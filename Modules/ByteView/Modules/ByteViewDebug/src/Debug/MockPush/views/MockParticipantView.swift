//
//  MockParticipantPush.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2023/7/18.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct MockParticipantView: View {
    @State
    var pushIntervalMSStr: String = "500"
    @State
    var maxParticipantCountStr: String = "1000"

    @State
    var upsertCountStr: String = "20"

    @State
    var removeCountStr: String = "10"

    typealias StartAction = (_ pushIntervalMS: Int, _ maxCount: Int, _ upsertCount: Int, _ removeCount: Int) -> Void
    let startAction: StartAction?

    let dismissAction: (() -> Void)?

    init(maxParticipantCount: Int = 1000,
         startAction: StartAction?,
         dismissAction: (() -> Void)?) {
        self.maxParticipantCountStr = maxParticipantCount.description
        self.startAction = startAction
        self.dismissAction = dismissAction
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("推送时间间隔(MS):")
                    Spacer()
                    TextField("MS", text: $pushIntervalMSStr)
                        .frame(maxWidth: 100)
                }
                HStack {
                    Text("最大参会人数量")
                    Spacer()
                    TextField("Count", text: $maxParticipantCountStr)
                        .frame(maxWidth: 100)
                }
                HStack {
                    Text("每次推送 Upsert 数量:")
                    Spacer()
                    TextField("Count", text: $upsertCountStr)
                        .frame(maxWidth: 100)
                }
                HStack {
                    Text("每次推送 Remove 数量:")
                    Spacer()
                    TextField("Count", text: $removeCountStr)
                        .frame(maxWidth: 100)
                }

            }
            Button("Start") {
                guard let maxCount = Int(maxParticipantCountStr),
                   let intervalMS = Int(pushIntervalMSStr),
                   let upsertCount = Int(upsertCountStr),
                   let removeCount = Int(removeCountStr) else {
                    return
                }
                startAction?(intervalMS, maxCount, upsertCount, removeCount)
                self.dismissAction?()
            }
            Button("Cancel") {
                self.dismissAction?()
            }
        }
    }
}
