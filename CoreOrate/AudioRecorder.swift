import Foundation
import SwiftUI
import Combine
import AVFoundation

class AudioRecorder: ObservableObject {
    
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
        
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(4096), format: inputFormat) { buffer,time in
            buffer.frameLength=AVAudioFrameCount(4096)
            var tst=0.0
            for i in 0..<4096 {
                tst+=abs(Double(buffer.floatChannelData![0][i]))
            }
            print(tst)
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
