//
//  MockAllFeedsDependency.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/8/24.
//

import UIKit
import RustPB
import RxSwift
@testable import LarkFeed

final class MockAllFeedsDependency: AllFeedsDependency {

    public init() { }

    /// 是否显示新引导
    public func needShowNewGuide(guideKey: String) -> Bool {
        return false
    }

    // 是否显示主导航免打扰badge
    public  var tabMuteBadgeObservable: Observable<Bool> = .just(true)

    public var showMute: Bool = true

    public func getAllBadge() -> Observable<Feed_V1_GetAllBadgeResponse> {
        return .just(Feed_V1_GetAllBadgeResponse())
    }
}
