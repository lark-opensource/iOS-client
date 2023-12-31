//
//  PushShortcutsHandler.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/9.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import LarkModel

// shortcuts
struct PushShortcuts: PushMessage {
    let shortcuts: [ShortcutResult]
}

final class PushShortcutsHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushShortcutsResponse) throws {
        guard let pushCenter = self.pushCenter else { return }
        let shortcuts = message.shortcuts.compactMap { (shortcut) -> ShortcutResult? in
            if let preview = FeedPreview.transform(id: shortcut.channel.id,
                                                   entityPreviews: message.entityPreviews) {
                return ShortcutResult(shortcut: shortcut, preview: preview)
            }
            return nil
        }
        let info = "resultsCount: \(shortcuts.count), "
             + "shortcutsCount: \(message.shortcuts.count), "
             + "entityPreviewsCount: \(message.entityPreviews.count), "
             + "list: \(shortcuts.map { $0.description })"
        let logs = info.logFragment()
        for i in 0..<logs.count {
            let log = logs[i]
            FeedContext.log.info("feedlog/shortcut/dataflow/push/<\(i)>. \(log)")
        }
        pushCenter.post(PushShortcuts(shortcuts: shortcuts))
    }
}
