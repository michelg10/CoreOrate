//
//  ContentView.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/6.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var analysisEngine:AnalysisEngine
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Model input (Spectrogram)")
                if analysisEngine.outSpec != nil {
                    analysisEngine.outSpec
                }
                Text("Model output")
                Text(analysisEngine.classificationReturn)
                Text("System epoch \(analysisEngine.alive)")
                
                if (analysisEngine.recordingActive) {
                    Button("Stop", action:{analysisEngine.stopRecording()})
                } else {
                    Button("Start", action:{analysisEngine.startRecording()})
                }
            }.navigationTitle("CoreOrate")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(analysisEngine: AnalysisEngine())
            .previewDevice("iPhone 12")
    }
}
