//
//  TabManagementViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/10.
//

import Foundation
import RxSwift
import RxCocoa
import LarkOpenChat
import LKCommonsLogging
import RustPB
import LarkSDKInterface
import LarkContainer
import LarkModel

final class TabManagementViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(TabManagementViewModel.self, category: "Module.IM.ChatTab")
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    private let disposeBag = DisposeBag()
    let chatId: Int64
    var manageItems: [ChatTabManageItem]
    let canManageTab: BehaviorRelay<(Bool, String?)>
    let getTab: (Int64) -> ChatTabContent?
    let getChat: () -> Chat

    init(userResolver: UserResolver,
         manageItems: [ChatTabManageItem],
         canManageTab: BehaviorRelay<(Bool, String?)>,
         getTab: @escaping (Int64) -> ChatTabContent?,
         getChat: @escaping () -> Chat) {
        self.userResolver = userResolver
        self.chatId = Int64(getChat().id) ?? 0
        self.manageItems = manageItems
        self.canManageTab = canManageTab
        self.getTab = getTab
        self.getChat = getChat
    }

    func delete(tabId: Int64) -> Observable<Int64> {
        let chatId = self.chatId
        return (self.chatAPI?.deleteChatTab(chatId: chatId, tabId: tabId).map { _ in return tabId }
                ?? .error(UserScopeError.disposed))
            .do(onError: { error in
                Self.logger.error("tab management delete tab fail tabId: \(tabId) chatId: \(chatId)", error: error)
            })
    }

    func reOrder() -> Observable<[Int64]> {
        let chatId = self.chatId
        let reorderTabIds = self.manageItems.map { $0.tabId }
        return (self.chatAPI?.updateChatTabsOrder(chatId: chatId, reorderTabIds: reorderTabIds)
            .map { (res) -> [Int64] in
                return res.tabs.map { $0.id }
            } ?? .error(UserScopeError.disposed))
            .do(onError: { error in
                Self.logger.error("tab management reOrder tabs fail chatId: \(chatId)", error: error)
            })
    }

    func move(from: Int, to: Int) {
        guard self.manageItems.count > from, self.manageItems.count > to else { return }
        let itemToMove = self.manageItems[from]
        self.manageItems.remove(at: from)
        self.manageItems.insert(itemToMove, at: to)
    }
}
