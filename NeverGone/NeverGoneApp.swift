//
//  NeverGoneApp.swift
//  NeverGone
//
//  Created by Michael Heverly on 2/4/26.
//

import SwiftUI

@main
struct NeverGoneApp: App {
    @State private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView(authViewModel: authViewModel)
                .preferredColorScheme(.light)
        }
    }
}
