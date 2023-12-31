//
//  AtPickerHandler.swift
//  LarkChat
//
//  Created by 李晨 on 2019/3/3.
//

import Foundation
import Swinject
import EENavigator
import LarkModel
import LarkCore
import LarkUIKit
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigator

final class AtPickerHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: AtPickerBody, req: Request, res: Response) throws {
        AtAppReciableTracker.start()
        guard let chat: Chat = try resolver.resolve(assert: ChatAPI.self).getLocalChat(by: body.chatID) else {
            res.end(error: RouterError.invalidParameters("chat is inexistence"))
            return
        }

        AtAppReciableTracker.update(chatType: getChatType(chat: chat))
        let isPublicThread = (chat.chatMode == .threadV2 && chat.isPublic)
        let groupMentionTipsEnable = userResolver.fg.staticFeatureGatingValue(with: .init(key: .groupMentionTipsEnable)) && isPublicThread
        let showDepartment = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.mention.display_department"))

        var atOuterText: String?
        if groupMentionTipsEnable {
            atOuterText = BundleI18n.LarkChat.Lark_Groups_MentionNonMembereTips
        } else {
            atOuterText = BundleI18n.LarkChat.Lark_Chat_AtNonChatMemberDescription
        }

        var viewModel = try AtPickerViewModel(
            userResolver: userResolver,
            chat: chat,
            atOuterText: atOuterText,
            allowAtAll: body.allowAtAll,
            allowSideIndex: body.allowSideIndex)
        viewModel.allowMyAi = body.allowMyAI
        viewModel.showDepartment = showDepartment
        let viewController = AtPickerController(viewModel: viewModel)

        viewController.selectUserCallback = body.completion
        viewController.closeCallback = body.cancel

        AtAppReciableTracker.initViewEnd()

        res.end(resource: viewController)
    }

    @inline(__always)
    private func getChatType(chat: Chat) -> AtAppReciableTracker.ChatType {
        if chat.type == .p2P {
            return .single
        }
        if chat.type == .group {
            return .group
        }
        if chat.chatMode == .threadV2 || chat.chatMode == .thread {
            return .topic
        }
        return .threadDetail
    }
}
