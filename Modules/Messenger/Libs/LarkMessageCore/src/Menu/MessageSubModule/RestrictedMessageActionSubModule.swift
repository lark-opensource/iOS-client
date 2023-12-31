//
//  PinMessageActionSubModule.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/1.
//

import UIKit
import LarkModel
import LarkMessageBase
import EENavigator
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkAccountInterface
import LarkCore
import LarkOpenChat
import LarkSetting
import LKCommonsLogging

public final class RestrictedMessageActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    @ScopedInjectedLazy var tenantUniversalSettingService: TenantUniversalSettingService?

    static let logger = Logger.log(RestrictedMessageActionSubModule.self, category: "RestrictedMessageActionSubModule")

    private lazy var canResrictedMessage: Bool = {
        return fgService?.staticFeatureGatingValue(with: "messenger.msaage.restricted") ?? false
    }()

    public override var type: MessageActionType {
        return .restrict
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    lazy var setActionHandler: RestrictedMessageHandler? = {
        if let targetVC = context.pageAPI {
            return RestrictedMessageHandler(messageAPI: try? self.userResolver.resolve(assert: MessageAPI.self),
                                            targetVC: targetVC,
                                            nav: self.context.nav)
        } else {
            return nil
        }
    }()

    lazy var cancelActionHandler: CancelRestrictedMessageHandler? = {
        if let targetVC = context.pageAPI {
            return CancelRestrictedMessageHandler(messageAPI: try? self.userResolver.resolve(assert: MessageAPI.self), targetVC: targetVC)
        } else {
            return nil
        }
    }()

    private var currentUserId: String {
        return self.userResolver.userID
    }

    private func hasPermission(message: Message, chat: Chat ) -> Bool {
        if message.fromId == currentUserId {
            return true
        }
        if chat.isGroupAdmin || chat.ownerId == currentUserId {
            return true
        }
        return false
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        let message = model.message
        let chat = model.chat

        guard message.localStatus == .success, canResrictedMessage else {
            return false
        }

        if chat.type == .p2P {
            return false
        }

        guard hasPermission(message: message, chat: chat) else { return false }
        return true
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let chatId = model.chat.id
        let messageId = model.message.id

        if model.message.isRestricted {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_SetMessageAsdUnrestricted_Button,
                                     icon: BundleResources.Menu.menu_cancel_secret_message,
                                     trackExtraParams: ["click": "cancel_restricted", "target": "none"]) { [weak self] in
                self?.cancelActionHandler?.handle(message: model.message, chat: model.chat, params: [:], onFinish: { error in
                    if error != nil {
                        Self.logger.error("RestrictedMessageActionSubModule cancel Restricted chatId: \(chatId) -messageId: \(messageId)", error: error)
                    }
                })
            }
        } else {
            guard let settingService = self.tenantUniversalSettingService, settingService.supportRestrictMessage() else { return nil }
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_SetMessageAsdRestricted_Button,
                                     icon: BundleResources.Menu.menu_set_secret_message,
                                     trackExtraParams: ["click": "set_restricted", "target": "none"]) { [weak self] in
                self?.setActionHandler?.handle(message: model.message, chat: model.chat, params: [:], onFinish: { [weak self] error in
                    if error != nil {
                        self?.tenantUniversalSettingService?.loadTenantMessageConf(forceServer: true, onCompleted: nil)
                        Self.logger.error("RestrictedMessageActionSubModule set Restricted chatId: \(chatId) -messageId: \(messageId)", error: error)
                    }
                })
            }
        }
    }
}
