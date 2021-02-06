//
//  ContentView.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/6.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var audioRecorder: AudioRecorder
    
    var body: some View {
//        NavigationView {
//        }
        VStack(alignment: .leading) {
            Text("SER").font(.title)
            Text("Model input (Spectrogram)")
            Text("Model output")
            Button("Start", action:{audioRecorder.startRecording()})
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(audioRecorder: AudioRecorder())
            .previewDevice("iPhone 12")
    }
}
