//
//  ChatSettingAppsModuleViewModel.swift
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

final class ChatSettingAppsModuleViewModel: ChatSettingModuleViewModel {
    var items: [CommonCellItemProtocol] {
        get { _items.value }
        set { _items.value = newValue }
    }
    private var _items: SafeAtomic<[CommonCellItemProtocol]> = [] + .readWriteLock
    var reloadObservable: Observable<Void> {
        reloadSubject.asObservable()
    }
    var isOwner: Bool { return currentUserId == chat.ownerId }
    private var currentUserId: String {
        return self.userResolver.userID
    }
    private static let logger = Logger.log(ChatSettingAppsModuleViewModel.self, category: "Module.IM.ChatInfo")
    var reloadSubject = PublishSubject<Void>()
    private(set) var disposeBag = DisposeBag()
    private var chat: Chat
    weak var targetVC: UIViewController?
    var chatPushWrapper: ChatPushWrapper
    var pushCenter: PushNotificationCenter
    lazy var chatExtensionFunctionsViewModel = {
        ChatExtensionFunctionsViewModel(resolver: self.userResolver,
                                        chatWrapper: self.chatPushWrapper,
                                        pushCenter: pushCenter,
                                        moduleFatoryTypes: moduleFatoryTypes)
    }()
    // 开放模块注册的工厂类型
    private let moduleFatoryTypes: [ChatSettingFunctionItemsFactory.Type]
    private let userResolver: UserResolver

    init(resolver: UserResolver,
         chat: Chat,
         pushCenter: PushNotificationCenter,
         chatPushWrapper: ChatPushWrapper,
         moduleFatoryTypes: [ChatSettingFunctionItemsFactory.Type],
         targetVC: UIViewController?) {
        self.chat = chat
        self.chatPushWrapper = chatPushWrapper
        self.moduleFatoryTypes = moduleFatoryTypes
        self.targetVC = targetVC
        self.pushCenter = pushCenter
        self.userResolver = resolver
    }

    func structItems() {
        let items = [groupAppsItem()].compactMap({ $0 })
        self.items = items
    }

    func startToObserve() {
        let chatExtensionFunctionsViewModelOb = chatExtensionFunctionsViewModel.reload.asObservable()
            .map { (_) -> Void in
            }

        Observable.merge(chatExtensionFunctionsViewModelOb)
            .subscribe(onNext: { [weak self] _ in
                self?.structItems()
                self?.reloadSubject.onNext(())
            }).disposed(by: disposeBag)
    }

    func groupAppsItem() -> CommonCellItemProtocol? {
        if chat.isCrypto || chat.isPrivateMode || AppConfigManager.shared.leanModeIsOn { return nil }
        let functions = self.chatExtensionFunctionsViewModel.functions.filter { $0.type != .search }
        if functions.isEmpty { return nil }
        let title = chat.type == .p2P ? BundleI18n.LarkChatSetting.Lark_Chat_Application :
            BundleI18n.LarkChatSetting.Lark_Chat_GroupApplication
        // 新版设置页移入新section, 需要过滤掉搜索item
        let item = ChatInfoGroupAppItem(
            type: .apps,
            cellIdentifier: ChatInfoGroupAppCell.lu.reuseIdentifier,
            style: .auto,
            title: title,
            listViewModel:
                ChatSettingItemListViewModel(functions: functions,
                                             vc: self.targetVC as? ChatInfoViewController))
        return item
    }
}
