//
//  ContentView.swift
//  NeverGone
//
//  Created by Michael Heverly on 2/4/26.
//

import SwiftUI

struct RootView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var sessionsViewModel = SessionsViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                SessionsListView(
                    viewModel: sessionsViewModel,
                    authViewModel: authViewModel
                )
            } else {
                AuthView(viewModel: authViewModel)
            }
        }
        .animation(.default, value: authViewModel.isAuthenticated)
    }
}

#Preview {
    RootView(authViewModel: AuthViewModel())
}
