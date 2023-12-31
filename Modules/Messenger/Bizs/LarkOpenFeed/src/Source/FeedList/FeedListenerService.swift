//
//  FeedListenerService.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2022/11/30.
//

import Foundation
import LarkContainer
import RustPB
import LarkModel

public enum FeedListState {
    case switchFilterTab                    // 切换分组
    case viewAppear                         // feedlist出现
    case firstLoad                          // 端上首次加载到数据的时机
    case stopScrolling(position: Int?)      // 停止滚动/拖动; position: 可视区域最底部 Cell 在列表中的 index 值
    case startScrolling                     //开始滚动
}

public protocol FeedListenerItem {
    var needListenLifeCycle: Bool { get }
    func feedLifeCycleChanged(state: FeedPageState, context: FeedContextService)

    var needListenFeedData: Bool { get }
    func feedDataChanged(feeds: [FeedPreview], context: FeedContextService?)

    var needListenListState: Bool { get }
    func feedListStateChanged(feeds: [FeedPreview], state: FeedListState, context: FeedContextService?)
}

public extension FeedListenerItem {
    var needListenLifeCycle: Bool { false }
    func feedLifeCycleChanged(state: FeedPageState, context: FeedContextService) {}

    var needListenFeedData: Bool { false }
    func feedDataChanged(feeds: [FeedPreview], context: FeedContextService?) {}

    var needListenListState: Bool { false }
    func feedListStateChanged(feeds: [FeedPreview], state: FeedListState, context: FeedContextService?) {}
}

public final class FeedListenerProviderRegistery {
    public typealias FeedListenerItemProvider = (UserResolver) -> FeedListenerItem
    public private(set) static var providers: [FeedListenerItemProvider] = []

    public static func register(provider: @escaping FeedListenerItemProvider) {
        providers.append(provider)
    }
}
