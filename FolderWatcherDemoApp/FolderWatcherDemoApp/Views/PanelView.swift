//
//  PanelView.swift
//  FolderWatcherDemoApp
//
//  Created by Sergey Slobodenyuk on 2024-01-15.
//

import SwiftUI

struct PanelView: View {
    @ObservedObject var viewModel: FolderWatcherViewModel

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Watching Path:")
                
                TextField("Path", text: $viewModel.watchingPath)
                    .disabled(viewModel.isWatching)
                
                Button("Select Path", action: viewModel.selectPath)
                    .disabled(viewModel.isWatching)
            }

            Button(action: viewModel.toggleWatching) {
                Image(systemName: viewModel.isWatching
                      ? "stop.fill"
                      : "play.fill")
                
                Text(viewModel.isWatching
                     ? "Stop Watching"
                     : "Start Watching")
            }
            .padding(.vertical, 5)
            .disabled(viewModel.watchingPath.isEmpty)

            EventTableView(events: viewModel.events)
                .cornerRadius(5)

            Button("Clear Events", action: viewModel.clearEvents)
                .padding(.vertical, 5)
                .disabled(viewModel.events.isEmpty)
        }
    }
}

#Preview {
    PanelView(viewModel: FolderWatcherViewModel())
}
