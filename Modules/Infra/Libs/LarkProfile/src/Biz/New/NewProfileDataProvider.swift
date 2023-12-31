////
////  ProfileDataProvider.swift
////  LarkProfile
////
////  Created by Yuri on 2022/8/9.
////
//
import Foundation
import UIKit
import RxSwift
import LarkSDKInterface
import RustPB
import LarkFeatureGating
import UniverseDesignIcon
import LarkMessengerInterface
import LarkNavigator
import EENavigator
import LarkModel
import LKCommonsTracker

public final class NewProfileDataProvider: LarkProfileDataProvider {
    
    /// 参数: userInfo, isSelf, fromPush(是否是签名push触发)
    var didUpdateUserInfoHandler: ((_ profile: ProfileInfoProtocol, _ isMe: Bool, _ isLocal: Bool, _ descUpdate: Bool) -> Void)?
    var didFetchErrorHandler: (() -> Void)?
    
    // nolint: duplicated_code - 本次需求没有QA，为了避免产生问题，会在后期FG下线技术需求统一处理
    override func fetchUserProfileInformation(whenDescriptionUpdate: Bool = false) {
        let timeStamp = CACurrentMediaTime()
        /// 远程异步获取一次
        guard let profileAPI = self.profileAPI,
              let userId = self.data.chatterId else { return }
        Self.logger.info("fetch userProfile remote data")
        profileAPI
            .fetchUserProfileInfomation(userId: userId,
                                        contactToken: self.data.contactToken,
                                        chatId: self.data.chatId,
                                        sourceType: self.data.source)
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (remoteData) in
                guard let `self` = self else {
                    return
                }
                LarkProfileDataProvider.logger.info("new fetchUserProfile remote tabOrders: \(remoteData.tabOrders.count) fieldOrders: \(remoteData.fieldOrders.count) ctaOrders: \(remoteData.ctaOrders.count)")
                /// 计算网络请求时间
                let networkCost = CACurrentMediaTime() - timeStamp
                ProfileReciableTrack.updateUserProfileSDKNetworkCost(networkCost)
                self.updateUserProfile(remoteData, isLocal: false, descriptionUpdate: whenDescriptionUpdate)
                self.isRemote = true

                var contactType = ""
                if self.currentChatterId == remoteData.userInfo.userID {
                    contactType = "self"
                } else if self.isSameTenant {
                    contactType = "internal"
                } else if remoteData.userInfo.friendStatus == .double {
                    contactType = "external_friend"
                } else {
                    contactType = "external_nonfriend"
                }
                if self.tracker == nil {
                    self.tracker = LarkProfileTracker(resolver: self.userResolver, userProfile: remoteData, contactType: contactType)
                }
                guard self.alreadyTrackMainView == false else {
                    return
                }
                self.tracker?.trackMainView(enableMedal: self.enabelMedal)
                self.alreadyTrackMainView = true
                let userProfileTrackKey = ProfileReciableTrack.getUserProfileKey()
                ProfileReciableTrack.trackUserProfileEndCostOnRefresh(key: userProfileTrackKey)
            }, onError: { [weak self] (error) in
                guard let self = self, self.alreadyTrackMainView == false else {
                    return }
                LarkProfileDataProvider.logger.info("fetch userProfile infomation failure: \(error)")
                self.trackProfileMainViewWithoutInfo()
                self.alreadyTrackMainView = true
                if self.userProfile == nil {
                    self.statusReplay.onNext(.error)
                    self.didFetchErrorHandler?()
                    if let apiError = error.underlyingError as? APIError {
                        ProfileReciableTrack.userProfileLoadNetworkError(errorCode: Int(apiError.errorCode),
                                                                     errorMessage: apiError.localizedDescription)
                    } else {
                        ProfileReciableTrack.userProfileLoadNetworkError(errorCode: (error as NSError).code,
                                                                     errorMessage: (error as NSError).localizedDescription)
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    
    func updateUserProfile(_ userProfile: ProfileInfoProtocol, isLocal: Bool, descriptionUpdate: Bool) {
        super.updateUserProfile(userProfile, isLocal: isLocal)
        DispatchQueue.global().async {
            self.didUpdateUserInfoHandler?(userProfile, self.isMe, isLocal, descriptionUpdate)
        }
    }
    
    override func updateUserProfile(_ userProfile: ProfileInfoProtocol, isLocal: Bool) {
        super.updateUserProfile(userProfile, isLocal: isLocal)
        self.didUpdateUserInfoHandler?(userProfile, self.isMe, isLocal, false)
    }
    
    override func getUserInformation() {
        
    }
    
    public override func loadUserInfo() {
        if isAIProfile {
            Self.logger.info("[MyAI.Profile][Preview][\(#function)] request AI profile, is mine: \(isMyAIProfile)")
            self.getAIProfileInformation(forceServer: false)
            self.getAIProfileInformation(forceServer: true)
            if isMyAIProfile {
                self.myAIService?.info
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        Self.logger.info("[MyAI.Profile][Preview][\(#function)] observe AI info change")
                        self?.updateAIProfileInformation()
                    }).disposed(by: disposeBag)
            }
        } else {
            self.getUserProfileInformation()
            self.fetchUserProfileInformation()
        }
    }
    
    override func generateUserDescription(userInfo: UserInfoProtocol) -> ProfileStatusView? {
        return nil
    }
    
    // nolint: long_function - 本次需求没有QA，为了避免产生问题，会在后期FG下线技术需求统一处理
    // nolint: duplicated_code - 本次需求没有QA，为了避免产生问题，会在后期FG下线技术需求统一处理
    // swiftlint:disable function_body_length
    func getCTA(with icons: [ProfileResourceLoader.IconKey: UIImage]) -> [ProfileCTAItem] {
        guard let ctaOrders = userProfile?.ctaOrders,
              let userInfo = userProfile?.userInfoProtocol else {
            return []
        }
        var chatSource = LarkUserProfilChatSource()
        chatSource.senderIDV2 = self.data.senderID
        chatSource.sourceID = self.data.sourceID
        chatSource.sourceName = self.data.sourceName
        chatSource.sourceType = self.data.source
        chatSource.subSourceType = self.data.subSourceType
        var ctas: [ProfileCTAItem] = []
        for (_, cta) in ctaOrders.enumerated() {
            var icon = UIImage()
            var tapCallback: (() -> Void)?
            var longPressCallback: (() -> Void)?
            switch cta.ctaType {
            case .chat:
                icon = icons[.chatFilled] ?? UIImage()
                tapCallback = { [weak self] in
                    guard let `self` = self, let fromVC = self.profileVC else { return }
                    self.dependency?.jumpToChatViewController(userInfo.userID,
                                                              isCrypto: false,
                                                              fromVC: fromVC,
                                                              needShowErrorAlert: true,
                                                              chatSource: chatSource,
                                                              source: self.data.source)
                    if self.userProfile?.userInfoProtocol.isResigned ?? false {
                        self.tracker?.trackMainClick("message_history", extra: ["target": "im_chat_main_view"])
                    } else {
                        self.tracker?.trackMainClick("message", extra: ["target": "im_chat_main_view"])
                    }
                    if self.isAIProfile {
                        // 点击 AIProfile 聊天的埋点
                        Tracker.post(TeaEvent("profile_ai_main_click", params: [
                            "shadow_id": self.aiShadowID,
                            "contact_type": self.isMyAIProfile ? "self" : "none_self",
                            "click": "message"
                        ]))
                    }
                }
                // 端上长按发起密聊入口是否开启
                if !userResolver.fg.staticFeatureGatingValue(with: "im.chat.secure.function.disable") {
                    let tempLongPressCallback: () -> Void = { [weak self] in
                        LarkProfileDataProvider.logger.info("crypto limit trace in longPressCallback \(userInfo.userID)")
                        // 跳转密聊
                        guard let `self` = self,
                              self.currentChatterId != userInfo.userID,
                              !userInfo.isResigned,
                              let fromVC = self.profileVC else { return }
                        let needShowErrorAlert: Bool = self.userResolver.fg.staticFeatureGatingValue(with: "im.chat.secure.unavailable.toast")
                        self.dependency?.jumpToChatViewController(userInfo.userID,
                                                                  isCrypto: true,
                                                                  fromVC: fromVC,
                                                                  needShowErrorAlert: needShowErrorAlert,
                                                                  chatSource: chatSource,
                                                                  source: self.data.source)
                        self.tracker?.trackMainClick("secret_message", extra: ["target": "im_chat_main_view"])
                    }
                    if let crytoCta = ctaOrders.first(where: { cta in
                        return cta.ctaType == .cryptoChat
                    }) {
                        LarkProfileDataProvider.logger.info("crypto limit trace find cryptoChat cta \(userInfo.userID)")
                        // 密聊cta点击入口被屏蔽
                        if crytoCta.deniedReason == .sendSecretChatByIconDeny {
                            longPressCallback = tempLongPressCallback
                            LarkProfileDataProvider.logger.info("crypto limit trace cryptoChat cta deniedReason equal sendSecretChatByIconDeny \(userInfo.userID)")
                        }
                    } else {
                        // 密聊cta彻底下掉
                        longPressCallback = tempLongPressCallback
                        LarkProfileDataProvider.logger.info("crypto limit trace can not find cryptoChat cta \(userInfo.userID)")
                    }
                }
            case .cryptoChat:
                icon = icons[.chatSecretFilled] ?? UIImage()
                tapCallback = { [weak self] in
                    guard let `self` = self, let fromVC = self.profileVC else { return }
                    self.dependency?.jumpToChatViewController(userInfo.userID,
                                                              isCrypto: true,
                                                              fromVC: fromVC,
                                                              needShowErrorAlert: true,
                                                              chatSource: chatSource,
                                                              source: self.data.source)
                    self.tracker?.trackMainClick("secret_message", extra: ["target": "im_chat_main_view"])
                }
            case .sPrivateMode:
                icon = icons[.privateSafeChatOutlined] ?? UIImage()
                tapCallback = { [weak self] in
                    LarkProfileDataProvider.logger.info("click privateModeChat, fromVC: \(String(describing: self?.profileVC))")
                    guard let `self` = self, let fromVC = self.profileVC else { return }
                    self.dependency?.jumpToChatViewController(userInfo.userID,
                                                              isCrypto: false,
                                                              isPrivate: true,
                                                              fromVC: fromVC,
                                                              needShowErrorAlert: true,
                                                              chatSource: chatSource,
                                                              source: self.data.source)
                    self.tracker?.trackMainClick("private_mode", extra: ["target": "im_chat_main_view"])
                }
            case .voice:
                icon = icons[.callFilled] ?? UIImage()
                tapCallback = { [weak self] in
                    guard let `self` = self, let fromVC = self.profileVC else { return }

                    let callByChannelBody = CallByChannelBody(chatterId: userInfo.userID,
                                                              chatId: nil,
                                                              displayName: userInfo.userName,
                                                              inCryptoChannel: false,
                                                              sender: nil,
                                                              isCrossTenant: !self.isSameTenant,
                                                              channelType: .psersion,
                                                              isShowVideo: false,
                                                              accessInfo: Chatter.AccessInfo(),
                                                              fromWhere: "profile",
                                                              chatterAvatarKey: userInfo.avatarKey) { [weak self] isPhone in
                        self?.tracker?.trackVoiceCallViewClick(isPhone: isPhone)
                    }
                    self.userResolver.navigator.push(body: callByChannelBody, from: fromVC)
                    self.tracker?.trackMainClick("voice_call", extra: ["target": "profile_voice_call_select_view"])
                    self.tracker?.trackVoiceCallView()
                }
            case .video:
                icon = icons[.videoFilled] ?? UIImage()
                tapCallback = { [weak self] in
                    guard let `self` = self else { return }
                    self.dependency?.startByteViewFromAddressBookCard(userId: userInfo.userID)
                    self.tracker?.trackMainClick("video_call", extra: ["target": "vc_meeting_calling_view"])
                }
            @unknown default:
                break
            }

            let item = ProfileCTAItem(title: cta.i18NNames.getString(),
                                      icon: icon.ud.withTintColor(UIColor.ud.colorfulBlue),
                                      enable: cta.enable,
                                      denyDescribe: cta.deniedDescription.getString(),
                                      tapCallback: tapCallback,
                                      longPressCallback: longPressCallback)
            // 根据权限过滤CTA
            if cta.ctaType == .chat
                || cta.ctaType == .sPrivateMode
                || cta.ctaType == .voice
                || cta.ctaType == .video
                || (cta.ctaType == .cryptoChat && secretChatEnable) {
                ctas.append(item)
            }
        }
        // 若不需折叠，展示所有CTA
        var maxCounts = ctas.count > LarkProfileDataProvider.maxButtonCount ? LarkProfileDataProvider.maxButtonCount : ctas.count
        // 最多展示n个CTA，但CTA的数量m大于n时，将后m-n+1个CTA折叠在actionSheet中,
        if ctas.count > LarkProfileDataProvider.maxButtonCount {
            self.foldCTA(&ctas)
        }
        return Array(ctas[0..<maxCounts])
    }
    // swiftlint:enable function_body_length
    
    // MARK: - Track
    func trackPushDescription(length: Int) {
        tracker?.trackMainClick("signature", extra: ["target": "profile_signature_setting_view",
                                                           "signature_length": length])
    }
}
