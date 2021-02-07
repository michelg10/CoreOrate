import Foundation
import SwiftUI
import Combine
import AVFoundation
import Accelerate

class AudioRecorder: ObservableObject {
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
    var audioBuffer:[Float]
    var curEndOfBuf=0
    
    var curActive=0
    var numJobs=0
    
    var fftSetup:vDSP.FFT<DSPSplitComplex>
    
    init() {
        dftWindowSample=Int(dftWindow*Double(sampleRate))
        interpolationSample=next2Pow(x:4*dftWindowSample) //interpolate!
        frameIncSample=Int(frameInc*Double(sampleRate))
        strideSample=Int(Double(sampleRate)*strideLen)
        chunkSample=Int(chunkLen*Double(sampleRate))
        audioBuffer=Array(repeating: 0.0, count: chunkSample)
        coefsNum=Int(floor(Double(interpolationSample)/2.0))
        
        let log2n=vDSP_Length(log2(Float(interpolationSample)))
        
        fftSetup=vDSP.FFT(log2n: log2n, radix:.radix2, ofType: DSPSplitComplex.self)!
        
    }
    
    let objectWillChange=PassthroughSubject<AudioRecorder,Never>() // notify observing views about changes
    
    var recording = false {
        didSet {
            objectWillChange.send(self)
        }
    }
    var audioEngine:AVAudioEngine=AVAudioEngine()
    func startRecording() {
        audioEngine=AVAudioEngine()
        
        let inputNode=audioEngine.inputNode
        let inputFormat=inputNode.outputFormat(forBus: 0)
        
        let outputFormat=AVAudioFormat(commonFormat:.pcmFormatFloat32,sampleRate:Double(sampleRate),channels:1,interleaved: true)!
        let converter=AVAudioConverter(from:inputFormat,to:outputFormat)!
        
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(Double(sampleRate)*strideLen), format: inputFormat) { [self] buffer,time in
            self.numJobs+=1
            let myNum=self.numJobs
            self.curActive=self.numJobs
            let perfStart = DispatchTime.now()
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
            let perfConv = DispatchTime.now()
            //print("Conversion Time \(Double(perfConv.uptimeNanoseconds-perfStart.uptimeNanoseconds)/1000000.0) ms")
            var internalAudBuf:[Float]=[]
            if let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate)){
                var error: NSError?
                let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
                assert(status != .error)
                if (convertedBuffer.frameLength != self.strideSample) {
                    print("Abnormal frame length \(convertedBuffer.frameLength)")
                }
                if (self.curEndOfBuf+self.strideSample>=self.chunkSample) {
                    let shiftBy=self.curEndOfBuf+self.strideSample-self.chunkSample
                    self.curEndOfBuf=self.chunkSample
                    //print("Moving \(shiftBy)..<\(self.chunkSample) to 0..<\(self.chunkSample-shiftBy)")
                    internalAudBuf=self.audioBuffer
                    internalAudBuf[0..<self.chunkSample-shiftBy]=internalAudBuf[shiftBy..<self.chunkSample]
                    
                    //print("Copying \(self.strideSample) samples to \(self.chunkSample-self.strideSample)..<\(self.chunkSample)")
                    for i in 0..<self.strideSample {
                        internalAudBuf[self.chunkSample-self.strideSample+i]=convertedBuffer.floatChannelData![0][i]
                    }
                    self.curEndOfBuf=self.chunkSample
                    self.audioBuffer=internalAudBuf
                } else {
                    //print("Copying \(self.strideSample) samples to \(self.curEndOfBuf)..<\(self.curEndOfBuf+self.strideSample)")
                    internalAudBuf=self.audioBuffer
                    for i in 0..<self.strideSample {
                        internalAudBuf[i+self.curEndOfBuf]=convertedBuffer.floatChannelData![0][i]
                    }
                    self.curEndOfBuf+=self.strideSample
                    self.audioBuffer=internalAudBuf
                }
            }
            let perfCopy = DispatchTime.now()
            print("Buffer load time \(Double(perfCopy.uptimeNanoseconds-perfStart.uptimeNanoseconds)/1000000.0) ms")
            
            if (self.curEndOfBuf==self.chunkSample) {
                //run analysis
                doAudioAnalysis(dftWindowSample: dftWindowSample, frameIncSample: frameIncSample, interpolationSample: interpolationSample, coefsNum: coefsNum, fftSetup: fftSetup, signal: internalAudBuf)
                let perfAnal = DispatchTime.now()
                print("Transform time \(Double(perfAnal.uptimeNanoseconds-perfCopy.uptimeNanoseconds)/1000000.0) ms")
            }
            
            if self.curActive != myNum {
                print("System overload!")
                assert(0 != 0)
            }
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
            
        }
        print("done")
    }
}
