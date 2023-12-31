//
//  ThreadNavigationBarRightSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/28.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkUIKit
import LKCommonsLogging
import RxSwift
import LarkBadge
import LarkAccountInterface
import EENavigator
import LarkMessengerInterface
import LarkCore
import LarkContainer

public final class ThreadNavigationBarRightSubModule: BaseNavigationBarItemSubModule {
    //右侧区域
    public override var items: [ChatNavigationExtendItem] {
        return _rightItems
    }
    private var _rightItems: [ChatNavigationExtendItem] = []
    private var metaModel: ChatNavigationBarMetaModel?
    private static let logger = Logger.log(ThreadNavigationBarRightSubModule.self, category: "ThreadNavigationBarRightSubModule")
    private let disposeBag: DisposeBag = DisposeBag()
    private lazy var chatMorePath: Path = {
        return self.context.chatRootPath.chat_more
    }()

    @ScopedInjectedLazy private var dependency: NavigationBarSubModuleDependency?

    public override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatNavigationBarMetaModel) -> [Module<ChatNavgationBarContext, ChatNavigationBarMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
        var needToRefresh = false
        if self.metaModel?.chat.isFrozen != model.chat.isFrozen {
            needToRefresh = true
        }
        self.metaModel = model
        if needToRefresh {
            self._rightItems = self.buildRigthItems(metaModel: model)
            self.context.refreshRightItems()
        }
    }

    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        if self.context.currentSelectMode() == .multiSelecting {
            self._rightItems = []
            return
        }
        let chat = metaModel.chat
        var items: [ChatNavigationExtendItem] = []
        self.metaModel = metaModel
        self._rightItems = self.buildRigthItems(metaModel: metaModel)
    }

    private func buildRigthItems(metaModel: ChatNavigationBarMetaModel) -> [ChatNavigationExtendItem] {
        var items: [ChatNavigationExtendItem] = []
        let chat = metaModel.chat
        if !chat.isFrozen && !chat.isCrossTenant && (chat.shareCardPermission == .allowed) {
            items.append(self.shareItem)
        }
        items.append(self.moreInfoItem)
        return items
    }

    private lazy var moreInfoItem: ChatNavigationExtendItem = {
        let button = UIButton()
        button.addPointerStyle()
        let defaultIcon: UIImage = Resources.navibar_more
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: defaultIcon,
                                                                style: self.context.navigationBarDisplayStyle())
        button.setImage(image, for: .normal)
        button.badge.observe(for: self.context.chatRootPath.chat_more)
        button.rx.tap.asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.moreInfoItemClick()
            })
            .disposed(by: disposeBag)
        return ChatNavigationExtendItem(type: .moreItem, view: button)
    }()

    private func moreInfoItemClick() {
        guard let metaModel = self.metaModel else { return }
        let targetVC = self.context.chatVC()
        let chat = metaModel.chat
        let currentChatterID = self.context.userID
        let isGroupOwner = self.context.userID == chat.ownerId
        LarkMessageCoreTracker.trackChatSetting(chat: chat,
                                     isGroupOwner: isGroupOwner,
                                     source: "more")
        IMTracker.Chat.Main.Click.Sidebar(chat, self.context.store.getValue(for: IMTracker.Chat.Main.ChatFromWhereKey))

        if !chat.announcement.docURL.isEmpty {
            self.dependency?.preloadDocFeed(chat.announcement.docURL, from: chat.trackType + "_announcement")
        }
        let body = ChatInfoBody(chat: chat, action: .chatMoreMobile, type: .ignore)
        self.context.nav.push(body: body, from: targetVC)
        LarkMessageCoreTracker.trackNewChatSetting(chat: chat,
                                        isGroupOwner: isGroupOwner,
                                        source: .chatMoreMobile)
        self.badgeShow(for: self.context.chatRootPath.chat_more, show: false)
    }

    private lazy var shareItem: ChatNavigationExtendItem = {
        let button = UIButton()
        button.addPointerStyle()
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: Resources.navibar_share,
                                                                style: self.context.navigationBarDisplayStyle())
        button.setImage(image, for: .normal)
        button.rx.tap.asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.shareItemClisk()
            })
            .disposed(by: disposeBag)
        return ChatNavigationExtendItem(type: .shareItem, view: button)
    }()

    private func shareItemClisk() {
        guard let metaModel = self.metaModel else {
            return
        }
        let chat = metaModel.chat
        let targetVC = self.context.chatVC()
        let body = ShareChatViaLinkBody(chatId: chat.id)
        self.context.nav.open(body: body, from: targetVC)
    }

    private func badgeShow(for path: Path, show: Bool, type: BadgeType = .dot(.pin)) {
        if show {
            BadgeManager.setBadge(path, type: type)
        } else {
            BadgeManager.clearBadge(path)
        }
    }
}
