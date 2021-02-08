//
//  clickButton.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/8.
//

import SwiftUI

struct clickButtonStyle: ButtonStyle { //override swiftUI's default fugly flash
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct clickButton: View {
    @ObservedObject var analysisEngine:AnalysisEngine
    @Environment(\.colorScheme) var colorScheme
    let generator=UIImpactFeedbackGenerator(style: .rigid)
    var body: some View {
        Button(action:{
            generator.prepare()
            print("Work")
            generator.impactOccurred()
            if analysisEngine.recordingActive {
                analysisEngine.stopRecording()
            } else {
                analysisEngine.startRecording()
            }
        }) {
            ZStack {
                Text(analysisEngine.recordingActive ? NSLocalizedString("Stop",comment:"Stop recording") : NSLocalizedString("Start", comment: "Start recording"))
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .fontWeight(.medium)
                    .padding(.horizontal,55)
                    .padding(.vertical,12)
                    .font(.title)
                    .background(analysisEngine.recordingActive ? LinearGradient(gradient: Gradient(colors: [Color.init("StopBtn1"),Color.init("StopBtn2")]), startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(gradient: Gradient(colors: [Color.init("StartBtn1"),Color.init("StartBtn2")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(.greatestFiniteMagnitude)
            }
        }.buttonStyle(clickButtonStyle())
    }
}

struct clickButton_Previews: PreviewProvider {
    static var previews: some View {
        clickButton(analysisEngine: AnalysisEngine(isPreview: true))
    }
}
