//
//  ContentView.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/6.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var audioRecorder:AudioRecorder
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("CoreOrate").font(.title)
            Text("Model input (Spectrogram)")
            if audioRecorder.outSpec != nil {
                audioRecorder.outSpec
            }
            Text("Model output")
            if (audioRecorder.alive==69) {
                Text("Oop")
            }
            Text("System epoch \(audioRecorder.alive)")
            
            Button("Start", action:{audioRecorder.startRecording()})
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        var img:Image?=Image("circle.fill")
        ContentView(audioRecorder: AudioRecorder())
            .previewDevice("iPhone 12")
    }
}
