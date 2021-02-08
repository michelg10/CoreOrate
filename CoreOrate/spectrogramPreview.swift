//
//  spectrogramPreview.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/8.
//

import SwiftUI

struct spectrogramPreview: View {
    @ObservedObject var analysisEngine:AnalysisEngine
    var body: some View {
        Text(NSLocalizedString("Preview",comment: "")).font(.title).bold()
        if analysisEngine.outSpec != nil {
            analysisEngine.outSpec!
                .resizable()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: 100, maxHeight: 170, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

struct spectrogramPreview_Previews: PreviewProvider {
    static var previews: some View {
        spectrogramPreview(analysisEngine: AnalysisEngine(isPreview: true))
    }
}
