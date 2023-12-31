//
//  DebugPodInfoView.swift
//  EEPodInfoDebugger
//
//  Created by kongkaikai on 2022/11/11.
//

import Foundation
import SwiftUI
import LarkFoundation

@available(iOS 15.0, *)
struct DebugPodInfoView: View {
    var copy: CopyHandler?
    @State private var searchKey: String = ""
    private let infos = DebugPodInfoJsonDataSource().podVersionInfos

    var body: some View {
        List {
            let searchKey = searchKey.lowercased()

            Text("Local-Pod commits (Top 3): \n\(DebugPodInfoForwarding.buildCommits)")
                .foregroundColor(.red.opacity(0.75))
                .lineLimit(2)
                .contextMenu {
                    Button("Copy") { copy?(DebugPodInfoForwarding.buildCommits) }
                }

            ForEach(infos, id: \.0) { info in
                if let indices = info.0.lowercased().fuzzyMatch(searchKey) {
                    HStack {
                        highlight(string: info.0, indices: indices)
                        Spacer()
                        Text(info.1).font(.caption)
                    }
                    .contextMenu {
                        Button("Copy") { copy?(info.1) }
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchKey, placement: .navigationBarDrawer(displayMode: .always))
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.never)
        .navigationTitle("Pod Info")
    }

    private func highlight(string: String, indices: [String.Index]?) -> some View {
        guard let indices, !indices.isEmpty else { return Text(string) }

        var result = Text("")

        for index in string.indices {
            let char = Text(String(string[index]))
            if indices.contains(index) {
                result = result + char.bold().foregroundColor(.blue.opacity(0.7))
            } else {
                result = result + char
            }
        }

        return result
    }
}

@available(iOS 15.0, *)
struct DebugPodInfoView_Previews: PreviewProvider {
    static var previews: some View {
        DebugPodInfoView()
    }
}
