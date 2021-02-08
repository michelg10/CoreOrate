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
            VStack(alignment:.leading) {
                if !analysisEngine.recordingActive&&analysisEngine.alive == -1 {
                    Text(NSLocalizedString("About CoreOrate",comment:""))
                        .font(.title)
                        .bold()
                    Text(NSLocalizedString("AboutCoreOrateDescription", comment: ""))
                    InactiveSession().frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                } else if analysisEngine.alive == -1 {
                    BufferingView().frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                } else {
                    spectrogramPreview(analysisEngine:analysisEngine)
                    classificationView(analysisEngine: analysisEngine)
                        .padding(.bottom,15)
                }
                clickButton(analysisEngine: analysisEngine)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                    .padding(.bottom,20)
            }.padding(.horizontal, 20)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(NSLocalizedString("CoreOrate", comment: "Name probably won't be localized"))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(analysisEngine: AnalysisEngine(isPreview: true))
            .previewDevice("iPhone 12")
    }
}
