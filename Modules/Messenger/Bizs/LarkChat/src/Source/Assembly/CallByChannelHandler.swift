//
//  CallAction.swift
//  LarkCore
//
//  Created by chengzhipeng-bytedance on 2018/8/21.
//

import UIKit
import LarkActionSheet
import Foundation
import RxSwift
import LarkContainer
import LarkModel
import Swinject
import UniverseDesignToast
import LarkFoundation
import EENavigator
import LarkCore
import LKCommonsTracker
import LarkAlertController
import LarkFeatureGating
import Homeric
import LarkSDKInterface
import LKCommonsLogging
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkUIKit
import UniverseDesignIcon
import LarkSetting
import LarkNavigator

/// 用户从哪个地方点击拨打电话
/// 点击拨打电话后出现手机通话、语音通话、视频通话、加密通话等选项的action sheet
enum CallScene: String {
    /// 会话界面
    case chat
    /// 个人名片页
    case profile
}

final class AppTracker {

    /// 点击拨打企业电话
    static func chatCompanyCallClick(scene: CallScene) {
        var event = ""
        switch scene {
        case .chat:
            event = "im_call_select_click"
        case .profile:
            event = "profile_voice_call_select_click"
        }
        Tracker.post(TeaEvent(event, params: ["click": "office_call", "target": "none"]))
    }

    /// 点击拨打电话
    static func chatCallClick(scene: CallScene, vc: UIViewController) {
        var params = ["from": scene.rawValue]
        if #available(iOS 13.0, *), let sceneInfo = vc.currentScene()?.sceneInfo {
            params["is_aux_window"] = sceneInfo.isMainScene() ? "false" : "true"
        }
        Tracker.post(TeaEvent(Homeric.CHAT_CALL_CLICK, params: params))
    }

    /// 点击拨打电话后，点击手机通话
    static func chatCallPhoneClick(scene: CallScene) {
        Tracker.post(TeaEvent(Homeric.CHAT_CALL_PHONE_CLICK, params: ["from": scene.rawValue]))
    }

    /// 点击拨打电话后，点击语音通话
    static func chatCallVoiceClick(scene: CallScene) {
        Tracker.post(TeaEvent(Homeric.CHAT_CALL_VOICE_CLICK, params: ["from": scene.rawValue]))
    }

    /// 点击拨打电话后，点击视频通话
    static func chatCallVideoClick(scene: CallScene) {
        Tracker.post(TeaEvent(Homeric.CHAT_CALL_VIDEO_CLICK, params: ["from": scene.rawValue]))
    }

    /// 点击拨打电话后，点击加密通话
    static func chatCallVoipClick(scene: CallScene) {
        Tracker.post(TeaEvent(Homeric.CHAT_CALL_VOIP_CLICK, params: ["from": scene.rawValue]))
    }

    /// 点击拨打电话后，点击通话取消
    static func chatCallCancelClick() {
        Tracker.post(TeaEvent(Homeric.CHAT_CALL_CANCEL_CLICK))
    }

    // profile 页面 CTA语音通话icon,点击action sheet电话通话的次数
    static func chatPhoneCallClick() {
        Tracker.post(TeaEvent(Homeric.PROFILE_CTA_PHONE_CALL_CLICK, params: [:]))
    }
}

/// 单向联系人打点
extension AppTracker {
    /// 音视频，电话屏蔽阻塞协作
    static func trackCallCollaborationCancelBlock(_ source: AddContactApplicationSource) {
        var resultStr = ""
        switch source {
        case .videoCall:
            resultStr = "VC"
        case .voiceCall:
            resultStr = "voice_call"
        case .phoneCall:
            resultStr = "phonecall"
        default:
            resultStr = ""
        }

        Tracker.post(
            TeaEvent(
                Homeric.COLLABORATION_CANCEL_BLOCK,
                params: ["source": resultStr]
            )
        )
    }
}

open class CallByChannelHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    private enum CallItemType {
        case companyCall
        case phoneCall
        case voiceCall(Bool)
        case videoCall(Bool)
        case sosCall
    }

    let disposeBag: DisposeBag = DisposeBag()

    static let logger = Logger.log(CallByChannelHandler.self, category: "CallByChannelHandler.Log")

    private var isE2EeMeetingEnable: Bool {
        userResolver.fg.staticFeatureGatingValue(with: "byteview.meeting.e2ee_meeting")
    }

    /// SOS
    var sosCallId: String?
    var actionSheetAdapter: ActionSheetPopoverAdapter?

    var addContactApplicationSource: AddContactApplicationSource = .voiceCall

    public func handle(_ body: CallByChannelBody, req: EENavigator.Request, res: Response) throws {
        CallByChannelHandler.logger.debug("channel action sheet : \(body)")
        guard let vc = req.from.fromViewController else {
            assertionFailure()
            return
        }
        AppTracker.chatCallClick(scene: body.channelType == .chat ? .chat : .profile, vc: vc)
        let resolver = self.resolver
        let callItemTypes: [CallItemType] = supportedCallItemTypes(body: body)

        guard !callItemTypes.isEmpty else {
            assertionFailure("call items is empty")
            res.end(resource: EmptyResource())
            return
        }
        let from = WindowTopMostFrom(vc: vc)

        if let firstType = callItemTypes.first, callItemTypes.count == 1 {
            let actionBlock = generateCallAction(type: firstType, body: body, from: from)
            actionBlock()
        } else {
            /// 显示 actionSheet 选择菜单
            let actionSheetAdapter = ActionSheetPopoverAdapter()
            self.actionSheetAdapter = actionSheetAdapter
            let acitonSheet = actionSheetAdapter.create(sourceView: body.sender, sourceRect: body.sender?.bounds ?? .zero)
            for itemType in callItemTypes {
                let actionBlock = generateCallAction(type: itemType, body: body, from: from)
                switch itemType {
                case .companyCall:
                    actionSheetAdapter.addItem(
                        title: BundleI18n.LarkChat.View_MV_OfficePhonePaid,
                        icon: UDIcon.officephoneOutlined.ud.withTintColor(UIColor.ud.iconN1),
                        entirelyCenter: true,
                        action: actionBlock)
                case .phoneCall:
                    actionSheetAdapter.addItem(
                        title: try allowsCompanyCall(body: body) ? BundleI18n.LarkChat.View_MV_SelfPhoneHere :
                            BundleI18n.LarkChat.Lark_Legacy_StartPhoneCall,
                        icon: Resources.call_up_icon,
                        entirelyCenter: true,
                        action: actionBlock)
                    if let fromWhere = body.fromWhere, fromWhere == "profile" {
                        AppTracker.chatPhoneCallClick()
                    }
                case .voiceCall(let isE2Ee):
                    let title = isE2Ee ? BundleI18n.LarkChat.View_G_VoiceCallEncrypt_Button : BundleI18n.LarkChat.Lark_View_VoiceCallName
                    actionSheetAdapter.addItem(
                        title: title,
                        icon: Resources.voice_call_icon,
                        entirelyCenter: true,
                        action: actionBlock)
                case .videoCall(let isE2Ee):
                    let dependency = try resolver.resolve(assert: ChatByteViewDependency.self)
                    let title = isE2Ee ? BundleI18n.LarkChat.View_G_VideoCallEncrypt_Button : dependency.serviceCallName
                    actionSheetAdapter.addItem(
                        title: title,
                        icon: Resources.video_call_icon,
                        entirelyCenter: true,
                        action: actionBlock)
                case .sosCall:
                    actionSheetAdapter.addItem(
                        title: BundleI18n.LarkChat.Lark_Legacy_UrgentCallEntrance,
                        textColor: UIColor.ud.colorfulRed,
                        icon: Resources.call_sos,
                        entirelyCenter: true,
                        action: actionBlock)
                }
            }
            /// cancel
            actionSheetAdapter.addCancelItem(title: BundleI18n.LarkChat.Lark_Legacy_Cancel) {
                AppTracker.chatCallCancelClick()
            }
            /// show action sheet
            guard let from = req.context.from() else {
                assertionFailure()
                return
            }
            navigator.present(acitonSheet, from: from)
        }
        res.end(resource: EmptyResource())
    }

    private func supportedCallItemTypes(body: CallByChannelBody) -> [CallItemType] {
        var callItemTypes: [CallItemType] = []
        /// Encrypted Call
        let isE2Ee = body.inCryptoChannel && isE2EeMeetingEnable

        /// Voice Call
        callItemTypes.append(.voiceCall(isE2Ee))

        /// Video call
        if body.isShowVideo {
            callItemTypes.append(.videoCall(isE2Ee))
        }

        if (try? self.allowsCompanyCall(body: body)) == true {
            callItemTypes.append(.companyCall)
        }

        Feature.on(.phoneCall).apply(on: {
            /// Call
            /// 同租户才能拨打手机号
            // code_next_line tag CryptChat
            guard !body.isCrossTenant && !body.inCryptoChannel else {
                return
            }
            callItemTypes.append(.phoneCall)
        }, off: {})

        /// 全球SOS呼叫
        if userResolver.fg.staticFeatureGatingValue(with: .init(key: .sosCallInChat)),
           !body.inCryptoChannel {
            callItemTypes.append(.sosCall)
        }

        return callItemTypes
    }

    // 跳转到加好友弹窗
    private func presentToAddContactAlert(userId: String,
                                          chatId: String,
                                          displayName: String,
                                          from: NavigatorFrom?) {
        guard let from = from else {
            assertionFailure()
            return
        }
        var source = Source()
        source.sourceType = .chat
        source.sourceID = chatId
        let content = BundleI18n.LarkChat.Lark_NewContacts_AddToContactsDialogContent
        let addContactBody = AddContactApplicationAlertBody(userId: userId,
                                                            chatId: chatId,
                                                            source: source,
                                                            displayName: displayName,
                                                            content: content,
                                                            targetVC: from,
                                                            businessType: .chatVCConfirm)
        navigator.present(body: addContactBody, from: from)
    }

    private func generateCallAction(type: CallItemType, body: CallByChannelBody, from: NavigatorFrom) -> (() -> Void) {
        let action = _generateCallAction(type: type, body: body, from: from)
        return {
            do {
                try action()
            } catch {
                Self.logger.error("call action handle \(type) \(body) error", error: error)
            }
        }
    }
    private func _generateCallAction(type: CallItemType, body: CallByChannelBody, from: NavigatorFrom) -> (() throws -> Void) {
        let actionBlock: (() throws -> Void)
        let errorBlcok: ((Error?) -> Void)? = { [weak self] (error) in
            func task() {
                guard let self = self, let error = error else { return }
                Self.logger.error("call action handle error", error: error)
                guard !body.chatterName.isEmpty,
                    !body.chatterAvatarKey.isEmpty else {
                    return
                }
                guard let fromView = from.fromViewController?.view else {
                    assertionFailure()
                    return
                }

                if let apiError = error.underlyingError as? APIError {
                    switch apiError.type {
                    case .collaborationAuthFailedNoRights:
                        self.presentToAddContactAlert(userId: body.chatterId,
                                                      chatId: body.chatId ?? "",
                                                      displayName: body.displayName,
                                                      from: from
                        )
                    case .collaborationAuthFailedBlocked(let message):
                        UDToast.showFailure(with: message, on: fromView, error: error)
                    case .collaborationAuthFailedBeBlocked(let message):
                        UDToast.showFailure(with: message, on: fromView, error: error)
                    default:
                        return
                    }
                } else {
                    let vcError = error as? CollaborationError
                    switch vcError {
                    case .collaborationBlocked:
                        AppTracker.trackCallCollaborationCancelBlock(self.addContactApplicationSource)
                        ChatTracker.trackChatCallBlock(self.addContactApplicationSource)
                        UDToast.showFailure(with: BundleI18n.LarkChat.View_G_NoPermissionsToCallBlocked, on: fromView, error: error)
                    case .collaborationBeBlocked:
                        AppTracker.trackCallCollaborationCancelBlock(self.addContactApplicationSource)
                        ChatTracker.trackChatCallBlock(self.addContactApplicationSource)
                        UDToast.showFailure(with: BundleI18n.LarkChat.View_G_NoPermissionsToCall, on: fromView, error: error)
                    case .collaborationNoRights:
                        self.presentToAddContactAlert(userId: body.chatterId,
                                                 chatId: body.chatId ?? "",
                                                 displayName: body.displayName,
                                                 from: from
                        )
                    default:
                        return
                    }
                }
            }
            if Thread.isMainThread {
                task()
            } else {
                DispatchQueue.main.async {
                    task()
                }
            }
        }
        switch type {
        case .companyCall:
            actionBlock = { [weak self] in
                guard let `self` = self else { return }
                Self.logger.info("do call action by companyCall")
                AppTracker.chatCompanyCallClick(scene: body.channelType == .chat ? .chat : .profile)
                let dependency = try self.resolver.resolve(assert: ChatByteViewDependency.self)
                dependency.startCompanyCall(calleeUserId: body.chatterId,
                                            calleeName: !body.chatterName.isEmpty ? body.chatterName : body.displayName,
                                            calleeAvatarKey: body.chatterAvatarKey,
                                            chatId: body.chatId ?? "")
                body.clickBlock?(false)
            }
        case .phoneCall:
            actionBlock = { [weak self] in
                guard let `self` = self else { return }
                if let chat = body.chat {
                    IMTracker.Call.Select.Click.Real(chat)
                }
                Self.logger.info("do call action by phoneCall")
                AppTracker.chatCallPhoneClick(scene: body.channelType == .chat ? .chat : .profile)
                let callRequestService = try self.resolver.resolve(assert: CallRequestService.self)
                self.addContactApplicationSource = .phoneCall
                callRequestService.callChatter(chatterId: body.chatterId, chatId: body.chatId ?? "", deniedAlertDisplayName: body.displayName, from: from, errorBlock: errorBlcok, actionBlock: nil)
                body.clickBlock?(true)
            }
        case .voiceCall(let isE2Ee):
            actionBlock = { [weak self] in
                guard let `self` = self else { return }
                if let chat = body.chat {
                    IMTracker.Call.Select.Click.Voice(chat)
                }
                Self.logger.info("do call action by voiceCall")
                AppTracker.chatCallVoiceClick(scene: body.channelType == .chat ? .chat : .profile)
                let dependency = try self.resolver.resolve(assert: ChatByteViewDependency.self)
                let secureChatId = body.inCryptoChannel ? body.chatId : ""
                self.addContactApplicationSource = .voiceCall
                dependency.start(userId: body.chatterId,
                                 source: body.channelType == ChannelType.chat ? .rightUpCornerButton : .addressBookCard,
                                 secureChatId: secureChatId ?? "",
                                 isVoiceCall: true,
                                 isE2Ee: isE2Ee,
                                 fail: errorBlcok)
                body.clickBlock?(false)
            }
        case .videoCall(let isE2Ee):
            actionBlock = { [weak self] in
                guard let `self` = self else { return }
                if let chat = body.chat {
                    IMTracker.Call.Select.Click.VC(chat)
                }
                Self.logger.info("do call action by videoCall")
                AppTracker.chatCallVideoClick(scene: body.channelType == .chat ? .chat : .profile)
                let dependency = try self.resolver.resolve(assert: ChatByteViewDependency.self)
                let secureChatId = body.inCryptoChannel ? body.chatId : ""
                self.addContactApplicationSource = .videoCall
                dependency.start(userId: body.chatterId,
                                 source: body.channelType == ChannelType.chat ? .rightUpCornerButton : .addressBookCard,
                                 secureChatId: secureChatId ?? "",
                                 isVoiceCall: false,
                                 isE2Ee: isE2Ee,
                                 fail: errorBlcok)
                body.clickBlock?(false)
            }
        case .sosCall:
            actionBlock = { [weak self] in
                guard let `self` = self else { return }
                Self.logger.info("do call action by sosCall")
                self.startupSOSCallProcess(configurationAPI: try self.resolver.resolve(assert: ConfigurationAPI.self),
                                           chatAPI: try self.resolver.resolve(assert: ChatAPI.self),
                                           calleeUserId: body.chatterId,
                                           from: from,
                                           updateCallIdHandler: { [weak self] (sosCallId: String) in
                                            self?.sosCallId = sosCallId
                })
                body.clickBlock?(false)
            }
        }
        return actionBlock
    }

    private func allowsToCall(from: NavigatorFrom) throws -> Bool {
        let dependency = try resolver.resolve(assert: ChatByteViewDependency.self)
        let isLocked: Bool
        if dependency.hasCurrentModule() {
            isLocked = true
            let text = (dependency.isRinging() == true) ? dependency.inRingingCannotCallVoIPText() : dependency.isInCallText()
            if let view = from.fromViewController?.viewIfLoaded {
                UDToast.showTips(with: text, on: view)
            }
        } else {
            isLocked = false
        }
        return !isLocked
    }

    private func allowsCompanyCall(body: CallByChannelBody) throws -> Bool {
        let dependency = try self.resolver.resolve(assert: ChatByteViewDependency.self)
        let isCompanyCallEnabled = dependency.isCompanyCallEnabled
        if !body.isCrossTenant && !body.inCryptoChannel && isCompanyCallEnabled && !Display.pad {
            return true
        }
        return false
    }
}
