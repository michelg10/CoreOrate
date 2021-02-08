//
//  BufferingView.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/8.
//

import SwiftUI

struct BufferingView: View {
    var body: some View {
        VStack {
            Text(NSLocalizedString("Buffering...", comment: ""))
                .font(.title)
                .bold()
            Text(NSLocalizedString("This should only take a moment", comment:""))
        }
    }
}

struct BufferingView_Previews: PreviewProvider {
    static var previews: some View {
        BufferingView()
    }
}
