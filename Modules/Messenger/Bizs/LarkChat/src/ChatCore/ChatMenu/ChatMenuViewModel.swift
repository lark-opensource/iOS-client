//
//  ChatMenuViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/9/12.
//

import UIKit
import Foundation
import RustPB
import LarkContainer
import RxSwift
import RxCocoa
import LarkSDKInterface
import EENavigator
import LarkModel
import LarkCore
import LarkStorage
import LarkAccountInterface
import LarkFeatureGating
import LKCommonsLogging

protocol ChatMenuClickDelegate: AnyObject {
    func didClickBottomItem(index: Int, source: UIView, minWidth: CGFloat)
    func didClickExtendItem(rootIndex: Int, index: Int)
}

struct ChatMenuCellInfo {
    public private(set) var iconImage: UIImage
    public private(set) var labelText: String
    public init(iconImage: UIImage,
                labelText: String) {
        self.iconImage = iconImage
        self.labelText = labelText
    }
}

final class ChatMenuViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatMenuViewModel.self, category: "Module.IM.ChatMenu")
    private let disposeBag = DisposeBag()
    private let chatId: Int64
    let getChat: () -> Chat
    private var version: Int64?
    private let chatAPI: ChatAPI
    @ScopedInjectedLazy private var p2PBotMenuConfigService: ChatP2PBotMenuConfigService?
    var dataSource: [Im_V1_ChatMenuItem] = []
    private weak var chatVC: UIViewController?
    private var tableRefreshPublish: PublishSubject<Void> = PublishSubject<Void>()
    lazy var tableRefreshDriver: Driver<Void> = {
        return tableRefreshPublish.asDriver(onErrorJustReturn: ())
    }()

    init(userResolver: UserResolver,
         chatId: Int64,
         getChat: @escaping () -> Chat,
         chatVC: UIViewController) throws {
        self.userResolver = userResolver
        self.chatId = chatId
        self.getChat = getChat
        self.chatVC = chatVC
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        let pushChatMenuItemsObservable = try userResolver.userPushCenter.observable(for: PushChatMenuItems.self)
        pushChatMenuItemsObservable
            .filter { $0.chatId == chatId }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                self.handleChatMenuItems(push.menuItems, newVersion: push.version)
                Self.logger.info(" handle push chat menu \(push.menuItems.count) version: \(push.version) chatId: \(self.chatId)")
            }).disposed(by: self.disposeBag)
        self.chatAPI.getChatMenuItems(chatId: chatId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.handleChatMenuItems(res.menuItems, newVersion: res.version)
                Self.logger.info("init chat menu \(res.menuItems.count) version: \(res.version) chatId: \(self.chatId)")
            }).disposed(by: self.disposeBag)
    }

    private func handleChatMenuItems(_ menuItems: [Im_V1_ChatMenuItem], newVersion: Int64) {
        if let version = self.version, version >= newVersion { return }
        self.version = newVersion
        self.dataSource = menuItems
        self.tableRefreshPublish.onNext(())
        let chat = self.getChat()
        if chat.type == .p2P, chat.chatter?.type == .bot {
            self.p2PBotMenuConfigService?.record(self.chatId, showMenu: !menuItems.isEmpty)
        }
    }
}

// 会话下方菜单按钮点击操作
extension ChatMenuViewModel: ChatMenuClickDelegate {
    func didClickBottomItem(index: Int, source: UIView, minWidth: CGFloat) {
        guard let chatVC = self.chatVC else { return }
        let menuItem = self.dataSource[index]
        let subMenuItems = menuItem.subMenuItems
        if !subMenuItems.isEmpty {
            let vc = ChatMenuExtendViewController(rootIndex: index, dataSource: subMenuItems, sourceView: source, minWidth: minWidth)
            vc.clickDelegate = self
            navigator.present(vc, from: chatVC)
        } else {
            clickMenuButton(buttonItem: menuItem.buttonItem, menuId: menuItem.id)
        }
        IMTracker.Chat.ChatMenu.Click(self.getChat(), featureButtonId: menuItem.buttonItem.id)
    }

    func didClickExtendItem(rootIndex: Int, index: Int) {
        let menuItem = self.dataSource[rootIndex].subMenuItems[index]
        clickMenuButton(buttonItem: menuItem.buttonItem, menuId: menuItem.id)
        IMTracker.Chat.ChatMenu.Click(self.getChat(), featureButtonId: menuItem.buttonItem.id)
    }

    func clickMenuButton(buttonItem: Basic_V1_ButtonItem, menuId: Int64) {
        guard let chatVC = self.chatVC else { return }
        switch buttonItem.actionType {
        case .callBack:
            self.chatAPI.triggerChatMenuEvent(
                chatId: self.chatId,
                menuId: menuId
            ).observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                guard let self = self else { return }
                Self.logger.error("triggerChatMenuEvent failed \(self.chatId) \(menuId)", error: error)
            }).disposed(by: self.disposeBag)
        case .appLink:
            if let url = URL(string: buttonItem.redirectLink.iosURL) {
                navigator.push(url, from: chatVC)
            } else if let url = URL(string: buttonItem.redirectLink.commonURL) {
                navigator.push(url, from: chatVC)
            }
        @unknown default:
            break
        }
    }
}

// 埋点
extension ChatMenuViewModel {
    func trackView() {
        IMTracker.Chat.ChatMenu.View(
            self.getChat(),
            isAppMenu: true,
            firstLayerNums: self.dataSource.count,
            secondLayerNums: self.dataSource.map { $0.subMenuItems.count }
        )
    }
}

/// 机器人单聊进群默认配置（展示菜单 or 输入框）目前开放平台没有提供接口配置
/// 需要端上记录配置了群菜单数据的机器人单聊，进群的时候默认展示菜单 UI
protocol ChatP2PBotMenuConfigService {
    func record(_ chatId: Int64, showMenu: Bool)
    func shouldShowMenu(_ chatId: Int64) -> Bool
}

class ChatP2PBotMenuConfigServiceImp: ChatP2PBotMenuConfigService {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatMenuViewModel.self, category: "Module.IM.ChatP2PBotMenuConfig")
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private lazy var store = KVStores.udkv(
        space: .user(id: userResolver.userID),
        domain: Domain.biz.messenger
    )
    private let configKey: String = "ChatP2PBotMenuConfig"
    private lazy var enableBotMenu: Bool = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.input.menu.ii"))

    func record(_ chatId: Int64, showMenu: Bool) {
        guard enableBotMenu else { return }
        Self.logger.info("record begin \(chatId) \(showMenu)")
        var showMenuChatIds: Set<Int64> = self.store.value(forKey: configKey) ?? []
        if showMenuChatIds.contains(chatId), !showMenu {
            showMenuChatIds.remove(chatId)
            self.store.set(showMenuChatIds, forKey: configKey)
            Self.logger.info("record delete \(chatId)")
        } else if !showMenuChatIds.contains(chatId), showMenu {
            showMenuChatIds.insert(chatId)
            self.store.set(showMenuChatIds, forKey: configKey)
            Self.logger.info("record inset \(chatId)")
        }
    }

    func shouldShowMenu(_ chatId: Int64) -> Bool {
        guard enableBotMenu else { return false }
        var showMenuChatIds: Set<Int64> = self.store.value(forKey: configKey) ?? []
        let shouldShowMenu = showMenuChatIds.contains(chatId)
        Self.logger.info("record shouldShowMenu \(chatId) \(shouldShowMenu)")
        return shouldShowMenu
    }
}
