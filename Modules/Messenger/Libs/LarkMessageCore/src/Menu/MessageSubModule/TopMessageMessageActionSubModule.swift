//
//  TopMessage.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/5.
//

import LarkModel
import RxSwift
import RustPB
import LarkMessageBase
import LarkMessengerInterface
import LarkContainer
import LarkCore
import UniverseDesignToast
import LarkOpenChat
import LarkAccountInterface
import LarkFeatureGating
import LKCommonsTracker

public final class TopMessageMessageActionSubModule: MessageActionSubModule {
    private let disposeBag = DisposeBag()
    private lazy var topNoticeSubject: BehaviorSubject<ChatTopNotice?>? = {
        return  self.context.pageAPI?.topNoticeSubject
    }()

    @ScopedInjectedLazy private var userActionService: TopNoticeUserActionService?
    @ScopedInjectedLazy var passportService: PassportUserService?
    @ScopedInjectedLazy private var topNoticeService: ChatTopNoticeService?

    public override var type: MessageActionType {
        return .topMessage
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    private func topHandle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI, let userActionService = self.userActionService else { return }
        TopMessageMenuAction.topMessage(chat: chat,
                                       message: message,
                                       userActionService: userActionService,
                                       hasNotice: true,
                                       targetVC: targetVC,
                                       disposeBag: disposeBag,
                                       chatFromWhere: nil)
    }

    private func cancelHandle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI, let userActionService = self.userActionService else { return }
        TopMessageMenuAction.cancelTopMessage(chat: chat,
                                             message: message,
                                             userActionService: userActionService,
                                             topNotice: try? topNoticeSubject?.value(),
                                             currentUserID: passportService?.user.userID ?? "",
                                             nav: self.context.nav,
                                             targetVC: targetVC,
                                             disposeBag: disposeBag,
                                             featureGatingService: self.context.userResolver.fg,
                                             chatFromWhere: nil)
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if ChatNewPinConfig.supportPinMessage(chat: model.chat, self.context.userResolver.fg) {
            return false
        }
        guard let topNoticeSubject = self.topNoticeSubject else { return false }
        return true
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let hasTopNotice = true
        var params: [AnyHashable: Any] = ["click": "pin_to_top", "target": "none"]

        let currentTopNotice = try? topNoticeSubject?.value()
        let type = topNoticeService?.topNoticeActionMenu(model.message, chat: model.chat, currentTopNotice: currentTopNotice)
        if type == .topMessage {
            params += ["have_pin_to_top": currentTopNotice != nil ? "true" : "false",
                       "status": "pin_to_top"]
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IMChatPin_PinMessage_Option,
                                     icon: BundleResources.Menu.menu_top,
                                     trackExtraParams: params) { [weak self] in
                self?.topHandle(message: model.message, chat: model.chat)
            }
        } else if type == .cancelTopMessage {
            params += ["have_pin_to_top": currentTopNotice != nil ? "true" : "false",
                       "status": "unpin_to_top"]
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IMChatPin_RemovePin_Option,
                                     icon: BundleResources.Menu.menu_cancelTop,
                                     trackExtraParams: params) { [weak self] in
                self?.cancelHandle(message: model.message, chat: model.chat)
            }
        } else {
            return nil
        }
    }
}
