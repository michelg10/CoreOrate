import Foundation
import Accelerate

func doAudioAnalysis(dftWindowSample:Int, frameIncSample:Int,interpolationSample:Int,coefsNum:Int,fftSetup:vDSP.FFT<DSPSplitComplex>, signal:[Float]) /*-> [[Float]]*/ {
    var usableRanges:[Int]=[]
    var curSamp=Int(Double(dftWindowSample)/2)
    while (true) {
        var leftEdg=curSamp-Int(Double(dftWindowSample)/2)
        var rightEdg=0
        if frameIncSample%2==1 {
            rightEdg=curSamp+Int(Double(dftWindowSample)/2)
        } else {
            rightEdg=curSamp+Int(Double(dftWindowSample)/2)+1
        }
        if rightEdg>=signal.count {
            break
        }
        
        usableRanges.append(leftEdg)
        
        curSamp+=frameIncSample
    }
    
    var frame=Array(repeating: Float(),count:interpolationSample)
    for i in usableRanges {
        let leftEdg=i
        let rightEdg=i+dftWindowSample-1
        frame[0..<dftWindowSample]=signal[leftEdg...rightEdg];
        let window = vDSP.window(ofType: Float.self,usingSequence: .hanningDenormalized,count:dftWindowSample,isHalfWindow: false)
        
//        print(frame)
        frame.replaceSubrange(0..<dftWindowSample,with:vDSP.multiply(frame[0..<dftWindowSample],window)) //check this lol
//        print(frame)
        
        let halfN=Int(interpolationSample/2)
        var forwardInputReal=[Float](repeating: 0,count:halfN)
        var forwardInputImag=[Float](repeating: 0,count:halfN)
        var forwardOutputReal=[Float](repeating: 0,count:halfN)
        var forwardOutputImag=[Float](repeating: 0,count:halfN)
        
        forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
            forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
                forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
                    forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                        //generate input
                        var forwardInput=DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!, imagp: forwardInputImagPtr.baseAddress!)
                        //convert real values to complex
                        frame.withUnsafeBytes {
                            vDSP.convert(interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)),toSplitComplexVector: &forwardInput)
                        }
                        var forwardOutput=DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!, imagp: forwardOutputImagPtr.baseAddress!)
                        fftSetup.forward(input: forwardInput, output: &forwardOutput)
                    }
                }
            }
        }
    }
    
}
