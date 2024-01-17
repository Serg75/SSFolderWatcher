//
//  ContentView.swift
//  FolderWatcherDemoApp
//
//  Created by Sergey Slobodenyuk on 2024-01-15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel1 = FolderWatcherViewModel()
    @StateObject private var viewModel2 = FolderWatcherViewModel()
    
    var body: some View {
        HStack(spacing: 20) {
            PanelView(viewModel: viewModel1)
            PanelView(viewModel: viewModel2)
        }
        .padding()
        .onAppear() {
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask).first!
            let downloadsDirectory = FileManager.default.urls(
                for: .downloadsDirectory,
                in: .userDomainMask).first!
            
            viewModel1.watchingPath = documentsDirectory.resolvingSymlinksInPath().path
            viewModel2.self.watchingPath = downloadsDirectory.resolvingSymlinksInPath().path
        }
    }
}

#Preview {
    ContentView()
}
