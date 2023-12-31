//
//  ReplayListView.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2023/7/20.
//

import Foundation
import SwiftUI
import LarkStorage

// swiftlint:disable type_name
extension IsoPath: Identifiable {
    public typealias ID = String
    public var id: String {
        self.absoluteString
    }
}

@available(iOS 14.0, *)
struct ReplayListView: View {
    let didSelect: (IsoPath) -> Void
    init(didSelect: @escaping (IsoPath) -> Void) {
        self.didSelect = didSelect
    }

    @State
    var pushRecords: [IsoPath] = []
    @EnvironmentObject
    var toastState: ToastState

    var contentView: some View {
        if pushRecords.isEmpty {
            return AnyView(Text("无录制记录！"))
        } else {
            return AnyView(List {
                ForEach(pushRecords) { record in
                    Button(record.lastPathComponent) {
                        didSelect(record)
                    }
                }
                .onDelete { indexSet in
                    indexSet.map {
                        self.pushRecords[$0]
                    }
                    .forEach { url in
                        try? url.removeItem()
                    }
                    self.pushRecords = PushDebug.shared.listRecordFiles()
                }
            }
                .toolbar { EditButton() }
            )
        }
    }

    var body: some View {
        contentView
            .onAppear {
                self.pushRecords = PushDebug.shared.listRecordFiles()
            }
    }

}
