//
//  ChatSettingSearchModuleViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/2/26.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkMessengerInterface
import LKCommonsLogging
import EENavigator
import LarkSDKInterface
import LarkCore
import LarkAlertController
import LarkAccountInterface
import LarkReleaseConfig
import LarkKAFeatureSwitch
import ThreadSafeDataStructure
import SuiteAppConfig
import LarkAccount
import LarkOpenChat
import LarkUIKit

final class ChatSettingSearchModuleViewModel: ChatSettingModuleViewModel, UserResolverWrapper {
    let userResolver: UserResolver
    var items: [CommonCellItemProtocol] {
        get { _items.value }
        set { _items.value = newValue }
    }
    private var _items: SafeAtomic<[CommonCellItemProtocol]> = [] + .readWriteLock
    var reloadObservable: Observable<Void> {
        reloadSubject.asObservable()
    }
    var isOwner: Bool { return currentUserId == chat.ownerId }
    private var currentUserId: String { userResolver.userID }
    private static let logger = Logger.log(ChatSettingSearchModuleViewModel.self, category: "Module.IM.ChatInfo")
    var reloadSubject = PublishSubject<Void>()
    private(set) var disposeBag = DisposeBag()
    private var chat: Chat
    weak var targetVC: UIViewController?
    lazy var chatSettingSearchDetailViewModel = {
        ChatSettingSearchDetailViewModel(userResolver: userResolver,
                                         chat: self.chat,
                                         factoryTypes: factoryTypes)
    }()
    var chatPushWrapper: ChatPushWrapper
    var pushCenter: PushNotificationCenter
    private let factoryTypes: [ChatSettingSerachDetailItemsFactory.Type]

    init(userResolver: UserResolver,
         chat: Chat,
         pushCenter: PushNotificationCenter,
         chatPushWrapper: ChatPushWrapper,
         factoryTypes: [ChatSettingSerachDetailItemsFactory.Type],
         targetVC: UIViewController?) {
        self.userResolver = userResolver
        self.chat = chat
        self.chatPushWrapper = chatPushWrapper
        self.targetVC = targetVC
        self.factoryTypes = factoryTypes
        self.pushCenter = pushCenter
    }

    func structItems() {
        let items = [searchChatHistoryItem(),
                     searchChatDetailItem()].compactMap({ $0 })
        self.items = items
    }

    func startToObserve() {
        let chatSettingSearchDetailViewModelOb = chatSettingSearchDetailViewModel.reload.asObservable()
            .map { (_) -> Void in }

        Observable.merge(chatSettingSearchDetailViewModelOb)
            .subscribe(onNext: { [weak self] _ in
                self?.structItems()
                self?.reloadSubject.onNext(())
            }).disposed(by: disposeBag)
    }
}

// MARK: item方法
extension ChatSettingSearchModuleViewModel {
    // 搜索聊天记录
    func searchChatHistoryItem() -> CommonCellItemProtocol? {
        if AppConfigManager.shared.leanModeIsOn || chat.isCrypto || chat.isPrivateMode { return nil }
        let chat = self.chat

        let item = ChatInfoSearchHistoryItem(
            type: .searchChatHistory,
            cellIdentifier: ChatInfoSearchHistoryCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Chat_SearchChatHistory,
            tapHandler: { [weak self] _ in
                guard let `self` = self else { return }
                guard let vc = self.targetVC else {
                    assertionFailure("missing targetVC")
                    return
                }
                NewChatSettingTracker.imChatSettingClickSearchHistory(chat: chat)
                let body = SearchInChatBody(chatId: chat.id, chatType: chat.type, isMeetingChat: chat.isMeeting)
                self.userResolver.navigator.push(body: body, from: vc)
            }
        )
        return item
    }

    // 搜索聊天的细节信息(如云文档、wiki)
    func searchChatDetailItem() -> CommonCellItemProtocol? {
        if AppConfigManager.shared.leanModeIsOn || chat.isCrypto || chat.isPrivateMode { return nil }
        let item = ChatInfoSearchDetailItem(
            type: .serachChatDetail,
            cellIdentifier: ChatInfoSearchDetailCell.lu.reuseIdentifier,
            style: .auto,
            listViewModel:
                ChatSettingItemListViewModel(functions: self.chatSettingSearchDetailViewModel.items,
                                             vc: self.targetVC)
        )
        return item
    }
}
