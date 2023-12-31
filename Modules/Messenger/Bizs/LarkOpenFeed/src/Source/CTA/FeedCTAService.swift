//
//  FeedCTAService.swift
//  LarkOpenFeed
//
//  Created by Ender on 2023/10/18.
//

import Foundation
import RxSwift
import RustPB

public protocol FeedCTAConfigService {
    // 按钮变更事件
    var buttonChangeObservable: Observable<String> { get }

    // 点击按钮时传入按钮信息及另一个按钮需要置灰按钮信息
    func clickWebhookButton(ctaInfo: FeedCTAInfo, anotherCTAInfo: FeedCTAInfo?, from: UIViewController)

    func isLoading(_ ctaInfo: FeedCTAInfo) -> Bool

    func isDisable(_ ctaInfo: FeedCTAInfo) -> Bool
}

public struct FeedCTAInfo {
    public let feedId: String
    public let buttonId: String
    public init(feedId: String, buttonId: String) {
        self.feedId = feedId
        self.buttonId = buttonId
    }
}

extension FeedCTAInfo: Hashable {
    public static func == (lhs: FeedCTAInfo, rhs: FeedCTAInfo) -> Bool {
        if lhs.feedId != rhs.feedId { return false }
        if lhs.buttonId != rhs.buttonId { return false }
        return true
    }
}
