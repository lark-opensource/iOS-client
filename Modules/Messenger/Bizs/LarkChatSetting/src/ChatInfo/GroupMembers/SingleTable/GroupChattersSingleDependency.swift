//
//  GroupChattersSingleDependency.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/8/30.
//

import Foundation
import LarkCore
import RxSwift
import RxRelay
import RxCocoa
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import LarkContainer

protocol GroupChattersSingleUIDependencyProtocol: AnyObject, UserResolverWrapper {
    var tracker: GroupChatDetailTracker { get }
    /// 列表状态变化：多选/展示
    var displayMode: BehaviorRelay<ChatChatterDisplayMode> { get }

    /// 搜索Key发生变化
    var searchKey: BehaviorRelay<String?> { get }

    /// 选择人数变化
    var selectedItemsRelay: BehaviorRelay<[ChatChatterItem]> { get }

    /// 当列表的某一项被点击
    /// - Parameter item: 被点击的Item
    /// - Parameter updateCell: 更新Cell选中态的回调
    func onTapItem(_ item: ChatChatterItem, updateCell: (_ isSelectd: Bool) -> Void)
    func onTableDragging()
    func isItemSelected(_ item: ChatChatterItem) -> Bool
}

protocol GroupChattersSingleDependencyProtocol {
    var ownerID: String { get }
    var tenantID: String { get }
    var currentChatterID: String { get }
    var chatID: String { get }

    var currentUserType: AccountUserType { get }

    var chat: Chat { get }

    var chatAPI: ChatAPI { get }
    var chatterAPI: ChatterAPI { get }
    var serverNTPTimeService: ServerNTPTimeService { get }

    var isOwnerSelectable: Bool { get }

    var removeChatters: Observable<[String]> { get }

    var pushChatChatter: Observable<PushChatChatter> { get }
    var pushChatAdmin: Observable<PushChatAdmin> { get }
    var pushChatChatterListDepartmentName: Observable<PushChatChatterListDepartmentName>? { get }
}
