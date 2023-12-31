//
//  MicroAppNormalChatKeyboardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/1/14.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkContainer
import LarkModel
import RustPB
import RxSwift
import RxCocoa
import SuiteAppConfig
import LarkFeatureSwitch
import LarkChat
import LarkOPInterface
import EEMicroAppSDK
import LarkFeatureGating
import LarkSetting

public final class MicroAppNormalChatKeyboardSubModule: NormalChatKeyboardSubModule {
    /// 「+」号菜单
    public override var moreItems: [ChatKeyboardMoreItem] {
        var items = [self.vote]
        items += self.dynamicMenuItems
        return items.compactMap { $0 }
    }

    @ScopedProvider var microAppService: MicroAppService?
    @ScopedProvider var openPlatformService: OpenPlatformService?
    @ScopedInjectedLazy var appConfigService: AppConfigService?
    @ScopedInjectedLazy var fgService: FeatureGatingService?

    private let disposeBag: DisposeBag = DisposeBag()
    private var metaModel: ChatKeyboardMetaModel?

    public override class func canInitialize(context: ChatKeyboardContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatKeyboardMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatKeyboardMetaModel) -> [Module<ChatKeyboardContext, ChatKeyboardMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatKeyboardMetaModel) {
        self.metaModel = model
    }

    public override func createMoreItems(metaModel: ChatKeyboardMetaModel) {
        self.metaModel = metaModel
        self.loadDynamicMenuItems(metaModel: metaModel)
    }

    // MARK: vote
    private lazy var vote: ChatKeyboardMoreItem? = {
        let featureGatingEnable = fgService?.staticFeatureGatingValue(with: "im.chat.vote") ?? false
        guard let chatModel = self.metaModel?.chat, !featureGatingEnable else { return nil }
        var item: ChatKeyboardMoreItemConfig?
        if chatModel.type == .group,
            !chatModel.isCrossWithKa,
            chatModel.oncallId.isEmpty,
            !self.context.hasRootMessage,
            !chatModel.isSuper,
            !chatModel.isP2PAi,
            !chatModel.isPrivateMode {
            item = ChatKeyboardMoreItemConfig(
                text: BundleI18n.LarkChat.Lark_Legacy_Vote,
                icon: Resources.vote,
                type: .vote,
                tapped: { [weak self] in
                    guard let self = self else { return }
                    if let chat = self.metaModel?.chat {
                        self.microAppService?.vote(in: chat)
                        ChatTracker.trackEnterVote(chat: chat)
                    }
                    self.context.foldKeyboard()
                })
        }
        var displayItem: ChatKeyboardMoreItemConfig?
        Feature.on(.vote).apply(on: {
            displayItem = item
        }, off: {})
        return displayItem
    }()

    // MARK: dynamicMenuItems
    private var dynamicMenuItems: [ChatKeyboardMoreItem] = []

    private func loadDynamicMenuItems(metaModel: ChatKeyboardMetaModel) {
        guard let appConfigService,
                appConfigService.feature(for: "chat.apps").isOn,
                !metaModel.chat.isCrossWithKa,
                !metaModel.chat.isPrivateMode,
                !metaModel.chat.isP2PAi,
                !metaModel.chat.isInMeetingTemporary else { return }
        guard let dynamicMenuItemsOb = self.dynamicMenuItems(
            chat: metaModel.chat,
            chatViewController: self.context.baseViewController()
        ) else { return }
        dynamicMenuItemsOb.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] items in
                guard let self = self else { return }
                self.dynamicMenuItems = items.map { item in
                    let tapped = item.tapped
                    var item = item
                    item.tapped = { [weak self] in
                        tapped()
                        // 打开加号应用或导索页后，收起"+"菜单
                        self?.context.foldKeyboard()
                    }
                    return item
                }
                self.context.refreshMoreItems()
            }).disposed(by: disposeBag)
    }

    func dynamicMenuItems(chat: Chat, chatViewController: UIViewController?) -> Observable<[ChatKeyboardMoreItem]>? {
        guard let openPlatformService else { return .empty() }
        return openPlatformService.getKeyBoardApps(chat: chat, chatViewController: chatViewController)?
            .map { items -> [ChatKeyboardMoreItem] in
                items.sorted { $0.priority > $1.priority }
                .map { item in ChatKeyboardMoreItemConfig(text: item.text,
                                                          icon: item.icon,
                                                          selectIcon: item.selectIcon,
                                                          type: .openPlatform,
                                                          badgeText: item.badge,
                                                          showDotBadge: item.isShowDot,
                                                          isDynamic: true,
                                                          tapped: item.tapped)
                }
            }
    }
}
