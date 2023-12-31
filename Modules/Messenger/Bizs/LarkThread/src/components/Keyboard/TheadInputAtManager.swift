//
//  TheadInputAtManager.swift
//  LarkThread
//
//  Created by liluobin on 2023/4/13.
//

import LarkFeatureGating
import LarkIMMention
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import LarkCore
import LarkMessageCore
import LarkKeyboardView
import LarkModel
import LKCommonsLogging
import LarkBaseKeyboard
import LarkContainer

class TheadInputAtManager: UserResolverWrapper {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    static let logger = Logger.log(TheadInputAtManager.self,
                                   category: "TheadInputAtManager")

    private var completeTask: (([IMMentionOptionType]) -> Void)?
    private var cancelTask: (() -> Void)?

    private lazy var mentionOptEnable: Bool =
        userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.corporate_aite_clouddocuments"))

    func inputTextViewInputAt(fromVC: UIViewController?,
                              chat: Chat,
                              cancel: (() -> Void)?,
                              complete: (([InputKeyboardAtItem]) -> Void)?) {

        guard let fromVC = fromVC else {
            assertionFailure("miss From VC")
            return
        }

        if self.mentionOptEnable {
            // 话题群键盘点击@
            let mentionChatModel = IMMentionChatConfig(id: chat.id,
                                                       userCount: chat.userCount,
                                                       isEnableAtAll: false,
                                                       showChatUserCount: chat.isUserCountVisible)
            let panel = IMMentionPanel(resolver: self.userResolver, mentionChatModel: mentionChatModel)
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
                    }
                })
            }
            panel.show(from: fromVC)
        } else {
            var body = AtPickerBody(chatID: chat.id)
            body.allowAtAll = false
            body.allowMyAI = false
            body.cancel = cancel
            if let callback = complete {
                body.completion = { items in
                    callback(items.map { .chatter(.init(id: $0.id, name: $0.name, actualName: $0.actualName, isOuter: $0.isOuter)) })
                }
            }
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: fromVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.autoAdaptStyle() }
            )
        }
    }
}

extension TheadInputAtManager: IMMentionPanelDelegate {
    public func panel(didFinishWith items: [IMMentionOptionType]) {
        self.completeTask?(items)
    }

    public func panelDidCancel() {
        self.cancelTask?()
    }
}
