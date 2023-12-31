//
//  MockFeedServiceForDocDependency.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
@testable import LarkFeed

class MockFeedServiceForDocDependency: FeedServiceForDocDependency {
    var deleteShortcutsBuilder: ((_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void>)?
    var createShortcutsBuilder: ((_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void>)?
    var isFeedCardShortcutBuilder: ((_ feedId: String) -> Bool)?

    func deleteShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        deleteShortcutsBuilder!(shortcuts)
    }

    func createShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        createShortcutsBuilder!(shortcuts)
    }

    func isFeedCardShortcut(feedId: String) -> Bool {
        isFeedCardShortcutBuilder!(feedId)
    }
}
