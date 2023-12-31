//
//  PhoneQueryLimitViewModel.swift
//  LarkMine
//
//  Created by 李勇 on 2019/4/28.
//

import UIKit
import Foundation
import LarkModel
import LarkMessengerInterface
import LarkFoundation
import UniverseDesignToast
import EENavigator
import RxSwift
import LarkSDKInterface
import LarkSendMessage
import LarkCore
import RustPB
import ServerPB
import LarkContainer
import LarkSetting
import LKCommonsLogging

final class PhoneQueryLimitViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    /// 咨询过相关人员，这里用optional
    private let byteViewDependency: ChatByteViewDependency
    private let chatterAPI: ChatterAPI
    private let userAppConfig: UserAppConfig
    private let sendMessageAPI: SendMessageAPI
    private let chatService: ChatService
    /// voip电话应该打对方
    private let chatterId: String
    /// 切换成普通语音通话错误处理需要的数据
    private let chatId: String
    private let deniedAlertDisplayName: String

    let queryQuota: ServerPB_Users_CheckUserPhoneNumberResponse
    /// 我的直属leader名字
    var leaderName: String = ""
    lazy var normalVoiceCall: Bool = userResolver.fg.staticFeatureGatingValue(with: "core_contact_phone_limit_voice_call")
    static let logger = Logger.log(PhoneQueryLimitViewModel.self, category: "Module.LarkChat.PhoneQueryLimit")
    weak var targetVc: UIViewController?

    init(userResolver: UserResolver,
         queryQuota: ServerPB_Users_CheckUserPhoneNumberResponse,
         chatterId: String,
         chatId: String,
         deniedAlertDisplayName: String,
         byteViewDependency: ChatByteViewDependency,
         chatterAPI: ChatterAPI,
         userAppConfig: UserAppConfig,
         sendMessageAPI: SendMessageAPI,
         chatService: ChatService) {
        self.userResolver = userResolver
        self.queryQuota = queryQuota
        self.chatterId = chatterId
        self.chatId = chatId
        self.deniedAlertDisplayName = deniedAlertDisplayName
        self.byteViewDependency = byteViewDependency
        self.chatterAPI = chatterAPI
        self.userAppConfig = userAppConfig
        self.sendMessageAPI = sendMessageAPI
        self.chatService = chatService
        // 同步获取leader名字
        if let queryQuotaStatus = QueryQuotaStatus(rawValue: queryQuota.status), queryQuotaStatus != .forbidTelPermission {
            if let chatter = chatterAPI.getChatterFromLocal(id: "\(self.queryQuota.leaderID)") {
                self.leaderName = chatter.displayName
            }
        }
    }

    /// 拨打手机电话
    func callPhone() {
        guard !self.queryQuota.phoneNumber.isEmpty, !LarkFoundation.Utils.isSimulator else {
            return
        }
        LarkFoundation.Utils.telecall(phoneNumber: self.queryQuota.phoneNumber)
    }

    /// 拨打语音电话
    func callVoipPhone(on view: UIView) {
        let errorBlcok: ((Error?) -> Void)? = { [weak self] (error) in
            func task() {
                guard let self = self, let error = error else { return }
                Self.logger.error("call action handle error", error: error)
                let vcError = error as? CollaborationError
                switch vcError {
                case .collaborationBlocked:
                    UDToast.showFailure(with: BundleI18n.LarkChat.View_G_NoPermissionsToCallBlocked, on: view, error: error)
                case .collaborationBeBlocked:
                    UDToast.showFailure(with: BundleI18n.LarkChat.View_G_NoPermissionsToCall, on: view, error: error)
                case .collaborationNoRights:
                    self.presentToAddContactAlert(userId: self.chatterId,
                                                  chatId: self.chatId,
                                                  displayName: self.deniedAlertDisplayName,
                                                  from: self.targetVc)
                default:
                    return
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
        /// 此处逻辑沿用VoIPCallAction
        byteViewDependency.start(userId: self.chatterId,
                                 source: .addressBookCard,
                                 secureChatId: "",
                                 isVoiceCall: true,
                                 isE2Ee: !normalVoiceCall,
                                 fail: errorBlcok)
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

    /// 申请额度
    func applyAmount() -> Observable<String> {
        /// 获取卡片内容 -> 创建会话 -> 发送卡片消息
        let applyAmountObservable: Observable<String> = self.chatterAPI.sendPhoneQueryQuotaApplyRequest(todayQueryTimes: Int32(queryQuota.todayCallCount) ?? 0)
            .flatMap { (cardContent) -> Observable<(CardContent, LarkModel.Chat)> in
                return self.chatService.createP2PChat(userId: "\(self.queryQuota.leaderID)", isCrypto: false, chatSource: nil)
                    .map({ (chat) -> (CardContent, LarkModel.Chat) in
                        return (cardContent, chat)
                    })
            }.flatMap { (result) -> Observable<String> in
                return self.sendCard(cardContent: result.0, chat: result.1)
                    .map({ (_) -> String in
                        return result.1.id
                    })
            }
        return applyAmountObservable
    }

    /// 发送卡片消息
    private func sendCard(cardContent: CardContent, chat: LarkModel.Chat) -> Observable<Void> {
        return Observable<Void>.create({ (observable) -> Disposable in
            self.sendMessageAPI.sendCard(
                context: nil,
                content: cardContent,
                chatId: chat.id,
                threadId: nil,
                parentMessage: nil,
                stateHandler: { (state) in
                    switch state {
                    case .getQuasiMessage: observable.onNext(())
                    default: break
                    }
                })
            return Disposables.create()
        })
    }

    /// 跳转到管控详情界面
    func jumpToDetail(from: UIViewController) {
        guard let helpUrlString = self.userAppConfig.resourceAddrWithLanguage(key: RustPB.Basic_V1_AppConfig.ResourceKey.helpAboutTelQueryLimit) else {
            return
        }
        guard let url = URL(string: helpUrlString) else {
            return
        }
        navigator.push(url, context: ["from": "lark"], from: from)
    }
}
