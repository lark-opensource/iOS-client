//
//  FeatureGatingDebugView.swift
//  LarkSetting
//
//  Created by kongkaikai on 2022/11/15.
//

#if ALPHA

/// The code in this file is only used on the debug page.

// swiftlint:disable shorthand_operator
import Foundation
import SwiftUI
import Combine
import LarkFoundation

@available(iOS 13.0, *)
private final class FeatureGatingDebugDatas: ObservableObject {
    typealias Items = [(String, Bool, [String.Index])]
    @MainActor @Published var filtered: Items = []
    @Published var filter: String = "" {
        didSet { loadData() }
    }

    private var task: Task<Void, Never>?

    private var userID: String

    init(userID: String) {
        self.userID = userID
        loadData()
    }

    private func loadData() {
        task?.cancel()
        task = Task.detached {
            let filter = self.filter.lowercased()
            let data: Items = FeatureGatingStorage.debugFeatureDict(of: self.userID).sorted { $0.key < $1.key }
                .compactMap { item in
                    guard let match = item.0.lowercased().fuzzyMatch(filter) else {
                        return nil
                    }
                    return (item.0, item.1, match)
                }

            if !Task.isCancelled {
                await self.updateFiltered(data)
            }
        }
    }

    @MainActor private func updateFiltered(_ data: Items) async { filtered = data }

    func addTempFeatureGating(fg: String, isEnable: Bool) {
        FeatureGatingStorage.updateDebugFeatureGating(fg: fg, isEnable: isEnable, id: userID)
        loadData()
    }
}

@available(iOS 16.0, *)
struct FeatureGatingDebugView: View {
    @StateObject private var data: FeatureGatingDebugDatas
    // Add new key
    @State private var isAddShow: Bool = false
    @State private var newKey: String = ""

    init(userID: String) {
        _data = StateObject(wrappedValue: FeatureGatingDebugDatas(userID: userID))
    }

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                TextField("Search", text: $data.filter)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)

                if !data.filter.isEmpty {
                    Button("Cancel", role: .cancel) {
                        data.filter = ""
                    }
                }

                Button("Add", role: .none) {
                    newKey = data.filter
                    isAddShow.toggle()
                }
            }
            .padding([.leading, .trailing])

            List($data.filtered, id: \.0) { $item in
                Toggle(isOn: $item.1) {
                    highlight(string: item.0, indices: item.2)
                }
                .onChange(of: item.1) { isEnable in
                    data.addTempFeatureGating(fg: item.0, isEnable: isEnable)
                }
            }
        }
        .alert("Add FG", isPresented: $isAddShow, actions: {
            TextField("Key:", text: $newKey)
            Button("Confirm") {
                data.addTempFeatureGating(fg: newKey, isEnable: true) // default true
                data.filter = newKey
                newKey = ""
            }
            Button("Cancel", role: .cancel, action: {})
        }, message: {
            Text("Please enter a new FG key.")
        })
        .navigationTitle("FG")
        .navigationBarTitleDisplayMode(.inline)
    }

    func highlight(string: String, indices: [String.Index]) -> some View {
        if indices.isEmpty { return Text(string) }

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
#endif
