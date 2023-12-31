//
//  IMAtPickerProcessor.swift
//  LarkChat
//
//  Created by liluobin on 2023/12/12.
//

import LarkUIKit
import LarkContainer
import LKCommonsLogging
import LarkIMMention
import LarkMessengerInterface
import LarkBaseKeyboard
import LarkModel
import EENavigator
import LarkCore

class IMAtPickerProcessor: IMMentionPanelDelegate {
    public static let logger = Logger.log(IMAtPickerProcessor.self, category: "IMAtPickerProcessor")

    struct IMAtPickerConfig {
        let chat: Chat
        let userResolver: UserResolver
        let supportAtMyAI: Bool
        weak var fromVC: UIViewController?
    }

    private var completeTask: (([IMMentionOptionType]) -> Void)?

    private var cancelTask: (() -> Void)?

    func showAtPicker(config: IMAtPickerConfig,
                      cancel: (() -> Void)?,
                      complete: (([InputKeyboardAtItem]) -> Void)?) {
        guard let fromVC = config.fromVC else {
            assertionFailure("fromVC == nil")
            return
        }
        let chat = config.chat
        let mentionOptEnable = config.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.corporate_aite_clouddocuments"))
        if mentionOptEnable {
            // chat普通键盘点击@
            let mentionChatModel = IMMentionChatConfig(id: chat.id,
                                                       userCount: chat.userCount,
                                                       isEnableAtAll: chat.isEnableAtAll(me: config.userResolver.userID),
                                                       showChatUserCount: chat.isUserCountVisible)
            let panel = IMMentionPanel(resolver: config.userResolver, mentionChatModel: mentionChatModel)
            panel.delegate = self
            self.cancelTask = cancel
            self.completeTask = { items in
                complete?(items.compactMap { item -> InputKeyboardAtItem? in
                    switch item.type {
                    case .chatter:
                        guard (item.id?.isEmpty == false) && (item.name != nil) else {
                            Self.logger.info("inputTextViewInputAt selectItem chatter data error")
                            return nil
                        }
                        return .chatter(.init(id: item.id ?? "", name: item.name?.string ?? "", actualName: item.actualName ?? "", isOuter: !item.isInChat))
                    case .wiki:
                        if case .wiki(let info) = item.meta {
                            return .wiki(info.url, item.name?.string ?? "", info.type)
                        }
                        Self.logger.info("inputTextViewInputAt selectItem wiki data error")
                        return nil
                    case .document:
                        if case .doc(let info) = item.meta {
                            return .doc(info.url, item.name?.string ?? "", info.type)
                        }
                        Self.logger.info("inputTextViewInputAt selectItem document data error")
                        return nil
                    case .unknown:
                        Self.logger.info("inputTextViewInputAt selectItem unknown")
                        return nil
                    case .chat:
                        Self.logger.info("inputTextViewInputAt selectItem chat will support")
                        assertionFailure("will support")
                        return nil
                    @unknown default:
                        return nil
                    }
                })
            }
            panel.show(from: fromVC)
        } else {
            var body = AtPickerBody(chatID: chat.id)
            body.cancel = cancel
            body.allowMyAI = config.supportAtMyAI
            if config.supportAtMyAI {
                try? config.userResolver.resolve(type: IMMyAIInlineService.self).trackInlineAIEntranceView(.mention)
            }
            if let callback = complete {
                body.completion = { items in
                    callback(items.map { .chatter(.init(id: $0.id, name: $0.name, actualName: $0.actualName, isOuter: $0.isOuter)) })
                }
            }
            config.userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: fromVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.autoAdaptStyle() }
            )
        }
    }

    public func panel(didFinishWith items: [IMMentionOptionType]) {
        self.completeTask?(items)
    }

    public func panelDidCancel() {
        self.cancelTask?()
    }
}
