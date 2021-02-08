//
//  CoreOrateApp.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/6.
//

import SwiftUI
@main
struct CoreOrateApp: App {
    var body: some Scene {
        let mainAnalysisEngine=AnalysisEngine()
        WindowGroup {
            ContentView(analysisEngine: mainAnalysisEngine)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification), perform: { _ in
                    if mainAnalysisEngine.recordingActive {
                        mainAnalysisEngine.stopRecording()
                    }
                })
        }
    }
}
