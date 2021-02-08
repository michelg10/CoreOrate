import Foundation
import SwiftUI
import Combine
import AVFoundation
import Accelerate
import CoreML
import Vision

class AnalysisEngine: ObservableObject {
    //MARK: Parameters
    let sampleRate=16000
    let chunkLen=1.0
    let strideLen=0.1
    let dftWindow=0.01533898305
    let frameInc=0.003813559322
    let resizeX=256
    let resizeY=256
    
    //MARK: Computed parameters
    let dftWindowSample:Int
    let interpolationSample:Int
    let frameIncSample:Int
    let strideSample:Int
    let chunkSample:Int
    let coefsNum:Int
    
    //MARK: Audio buffer stuff
    var audioBufs:[UnsafeMutablePointer<Float>?]
    var arcAid:[AVAudioPCMBuffer?]
    var curBufStart=0
    var curBufSize=0
    var bufSize:Int
    
    var curActive=0
    var numJobs=0
    
    var fftSetup:FFTSetup
    
    var mlmodel:VNCoreMLModel
    
    //MARK: Generate this
    var frame:UnsafeMutablePointer<Float>
    var hammingWindow:UnsafeMutablePointer<Float>
    var scale:Float
    @Published var recordingActive=false
    @Published var outSpec:Image?=nil
    @Published var alive:Int = -1
    @Published var classificationReturn=""
        
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            /*
             Use the Swift class `MobileNet` Core ML generates from the model.
             To use a different Core ML classifier model, add it to the project
             and replace `MobileNet` with that model's generated Swift class.
             */
            
            let request = VNCoreMLRequest(model: mlmodel, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.classificationReturn = "Unable to classify image."
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
        
            if classifications.isEmpty {
                self.classificationReturn = "Nothing recognized."
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                   return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                self.classificationReturn = "Classification:\n" + descriptions.joined(separator: "\n")
            }
        }
    }
    
    init() {
        try! mlmodel=VNCoreMLModel(for: smmodel().model)
        
        dftWindowSample=Int(dftWindow*Double(sampleRate))
        interpolationSample=next2Pow(x:4*dftWindowSample) //interpolate!
        frameIncSample=Int(frameInc*Double(sampleRate))
        strideSample=Int(Double(sampleRate)*strideLen)
        chunkSample=Int(chunkLen*Double(sampleRate))
        bufSize=Int(ceil(Double(chunkSample)/Double(strideSample)))
        audioBufs=Array(repeating: UnsafeMutablePointer<Float>(nil), count: bufSize)
        arcAid=Array(repeating: nil, count: bufSize)
        
        coefsNum=Int(floor(Double(interpolationSample)/2.0))
        
        let log2n=vDSP_Length(log2(Float(interpolationSample)))
        
        fftSetup=vDSP_create_fftsetup(log2n,FFTRadix(kFFTRadix2))!
        
        scale=0
        
        frame=UnsafeMutablePointer<Float>.allocate(capacity: interpolationSample)
        frame.initialize(to: 0)
        hammingWindow=UnsafeMutablePointer<Float>.allocate(capacity: dftWindowSample)
        hammingWindow.initialize(to: 0)
        
        doInit(dftWindowSample,sampleRate,hammingWindow,&scale)
        
        audioEngine=AVAudioEngine()
        
        let inputNode=audioEngine.inputNode
        let inputFormat=inputNode.outputFormat(forBus: 0)
        
        let outputFormat=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:Double(sampleRate),channels:1,interleaved: true)!
        let converter=AVAudioConverter(from:inputFormat,to:outputFormat)!
        
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(Double(sampleRate)*strideLen), format: inputFormat) { [self] buffer,time in
            let perfStart = DispatchTime.now()
            self.numJobs+=1
            let myNum=self.numJobs
            self.curActive=self.numJobs
            var newBufferAvailable=true
            
            let inputCallback: AVAudioConverterInputBlock={inNumPackets,outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable=false
                    return buffer
                } else {
                    print("New buffer unavailable")
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }
            if let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate)){
                var error: NSError?
                let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
                assert(status != .error)
                if (convertedBuffer.frameLength != self.strideSample) {
                    print("Abnormal frame length \(convertedBuffer.frameLength)")
                }
                let daBuffer=convertedBuffer.floatChannelData![0]
                audioBufs[curBufStart]=daBuffer
                arcAid[curBufStart]=convertedBuffer
                curBufStart=(curBufStart+1)%bufSize
                curBufSize=min(curBufSize+1,bufSize)
            }
            
            if (curBufSize==bufSize) {
                var img:UnsafeMutablePointer<UInt8>
                let audioBufPtr:UnsafeMutablePointer<UnsafeMutablePointer<Float>?>=UnsafeMutablePointer(mutating:audioBufs)
                img=specGen(curBufStart,bufSize,strideSample,audioBufPtr,dftWindowSample,frameIncSample,coefsNum,chunkSample, interpolationSample,frame,hammingWindow, fftSetup, scale, resizeX,resizeY, -144, -50)

                let colorspace = CGColorSpaceCreateDeviceRGB();
                let rgbData = CFDataCreate(nil, img, 256 * 256 * 3);
                let provider = CGDataProvider(data: rgbData!);
                let cgimg=CGImage(width: 256, height: 256, bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: 256*3, space: colorspace, bitmapInfo: CGBitmapInfo(rawValue: 0), provider: provider!, decode: nil, shouldInterpolate:false, intent: CGColorRenderingIntent.defaultIntent)
                img.deallocate()
                DispatchQueue.main.async {
                    outSpec=Image(uiImage: UIImage(cgImage: cgimg!))
                    alive=alive+1
                }
                let perfEnd = DispatchTime.now()
                
                //Perform inference
                DispatchQueue.global(qos: .userInitiated).async {
                    let infStart = DispatchTime.now()
                    let handler = VNImageRequestHandler(ciImage: CIImage(cgImage: cgimg!), orientation: .up)
                    do {
                        try handler.perform([self.classificationRequest])
                    } catch {
                        /*
                         This handler catches general image processing errors. The `classificationRequest`'s
                         completion handler `processClassifications(_:error:)` catches errors specific
                         to processing that request.
                         */
                        print("Inference failure.\n\(error.localizedDescription)")
                    }
                    let infEnd = DispatchTime.now()
                    print("Inference completed in \(Double(infEnd.uptimeNanoseconds-infStart.uptimeNanoseconds)/1000000.0) ms")
                }
                print("Preprocessing completed in \(Double(perfEnd.uptimeNanoseconds-perfStart.uptimeNanoseconds)/1000000.0) ms")
            }
            if self.curActive != myNum {
                print("System overload!")
                assert(0 != 0)
            }
        }
    }
        
    var audioEngine:AVAudioEngine=AVAudioEngine()
    func stopRecording() {
        audioEngine.stop()
        recordingActive=false
    }
    func startRecording() {
        curBufStart=0
        curBufSize=0
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
            
        }
        print("done")
        recordingActive=true
    }
}
