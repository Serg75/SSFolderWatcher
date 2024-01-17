//
//  EventTableView.swift
//  FolderWatcherDemoApp
//
//  Created by Sergey Slobodenyuk on 2024-01-15.
//

import SwiftUI
import SSFolderWatcher

struct EventTableView: View {
    var events: [GroupedEvent]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("File Name").bold()
                Spacer()
                Text("Event Type").bold()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(Color(.controlBackgroundColor))

            List(events, id: \.self) { event in
                EventRowView(event: event)
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct EventRowView: View {
    var event: GroupedEvent

    var body: some View {
        HStack {
            Text(event.event.fileName)
            Spacer()
            Text(event.event.type.description)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .modifier(RowBackgroundColorModifier(isDimmed: event.isOddGroup))
    }
}

struct RowBackgroundColorModifier: ViewModifier {
    let isDimmed: Bool

    func body(content: Content) -> some View {
        content
            .listRowBackground(!isDimmed ? Color(.alternatingContentBackgroundColors[0]) : Color(.alternatingContentBackgroundColors[1]))
    }
}


#Preview {
    EventTableView(events: [
        GroupedEvent(
            event: FolderWatcherEvent(
                type: .created,
                fileID: 0,
                fileName: "file1.txt",
                fileNewName: nil),
            isOddGroup: true),
        GroupedEvent(
            event: FolderWatcherEvent(
                type: .created,
                fileID: 0,
                fileName: "file2.txt",
                fileNewName: nil),
            isOddGroup: true),
        GroupedEvent(
            event: FolderWatcherEvent(
                type: .changed,
                fileID: 0,
                fileName: "file1.txt",
                fileNewName: nil),
            isOddGroup: false),
        GroupedEvent(
            event: FolderWatcherEvent(
                type: .deleted,
                fileID: 0,
                fileName: "file2.txt",
                fileNewName: nil),
            isOddGroup: true),
        GroupedEvent(
            event: FolderWatcherEvent(
                type: .deleted,
                fileID: 0,
                fileName: "file1.txt",
                fileNewName: nil),
            isOddGroup: false),
    ])
}
