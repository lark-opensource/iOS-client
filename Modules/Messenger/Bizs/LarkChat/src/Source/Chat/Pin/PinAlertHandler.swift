//
//  PinAlertHandler.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/6.
//

import UIKit
import Foundation
import EENavigator
import LarkModel
import Swinject
import LarkCore
import LarkKeyboardView
import LarkContainer
import LarkUIKit
import RxSwift
import LarkAlertController
import SnapKit
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigator

final class PinAlertHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    func handle(_ body: DeletePinAlertBody, req: EENavigator.Request, res: Response) throws {
        let chatSecurity: ChatSecurityControlService = try userResolver.resolve(assert: ChatSecurityControlService.self)
        /// dependancy
        let checkIsMe = { [me = userResolver.userID] id in me == id || id == body.chat.anonymousId }
        let isGroupOwner = userResolver.userID == body.chat.ownerId
        let pinAPI: PinAPI = try resolver.resolve(assert: PinAPI.self)
        let calendarInterface = try resolver.resolve(assert: ChatCalendarDependency.self)
        let enterpriseEntityService = try resolver.resolve(assert: EnterpriseEntityWordService.self)
        let abbreviationEnable = enterpriseEntityService.abbreviationHighlightEnabled()
        let permissionPreview: (Bool, ValidateResult?) = chatSecurity.checkPermissionPreview(anonymousId: body.chat.anonymousId, message: body.message)
        let dynamicAuthorityEnum: DynamicAuthorityEnum = chatSecurity.getDynamicAuthorityFromCache(event: .receive,
                                                                                                       message: body.message,
                                                                                                       anonymousId: body.chat.anonymousId)
        /// confirm content view
        let pinConfirmProvider = PinAlertViewModelProvider(
            checkIsMe: checkIsMe,
            hasJoinedChat: body.shareChat?.role == .member,
            abbreviationEnable: abbreviationEnable,
            getSenderName: { chatter in
                return chatter.displayName(chatId: body.chat.id, chatType: body.chat.type, scene: .pin)
            },
            eventTimeDescription: { (start, end, isAllDay) in
                return calendarInterface.eventTimeDescription(start: start, end: end, isAllDay: isAllDay)
            }, permissionPreview: permissionPreview,
            dynamicAuthorityEnum: dynamicAuthorityEnum,
            settingGifLoadConfig: try resolver.resolve(assert: UserGeneralSettings.self).gifLoadConfig
        )
        let confirmView: UIView? = PinConfirmAlertFactory.createPinConfirmAlertView(userResolver: userResolver, body.message, dataProvider: pinConfirmProvider)

        guard let contentView = confirmView else { return }

        let alertController = LarkAlertController()
        contentView.snp.makeConstraints { (make) in
            make.width.equalTo(LarkChatUtils.pinAlertConfirmMaxWidth)
        }
        alertController.setContent(view: contentView)

        /// alert view
        let messageId = body.message.id
        let chatId = body.message.channel.id

        let unPinTitle = body.chat.chatMode == .threadV2 ? BundleI18n.LarkChat.Lark_Chat_TopicToolUnPinAlertTitle : BundleI18n.LarkChat.Lark_Pin_TipForUnpinConfirmation
        let confirmText = BundleI18n.LarkChat.Lark_Groups_UnpinButton
        alertController.setTitle(text: unPinTitle, alignment: .left, numberOfLines: 2)
        alertController.addCancelButton(dismissCompletion: {
            ChatTracker.trackPinAlertCancel(
                message: body.message,
                isGroupOwner: isGroupOwner,
                chat: body.chat
            )
        })

        alertController.addPrimaryButton(text: confirmText, dismissCompletion: {
            /*func deletePin函数里有包装doOnNext操作。此处不能使用self.disposeBag, deletePin为异步操作，
             在异步执行期间handler就销毁了，会导致订阅关系非提前结束，doOnNext没有执行*/
            _ = pinAPI.deletePin(messageId: messageId, chatId: chatId).subscribe()
            ChatTracker.trackDeletePin(
                message: body.message,
                groupId: chatId,
                isGroupOwner: isGroupOwner,
                location: ChatTracker.DeletePinLocation(rawValue: body.from.rawValue) ?? .inChat
            )
            ChatTracker.trackPinAlertConfirm(message: body.message, isGroupOwner: isGroupOwner, chat: body.chat)
            if body.chat.chatMode == .threadV2 {
                IMTracker.Msg.Menu.More.Click.UnPin(body.chat, body.message)
            }
            if var targetVC = body.targetVC?.parent {
                while !(targetVC is ChatContainerViewController), let parent = targetVC.parent {
                    targetVC = parent
                }

                if let chatContainerVC = targetVC as? ChatContainerViewController {
                    chatContainerVC.guideManager.checkShowGuideIfNeeded(.pinSide)
                }
            }
        })
        navigator.present(alertController, from: req.from)
        ChatTracker.imUnpinConfirmView(chat: body.chat)
    }
}
