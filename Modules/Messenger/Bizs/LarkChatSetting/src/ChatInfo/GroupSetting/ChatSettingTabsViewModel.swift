//
//  ChatSettingTabsViewModel.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2022/4/14.
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
import UniverseDesignToast
import RustPB
import RxRelay
import LarkUIKit
import LarkActionSheet
import UniverseDesignActionPanel
import LarkOpenChat
import Swinject
import AppContainer

final class ChatSettingTabsViewModel: ChatOpenTabService, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    func addTab(type: ChatTabType, name: String, jsonPayload: String?, success: ((ChatTabContent) -> Void)?, failure: ((_ error: Error, _ type: ChatTabType) -> Void)?) {
        self.chatAPI?.addChatTab(chatId: self.chatId, name: name, type: type, jsonPayload: jsonPayload)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                if let newTab = response.tabs.first(where: { $0.id == response.newTabID }) {
                    success?(newTab)
                } else {
                    assertionFailure("can not find new tab")
                }
            }, onError: { error in
                Self.logger.error("add tab failed", error: error)
                failure?(error, type)
            }).disposed(by: disposeBag)
    }
    func getTab(id: Int64) -> ChatTabContent? {
        assertionFailure("chat info not support")
        return nil
    }
    func jumpToTab(_ tab: ChatTabContent, targetVC: UIViewController) { assertionFailure("chat info not support") }
    func updateChatTabDetail(tab: ChatTabContent, success: ((ChatTabContent) -> Void)?, failure: ((_ error: Error) -> Void)?) { assertionFailure("chat info not support") }

    static let logger = Logger.log(ChatSettingTabsViewModel.self, category: "Module.IM.ChatTab")
    private let chatId: Int64
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    private(set) var dataSource: ChatTabsDataSourceService?

    init(resolver: UserResolver, chatId: Int64) {
        self.userResolver = resolver
        self.chatId = chatId
    }

    func loadData() {
        if self.dataSource == nil {
            let tabs = try? self.userResolver.resolve(type: ChatTabsDataSourceService.self, argument: self.chatId)
            self.dataSource = tabs
        }
    }
}
