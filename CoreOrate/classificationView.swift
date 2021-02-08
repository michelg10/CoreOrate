//
//  classificationView.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/8.
//

import SwiftUI

struct classificationView: View {
    @ObservedObject var analysisEngine:AnalysisEngine
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Text(NSLocalizedString("Classification",comment:"")).font(.title).bold()
        if analysisEngine.classificationError != nil {
            Text(analysisEngine.classificationError!)
        } else {
            if analysisEngine.classif != nil {
                VStack {
                    Image(analysisEngine.classif![0].resID+"-"+(colorScheme == .light ? "Light" : "Dark"))
                        .resizable()
                        .scaledToFit()
                        .padding(.bottom,10)
                    ForEach((0..<analysisEngine.classif!.count)) { index in
                        HStack {
                            if index==0 {
                                Text((analysisEngine.classif![index].name)).font(.title2).fontWeight(.bold)
                            } else {
                                Text((analysisEngine.classif![index].name)).font(.body).fontWeight(.medium)
                            }
                            Spacer()
                            if index==0 {
                                Text((String(Int(analysisEngine.classif![index].confidence*100))+"%")).font(.system(.title2, design:.monospaced)).fontWeight(.bold)
                            } else {
                                Text((String(Int(analysisEngine.classif![index].confidence*100))+"%")).font(.system(.body, design:.monospaced)).fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct classificationView_Previews: PreviewProvider {
    static var previews: some View {
        classificationView(analysisEngine: AnalysisEngine(isPreview: true))
    }
}
