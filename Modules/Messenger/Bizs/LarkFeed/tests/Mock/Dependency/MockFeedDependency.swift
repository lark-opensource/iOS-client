//
//  MockFeedDependency.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/11/3.
//

import Foundation
@testable import LarkFeed
import RxSwift
import LarkInteraction
import LarkContainer

final class MockFeedDependency: FeedDependency {

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    var userResolver: UserResolver

    var supportTypes: [DropItemType] { return [] }

    func getDraftFromLarkCoreModel(content: String) -> String { return "" }

    func setDropItemsFromLarkCoreModel(chatID: String, items: [DropItemValue]) {}

    func showMinimumModeChangeTip(show: () -> Void) {}
}
