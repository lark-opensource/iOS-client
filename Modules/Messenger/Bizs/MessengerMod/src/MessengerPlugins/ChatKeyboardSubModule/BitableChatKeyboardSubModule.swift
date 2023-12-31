//
//  BitableChatKeyboardSubModule.swift
//  MessengerMod
//
//  Created by zhaojiachen on 2023/3/21.
//

import Foundation
import LarkOpenChat
import LarkContainer
import LarkModel
import EENavigator
import LarkUIKit
import LarkAccountInterface
import UniverseDesignIcon
import LarkSetting
import LKCommonsLogging
import LarkSDKInterface
import LarkCore

public final class BitableChatKeyboardSubModule: NormalChatKeyboardSubModule {
    static let logger = Logger.log(BitableChatKeyboardSubModule.self, category: "BitableChatKeyboardSubModule")
    @ScopedInjectedLazy private var passportUserService: PassportUserService?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    /// 「+」号菜单
    public override var moreItems: [ChatKeyboardMoreItem] {
        return [groupSolitaire].compactMap { $0 }
    }

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
    }

    private lazy var groupSolitaire: ChatKeyboardMoreItem? = {
        guard fgService?.staticFeatureGatingValue(with: "im.chatgroup.more_collaborativelist") ?? false else { return nil }
        guard let chatModel = self.metaModel?.chat else { return nil }
        if !chatModel.isCrossWithKa,
           !chatModel.isPrivateMode,
           !chatModel.isSuper,
           !chatModel.isP2PAi,
           !chatModel.isOncall,
           !chatModel.isInMeetingTemporary,
           chatModel.type != .p2P {
            let item = ChatKeyboardMoreItemConfig(
                text: BundleI18n.CCM.Bitable_Runninglist_Name,
                icon: UDIcon.getIconByKey(.klondikeOutlined).ud.withTintColor(UIColor.ud.colorfulPurple),
                type: .groupSolitaire,
                tapped: { [weak self] in
                    self?.clickGroupSolitaire()
                })
            return item
        }
        return nil
    }()

    private func clickGroupSolitaire() {
        guard let chat = self.metaModel?.chat else { return }
        IMTracker.Chat.InputPlus.Click.GroupRunningList(chat)
        var tenantDomain = passportUserService?.userTenant.tenantDomain ?? ""
        /// 获取不到租户域名的时候使用 www 兜底
        if tenantDomain.isEmpty {
            tenantDomain = "www"
        }
        guard let domain = DomainSettingManager.shared.currentSetting["group_more_collaborativelist"]?.first else {
            assertionFailure("can not get")
            Self.logger.error("can not get groupMoreCollaborativelist domain")
            return
        }
        let urlStr: String = "https://" + "\(tenantDomain).\(domain)" + (self.userGeneralSettings?.bitableGroupNoteConfig.pathString ?? "")
        guard let url = URL(string: urlStr) else {
            assertionFailure("url init fail")
            Self.logger.error("url init fail \(urlStr)")
            return
        }
        guard let applinkStr = DomainSettingManager.shared.currentSetting["applink"]?.first else {
            assertionFailure("can not get")
            Self.logger.error("can not get applink domain")
            return
        }
        guard var applink = URL(string: "https://" + applinkStr + "/client/web_url/open") else {
            assertionFailure("applink init fail")
            Self.logger.error("applink init fail \(applinkStr)")
            return
        }
        applink = applink.append(parameters: ["url": url.append(name: "chat_id", value: chat.id).absoluteString,
                                              "lk_animation_mode": "1",
                                              "lk_navigation_mode": "1"])
        self.context.nav.push(applink, from: self.context.baseViewController())
    }
}
