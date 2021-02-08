//
//  InactiveSession.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/8.
//

import SwiftUI

struct InactiveSession: View {
    var body: some View {
        VStack(alignment: .center) {
            Text(NSLocalizedString("Session Inactive",comment: "")).font(.title).bold()
            Text(NSLocalizedString("Press start", comment: ""))
        }
    }
}

struct InactiveSession_Previews: PreviewProvider {
    static var previews: some View {
        InactiveSession()
    }
}
