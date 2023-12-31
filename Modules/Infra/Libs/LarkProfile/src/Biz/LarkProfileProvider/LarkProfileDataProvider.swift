//
//  LarkProfileDataProvider.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/4.
//

import Foundation
import RxSwift
import RxCocoa
import LarkLocalizations
import ByteWebImage
import UniverseDesignIcon
import UniverseDesignTag
import RustPB
import EENavigator
import SwiftProtobuf
import RichLabel
import Swinject
import LarkMessengerInterface
import LarkContainer
import LarkSDKInterface
import UniverseDesignToast
import LarkFeatureGating
import LarkKAFeatureSwitch
import LarkAccountInterface
import LarkAppConfig
import LarkModel
import UniverseDesignDialog
import UniverseDesignActionPanel
import SuiteAppConfig
import LarkUIKit
import LarkBizAvatar
import LarkImageEditor
import UIKit
import FigmaKit
import UniverseDesignColor
import LKCommonsLogging
import ThreadSafeDataStructure
import LKCommonsTracker
import Homeric
import LarkActionSheet
import LarkContactComponent
import LarkSetting

public enum ProfileImageSizeType: String {
    case middle
    case origin
}

public struct LarkProfileData: ProfileData {
    public let chatterId: String?
    public let chatterType: Chatter.TypeEnum?
    public let chatId: String
    public let contactToken: String
    public let fromWhere: LarkUserProfileFromWhere

    /// PRD: https://bytedance.feishu.cn/docs/doccnlCxYN5ro5JkqkLmywQQ958#
    /// PB：https://review.byted.org/c/ee/lark/rust-sdk/+/1449540/4/im-protobuf-sdk/client/im/v1/chats.proto
    /// 发送来源ID
    public let senderID: String
    /// 发送来源
    public let sender: String
    /// 来源ID
    public let sourceID: String
    /// 来源名称
    public let sourceName: String
    /// 来源类型
    public let source: LarkUserProfileSource

    /// source子类型，透传。例如：source_type为doc，sub_type可能会有doc，表格，思维导图
    public let subSourceType: String
    /// extra parameters
    public let extraParams: [String: String]?

    /// profile页打开后，需要立即调整到设置页
    public let needToPushSetInformationViewController: Bool

    public init(chatterId: String?,
                chatterType: Chatter.TypeEnum?,
                contactToken: String,
                chatId: String = "",
                fromWhere: LarkUserProfileFromWhere = .none,
                senderID: String = "",
                sender: String = "",
                sourceID: String = "",
                sourceName: String = "",
                subSourceType: String = "",
                source: LarkUserProfileSource = .unknownSource,
                extraParams: [String: String]? = nil,
                needToPushSetInformationViewController: Bool = false
    ) {
        self.chatterId = chatterId
        self.chatterType = chatterType
        self.contactToken = contactToken
        self.chatId = chatId
        self.fromWhere = fromWhere
        self.senderID = senderID
        self.sender = sender
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.source = source
        self.subSourceType = subSourceType
        self.extraParams = extraParams
        self.needToPushSetInformationViewController = needToPushSetInformationViewController
    }
}

public protocol LarkProfileDataProviderDependency: AnyObject {
    func startByteViewFromAddressBookCard(userId: String)
    func jumpToChatViewController(_ userId: String,
                                  isCrypto: Bool,
                                  fromVC: UIViewController,
                                  needShowErrorAlert: Bool,
                                  chatSource: LarkUserProfilChatSource,
                                  source: LarkUserProfileSource)
    func jumpToChatViewController(_ userId: String,
                                  isCrypto: Bool,
                                  isPrivate: Bool,
                                  fromVC: UIViewController,
                                  needShowErrorAlert: Bool,
                                  chatSource: LarkUserProfilChatSource,
                                  source: LarkUserProfileSource)
}

public class LarkProfileDataProvider: ProfileDataProvider, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    
    static let logger = Logger.log(LarkProfileDataProvider.self, category: "LarkProfileDataProvider")

    lazy var tnsReport: Bool = userResolver.fg.staticFeatureGatingValue(with: "lark.tns.report")
    lazy var isUnifiedComponentFG: Bool = userResolver.fg.staticFeatureGatingValue(with: "ios.profile.tenantname.unified_component")
    public static var identifier: String = "LarkProfileDataProvider"

    public static func createDataProvider(by data: ProfileData, resolver: LarkContainer.UserResolver, factory: ProfileFactory?) -> ProfileDataProvider? {
        guard let data = data as? LarkProfileData else {
            return nil
        }
        return LarkProfileDataProvider(data: data, resolver: resolver, factory: factory)
    }

    public var shouldUpdateDefaultIndex: Bool {
        if _shouldUpdateDefaultIndex {
            _shouldUpdateDefaultIndex = false
            return true
        }

        return false
    }

    private var _shouldUpdateDefaultIndex: Bool = false
    var alreadyTrackMainView: Bool = false

    public var needToPushSetInformationViewController: Bool {
        return self.data.needToPushSetInformationViewController
    }

    var context: ProfileContext

    var statusReplay: ReplaySubject<ProfileStatus> = ReplaySubject<ProfileStatus>.create(bufferSize: 1)
    public var status: Observable<ProfileStatus> {
        return statusReplay.asObserver()
    }

    private var relationshipReplay = ReplaySubject<ProfileRelationship>.create(bufferSize: 1)
    public var relationship: Observable<ProfileRelationship> {
        return relationshipReplay.asObserver()
    }

    private var communicationPermissionReplay = ReplaySubject<ProfileCommunicationPermission>.create(bufferSize: 1)
    public var communicationPermission: Observable<ProfileCommunicationPermission> {
        return communicationPermissionReplay.asObserver()
    }

    public weak var dependency: LarkProfileDataProviderDependency?
    public weak var factory: ProfileFactory?
    public weak var profileVC: ProfileViewController?

    @ScopedInjectedLazy var myAIAPI: MyAIAPI?
    @ScopedInjectedLazy var myAIService: MyAIService?
    @ScopedInjectedLazy var profileAPI: LarkProfileAPI?
    @ScopedInjectedLazy var serverNTPTimeService: ServerNTPTimeService?
    @ScopedInjectedLazy var appConfiguration: AppConfiguration?
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var chatApplicationAPI: ChatApplicationAPI?
    @ScopedInjectedLazy var userAppConfig: UserAppConfig?
    @ScopedInjectedLazy var monitor: SetContactInfomationMonitorService?
    @ScopedInjectedLazy var inlineService: TextToInlineService?
    @ScopedInjectedLazy var imageAPI: ImageAPI?
    private var accountService: PassportUserService? {
        try? userResolver.resolve(assert: PassportUserService.self)
    }

    var data: LarkProfileData

    var tracker: LarkProfileTracker?
    
    var isSelf: Bool = false

    var currentChatterId: String {
        return accountService?.user.userID ?? ""
    }

    var secretChatEnable: Bool {
        // 该租户开通了密聊功能
        guard self.userAppConfig?.appConfig?.billingPackage.hasSecretChat_p ?? false else { return false }
        // 未被精简模式关闭密聊功能
        guard AppConfigManager.shared.feature(for: "secretChat").isOn else { return false }

        // 是否使用新的密聊判断规则
        if userResolver.fg.staticFeatureGatingValue(with: "lark.client.secretchat_priviledge_control.migrate") {
            // 判断appConfig下发的可用性
            return self.userAppConfig?.appConfig?.cryptoChatState ?? .unknown == .allow
        } else {
            // 判断老FG
            return userResolver.fg.staticFeatureGatingValue(with: "secretchat.main")
        }
    }

    /// 是不是海外用户
    var isOversea: Bool {
        return !(accountService?.isFeishuBrand ?? false)
    }

    var isSameTenant: Bool {
        return (self.userProfile?.userInfoProtocol.tenantID ?? "") == accountService?.userTenant.tenantID
    }

    var isMe: Bool {
        return (self.userProfile?.userInfoProtocol.userID ?? "") == accountService?.user.userID
    }

    var blockStatus: LarkUserProfile.UserInfo.BlockStatus {
        return userProfile?.userInfoProtocol.blockStatus ?? .bUnknown
    }

    public var isBlocked: Bool {
        return self.blockStatus == .bForward || self.blockStatus == .bDouble || self.userProfile?.userInfoProtocol.isBlocked ?? false
    }

    var isShowBlockMenu: Bool {
         return self.userProfile?.userInfoProtocol.canBlock ?? false
    }

    var userProfile: ProfileInfoProtocol?

    var descriptionText: String?
    var isRemote = false

    var tabItems: SafeArray<ProfileTabItem> = [] + .readWriteLock

    var topImageView: UIImageView?

    var medalView: MedalStackView?

    var avatarView: LarkMedalAvatar?

    var topImageKey: String = ""

    var enabelMedal: Bool {
        return self.userProfile?.userInfoProtocol.avatarMedal.showSwitch ?? false
    }

    let disposeBag = DisposeBag()
    let tabsLock = NSLock()
    let descLock = NSLock()

    // 签名变更时，需要重新记录inline渲染开始时间
    var inlineTrackTime: (sourceText: String, startTime: CFTimeInterval, tracked: Bool, isFromPush: Bool) = ("", 0, false, false)

    public init(data: LarkProfileData, resolver: UserResolver, factory: ProfileFactory? = nil) {
        self.data = data
        self.userResolver = resolver
        if let profileFactory = factory {
            self.factory = profileFactory
        }
        self.context = ProfileContext(data: data)
        getUserInformation()
        monitor?.registerObserver(self, method: #selector(onBlockStatusChange(not:)), serverType: .blockStatusChangeService)

        ProfileFieldFactory.register(type: ProfileFieldPhoneCell.self)

        // 星标联系人状态更新时，reload一次
        chatterAPI?.pushFocusChatter
            .subscribe(onNext: { [weak self] msg in
                guard let self = self, let userProfile = self.userProfile else { return }
                let changedChatterIds = msg.deleteChatterIds + msg.addChatters.map { $0.id }
                guard changedChatterIds.contains(userProfile.userInfoProtocol.userID) else { return }
                self.reloadData()
            }).disposed(by: disposeBag)

        inlineService?.subscribePush(sourceIDHandler: { [weak self] sourceIDs in
            guard let self = self, let userInfo = self.userProfile?.userInfoProtocol else { return }
            if sourceIDs.contains(userInfo.userID) {
                self.inlineTrackTime.isFromPush = true
                self.fetchUserProfileInformation(whenDescriptionUpdate: true)
            }
        })
    }

    public func getAvtarView() -> UIView? {
        guard let userInfo = self.userProfile?.userInfoProtocol else {
            return nil
        }
        guard let bizView = generateAvatarView() as? LarkMedalAvatar else {
            return nil
        }
        let timeStamp = CACurrentMediaTime()
        bizView.setAvatarByIdentifier(userInfo.userID,
                                      avatarKey: userInfo.avatarKey,
                                      medalKey: userInfo.avatarMedal.showSwitch ? userInfo.avatarMedal.key : "",
                                      medalFsUnit: "",
                                      scene: .Profile,
                                      placeholder: isAIProfile ? aiDefaultAvatar : nil,
                                      avatarViewParams: .init(sizeType: .size(Cons.avatarViewSize)),
                                      backgroundColorWhenError: UIColor.ud.bgBodyOverlay) { _ in
            let userProfileTrackKey = ProfileReciableTrack.getUserProfileKey()
            let networkCost = CACurrentMediaTime() - timeStamp
            ProfileReciableTrack.updateUserProfileAvatarCost(networkCost)
            ProfileReciableTrack.trackUserProfileEndCostOnAvatar(key: userProfileTrackKey)
        }
        return bizView
    }
    
    public func generateAvatarView() -> UIView {
        let bizView = LarkMedalAvatar()
        if isAIProfile {
            bizView.border.isHidden = true
            bizView.backgroundColor = .clear
            bizView.avatar.backgroundColor = .clear
            bizView.avatar.ud.removeMaskView()
            // AI 头像为透明，并在底部添加一个不规则底图
            /// 深色模式下头像背后的渐变阴影
            let gradientBackground: FKGradientView = {
                let view = FKGradientView()
                view.direction = .topToBottom
                view.colors = [
                    // swiftlint:disable init_color_with_token
                    UIColor(red: 183 / 255, green: 128 / 255, blue: 224 / 255, alpha: 1.0) & UIColor(red: 181 / 255, green: 124 / 255, blue: 217 / 255, alpha: 1.0),
                    UIColor(red: 225 / 255, green: 214 / 255, blue: 249 / 255, alpha: 1.0) & UIColor(red: 113 / 255, green: 87 / 255, blue: 168 / 255, alpha: 1.0),
                    UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1.0) & UIColor(red: 41 / 255, green: 41 / 255, blue: 41 / 255, alpha: 1.0)
                    // swiftlint:enable init_color_with_token
                ]
                view.locations = [0, 0.35, 0.7]
                view.layer.masksToBounds = true
                view.layer.cornerRadius = Cons.avatarViewBorderSize * 0.8 / 2
                return view
            }()
            bizView.insertSubview(gradientBackground, at: 0)
            gradientBackground.snp.makeConstraints { make in
                make.center.equalTo(bizView.avatar)
                make.width.height.equalTo(bizView.avatar).multipliedBy(0.9)
            }
        } else {
            bizView.border.backgroundColor = UIColor.ud.primaryOnPrimaryFill
            bizView.border.isHidden = false
            // disable-lint: magic number
            bizView.border.layer.cornerRadius = Cons.avatarViewBorderSize / 2
            // enable-lint: magic number
        }
        bizView.updateBorderSize(CGSize(width: Cons.avatarViewBorderSize, height: Cons.avatarViewBorderSize))
        bizView.border.layer.cornerRadius = Cons.avatarViewBorderSize / 2
        bizView.layer.shadowOpacity = 1
        bizView.layer.shadowRadius = 8
        bizView.layer.shadowOffset = CGSize(width: 0, height: 4)
        bizView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        bizView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarViewTapped))
        bizView.addGestureRecognizer(tapGesture)
        self.avatarView = bizView
        return bizView
    }
    
    public func updateAvatar() {
        guard let userInfo = self.userProfile?.userInfoProtocol else {
            return
        }
        let timeStamp = CACurrentMediaTime()
        avatarView?.setAvatarByIdentifier(userInfo.userID,
                                          avatarKey: userInfo.avatarKey,
                                          medalKey: userInfo.avatarMedal.showSwitch ? userInfo.avatarMedal.key : "",
                                          medalFsUnit: "",
                                          scene: .Profile,
                                          avatarViewParams: .init(sizeType: .size(Cons.avatarViewSize)),
                                          backgroundColorWhenError: UIColor.ud.bgBodyOverlay) { _ in
            let userProfileTrackKey = ProfileReciableTrack.getUserProfileKey()
            let networkCost = CACurrentMediaTime() - timeStamp
            ProfileReciableTrack.updateUserProfileAvatarCost(networkCost)
            ProfileReciableTrack.trackUserProfileEndCostOnAvatar(key: userProfileTrackKey)
        }
    }

    public func getNavigationBarAvatarView() -> UIView? {
        guard let userInfo = self.userProfile?.userInfoProtocol else {
            return nil
        }

        let avatar = UIImageView()
        avatar.bt.setLarkImage(with: .avatar(key: userInfo.avatarKey,
                                             entityID: userInfo.userID),
                               trackStart: {
                                TrackInfo(scene: .Profile, fromType: .avatar)
                               })

        avatar.ud.setMaskView()
        barAvatarView = avatar
        return avatar
    }
    public var barAvatarView: UIImageView = UIImageView()
    public func updateNavigationBarAvatarView() {
        guard let userInfo = self.userProfile?.userInfoProtocol else {
            return
        }
        barAvatarView.bt.setLarkImage(with: .avatar(key: userInfo.avatarKey,
                                                    entityID: userInfo.userID),
                               trackStart: {
                                TrackInfo(scene: .Profile, fromType: .avatar)
                               })
    }

    public func getBackgroundView() -> UIImageView? {
        guard let userInfo = self.userProfile?.userInfoProtocol else {
            return nil
        }

        var passThrough = ImagePassThrough()
        let key = getProfileKey(self.topImageKey, sizeType: .middle)
        passThrough.key = key
        passThrough.fsUnit = userInfo.topImage.fsUnit
        passThrough.fileType = .profileTopImage

        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill

        imageView.bt.setLarkImage(with: .default(key: key),
                                  placeholder: BundleResources.LarkProfile.default_bg_image,
                                  passThrough: passThrough,
                                  trackStart: {
                                    return TrackInfo(scene: .Profile, fromType: .avatar)
                                  })
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundViewTapped))
        imageView.addGestureRecognizer(tapGesture)
        imageView.ud.setMaskView()

        if userInfo.avatarMedal.showSwitch {

            let medalView = MedalStackView()
            medalView.moreImageView.image = BundleResources.LarkProfile.more.ud.withTintColor(UIColor.ud.iconN2)
            medalView.pushView.image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
            self.medalView = medalView

            updateMedal()

            medalView.tapCallback = { [weak self] in
                self?.medalViewTapped()
            }

            imageView.addSubview(medalView)
            medalView.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-16)
                make.height.equalTo(28)
            }
        }

        self.topImageView = imageView
        return imageView
    }

    public func reloadData() {
        self.fetchUserProfileInformation()
    }

    private func updateMedal() {
        guard let userInfo = self.userProfile?.userInfoProtocol else {
            return
        }

        medalView?.isHidden = !userInfo.avatarMedal.showSwitch

        // swiftlint:disable empty_count
        if userInfo.medalList.totalNum == 0,
           userInfo.medalList.medalMeta.isEmpty,
            self.currentChatterId == userInfo.userID {
            medalView?.setTitle(BundleI18n.LarkProfile.Lark_Profile_MyBadges)
        } else {
            medalView?.setMedals(userInfo.medalList.medalMeta, count: Int(userInfo.medalList.totalNum))
        }
        // swiftlint:enable empty_count
    }

    func getUserInformation() {
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
    
    public func loadUserInfo() {}

    /// 请求 MyAI Profile 信息
    /// - Parameter forceServer: 本地缓存 or 从服务端获取
    func getAIProfileInformation(forceServer: Bool) {
        let fromType = forceServer ? "server" : "cache"
        Self.logger.info("[MyAI.Profile][Preview][\(#function)] trying to get ai profile from \(fromType)")
        myAIAPI?.getAIProfileInfomation(aiID: self.data.chatterId, forceServer: forceServer)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (data) in
                Self.logger.info("[MyAI.Profile][Preview][\(#function)] get ai profile from \(fromType) succeeded: \(data)")
                guard let `self` = self else { return }
                var aiProfileInfo = data
                // 防止 PushChatter 之后，getInfo 拿到的数据还是旧的，客户端先做一下处理
                if let myAIServiceInfo = self.myAIService?.info.value, myAIServiceInfo.name != aiProfileInfo.aiInfo.name || myAIServiceInfo.avatarKey != aiProfileInfo.aiInfo.avatarKey {
                    Self.logger.error("[MyAI.Profile][Preview][\(#function)] get ai profile returns legacy data, different with myAIInfo")
                }
                self.updateUserProfile(data, isLocal: !forceServer)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                Self.logger.info("[MyAI.Profile][Preview][\(#function)] get ai profile from \(fromType) failed: \(error)")
            }).disposed(by: disposeBag)
    }

    /// 根据 MyAIService 中保存的 Info 信息更新 AI Profile
    func updateAIProfileInformation() {
        guard let myAIServiceInfo = self.myAIService?.info.value else {
            return
        }
        // 根据 MyAIService 中提供的 info 更新 Profile
        if var profileData = userProfile {
            var hasProfileChange = false
            if profileData.userInfoProtocol.userName != myAIServiceInfo.name {
                profileData.userInfoProtocol.userName = myAIServiceInfo.name
                profileData.userInfoProtocol.profileUserName = myAIServiceInfo.name
                profileData.userInfoProtocol.nameWithAnotherName = myAIServiceInfo.name
                hasProfileChange = true
            }
            if profileData.userInfoProtocol.avatarKey != myAIServiceInfo.avatarKey {
                profileData.userInfoProtocol.avatarKey = myAIServiceInfo.avatarKey
                hasProfileChange = true
            }
            if hasProfileChange {
                Self.logger.warn("[MyAI.Profile][Preview][\(#function)] AI profile info change, updating with: \(myAIServiceInfo)")
                updateUserProfile(profileData, isLocal: false)
                profileVC?.loadContent()
            } else {
                Self.logger.warn("[MyAI.Profile][Preview][\(#function)] AI profile info not change")
            }
        }
    }

    func getUserProfileInformation() {
        let timeStamp = CACurrentMediaTime()
        /// 本地同步获取一次
        guard let profileAPI = self.profileAPI,
              let userId = self.data.chatterId else { return }
        profileAPI
            .getUserProfileInfomation(userId: userId,
                                      contactToken: self.data.contactToken,
                                      chatId: self.data.chatId,
                                      sourceType: self.data.source)
            .subscribe(onNext: { [weak self] (localData) in
                guard let `self` = self,
                      !self.isRemote else { return }
                Self.logger.info("fetchUserProfile local tabOrders: \(localData.tabOrders.count) fieldOrders: \(localData.fieldOrders.count) ctaOrders: \(localData.ctaOrders.count)")
                /// 计算本地请求时间
                let localCost = CACurrentMediaTime() - timeStamp
                ProfileReciableTrack.updateUserProfileSDKLocalCost(localCost)
                self.updateUserProfile(localData, isLocal: true)
            }).disposed(by: disposeBag)
    }

    func trackProfileMainViewWithoutInfo() {
        var params: [AnyHashable: Any] = [:]
        params["gender_tag"] = "none"
        params["is_user_on_leave_tag_shown"] = "false"
        params["is_user_no_disturb_tag_shown"] = "false"
        params["account_status_tag"] = "none"
        params["is_custom_image_field_shown"] = "false"
        params["is_alias_filled"] = "false"
        params["is_moments_tab_shown"] = "false"
        params["friend_conversion"] = "none"
        params["contact_type"] = ""
        params["verification"] = "false"
        params["contain_module"] = ""
        params["to_user_id"] = ""
        params["is_verified"] = false
        params["signature_length"] = 0
        params["is_privacy_set"] = "false"
        params["is_avatar_medal_shown"] = "false"
        params["is_medal_wall_entry_shown"] = "false"
        params["tab"] = ""
        Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_VIEW, params: params, md5AllowList: ["to_user_id"]))
    }

    /// 远程拉取profile信息
    /// - Parameter whenDescriptionUpdate: 因为签名更新push而刷新
    func fetchUserProfileInformation(whenDescriptionUpdate: Bool = false) {
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
                Self.logger.info("fetchUserProfile remote tabOrders: \(remoteData.tabOrders.count) fieldOrders: \(remoteData.fieldOrders.count) ctaOrders: \(remoteData.ctaOrders.count)")
                /// 计算网络请求时间
                let networkCost = CACurrentMediaTime() - timeStamp
                ProfileReciableTrack.updateUserProfileSDKNetworkCost(networkCost)
                self.updateUserProfile(remoteData, isLocal: false)
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
                Self.logger.info("fetch userProfile infomation failure: \(error)")
                self.trackProfileMainViewWithoutInfo()
                self.alreadyTrackMainView = true
                if self.userProfile == nil {
                    self.statusReplay.onNext(.error)
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

    func updateUserProfile(_ userProfile: ProfileInfoProtocol, isLocal: Bool) {
        self.userProfile = userProfile
        self.isSelf = currentChatterId == userProfile.userInfoProtocol.userID
        // 默认选中的tab页数
        self._shouldUpdateDefaultIndex = true

        self.updateTabItems()

        if userProfile.userInfoProtocol.isRegistered {
            relationshipReplay.onNext(userProfile.userInfoProtocol.friendStatus.getApplyStatus())
        } else {
            relationshipReplay.onNext(.none)
        }
        let selfApplyStatus = userProfile.userInfoProtocol.hasApplyCommunication ? userProfile.userInfoProtocol.applyCommunication.selfApplyStatus.getApplyCommunicationStatus() : .unown
        communicationPermissionReplay.onNext(selfApplyStatus)

        self.topImageKey = userProfile.userInfoProtocol.topImage.key
        if userProfile.canNotFind {
            self.statusReplay.onNext(.noPermission)
        } else if userProfile.fieldOrders.isEmpty {
            // MyAI 特化逻辑：PM 觉得 AI Profile 显示“暂无个人信息”像 bug，所以 AI Profile 不展示空占位图
            self.statusReplay.onNext(isAIProfile ? .normal : .empty)
        } else {
            self.statusReplay.onNext(.normal)
        }
        let oppositeApplyStatus = userProfile.userInfoProtocol.hasApplyCommunication ? userProfile.userInfoProtocol.applyCommunication.oppositeApplyStatus.getApplyCommunicationStatus() : .unown
        Self.logger.info("get \(userProfile.userInfoProtocol.userID.md5()) profile info from isLocal \(isLocal) isSpecialFocus: \(userProfile.userInfoProtocol.isSpecialFocus) topImageKey: \(userProfile.userInfoProtocol.topImage.key) hasApplyCommunication: \(userProfile.userInfoProtocol.hasApplyCommunication) selfApplyStatus: \(selfApplyStatus) oppositeApplyStatus: \(oppositeApplyStatus) hideAddConnectButton: \(userProfile.userInfoProtocol.hideAddConnectButton) friendStatus: \(userProfile.userInfoProtocol.friendStatus)")
        // 发送UserInfo更新通知, 设置页更新添加按钮
        let name = Notification.Name(LKProfileUserInfoUpdateNotification)
        let isHideAddContactButtonOnProfile = isHideAddContactButtonOnProfile(userInfo: userProfile)
        Self.logger.info("hideAddConnectButton notification: \(isHideAddContactButtonOnProfile)")
        NotificationCenter.default.post(name: name, object: nil, userInfo: [
            LKProfileHideAddOnProfileKey: isHideAddContactButtonOnProfile,
            LKProfileIsDoubleFriend: userProfile.userInfoProtocol.friendStatus == .double
        ])
    }

    public func medalViewTapped() {
        self.tracker?.trackMainClick("medal_wall_entry", extra: ["target": "profile_avatar_medal_wall_view",
                                                                 "vaild_medal_count": Int(userProfile?.userInfoProtocol.medalList.totalNum ?? 0)])
        guard let fromVC = self.profileVC else { return }
        let userID: String = self.userProfile?.userInfoProtocol.userID ?? ""
        let vm = MedalViewModel(resolver: userResolver, userID: userID)
        userResolver.navigator.push(MedalViewController(resolver: self.userResolver, viewModel: vm), from: fromVC)
    }

    @objc
    func avatarViewTapped() {
        guard let fromVC = self.profileVC else { return }
        if enabelMedal, !(self.avatarView?.medalKey.isEmpty ?? true) {
            let userID: String = self.userProfile?.userInfoProtocol.userID ?? ""
            let actionSheet = UDActionSheet(config: UDActionSheetUIConfig())
            actionSheet.addDefaultItem(text: BundleI18n.LarkProfile.Lark_Profile_ViewProfilePhoto_Option) { [weak self] in
                self?.presentPreviewAvatar()
                self?.tracker?.trackerAvatarActionSheetClick("check_avatar", target: "im_avatar_main_view")
            }
            actionSheet.addDefaultItem(text: BundleI18n.LarkProfile.Lark_Profile_ViewBadgeDetails_Option) { [weak self] in
                guard let self = self else { return }
                let medalVC = MedalDetailViewController(resolver: self.userResolver, userID: userID, medal: nil)
                self.userResolver.navigator.push(medalVC, from: fromVC)
                self.tracker?.trackerAvatarActionSheetClick("medal_detail", target: "profile_avatar_medal_detail_view")
            }
            actionSheet.setCancelItem(text: BundleI18n.LarkProfile.Lark_Profile_ProfilePhotoMenuCancel_Button) { [weak self] in
                self?.tracker?.trackerAvatarActionSheetClick("cancel", target: "profile_main_view")
            }
            self.userResolver.navigator.present(actionSheet, from: fromVC)
            self.tracker?.trackerAvatarActionSheetToUserId()
            self.tracker?.trackMainClick("avatar", extra: ["target": "profile_avatar_action_sheet_view"])
        } else {
            presentPreviewAvatar()
        }
    }

    private func presentPreviewAvatar() {
        guard let userInfo = self.userProfile?.userInfoProtocol,
              let fromVC = self.profileVC else { return }
        var avatarKey = userInfo.avatarKey
        if let lastAvatarKey = self.avatarView?.avatar.lastAvatarKey,
            !lastAvatarKey.isEmpty,
            avatarKey != lastAvatarKey {
            avatarKey = lastAvatarKey
        }
        let body = PreviewAvatarBody(avatarKey: avatarKey,
                                     entityId: userInfo.userID,
                                     supportReset: !userInfo.isDefaultAvatar && isMe,
                                     scene: userInfo.userID == self.currentChatterId ? .personalizedAvatar : .simple)
        userResolver.navigator.present(body: body, from: fromVC)

        self.tracker?.trackMainClick("avatar", extra: ["target": "im_avatar_main_view"])
    }

    @objc
    public func backgroundViewTapped() {
        guard let userInfo = self.userProfile?.userInfoProtocol,
              let fromVC = self.profileVC else { return }

        var imageSet = ImageSet()
        imageSet.key = self.topImageKey
        imageSet.origin.key = self.topImageKey
        var asset = Asset(sourceType: .image(imageSet))

        /// 这个key是用户用来保存图片的key 使用原图的
        asset.key = self.topImageKey
        asset.originKey = self.topImageKey
        asset.forceLoadOrigin = true
        asset.isAutoLoadOrigin = true
        asset.fsUnit = userInfo.topImage.fsUnit
        asset.placeHolder = self.topImageView?.image ?? BundleResources.LarkProfile.default_bg_image

        if userInfo.userID == currentChatterId {
            let config = CropperConfigure(squareScale: false, style: .custom(Cons.cropperStyleCustomRatio), supportRotate: false)
            let body = SettingSingeImageBody(asset: asset,
                                             modifyAvatarString: BundleI18n.LarkProfile.Lark_Community_ChangeCover,
                                             type: .background,
                                             editConfig: config) { [weak self] in
                self?.tracker?.trackBackgroundMainClick()
                self?.tracker?.trackBackgroundChangeView()
            } actionCallback: { [weak self] isPhoto in

                if let isPhoto = isPhoto {
                    if isPhoto {
                        self?.tracker?.trackBackgroundChangeClick("from_album", target: "im_chat_album_list_view")
                    } else {
                        self?.tracker?.trackBackgroundChangeClick("shot", target: "public_photograph_view")
                    }
                } else {
                    self?.tracker?.trackBackgroundChangeClick("cancel", target: "profile_background_main_view")
                }
            } updateCallback: { [weak self] info -> Observable<[String]> in
                guard let self = self, let data = info.0 else { return .just([]) }
                return self.uploadTopImage(data)
                    .observeOn(MainScheduler.instance)
                    .flatMap { [weak self] key -> Observable<[String]> in
                    Self.logger.info("upload profile topImage success")
                    guard let userInfo = self?.userProfile?.userInfoProtocol else {
                        Self.logger.info("upload profile topImage success, but userInfo isEmpty")
                        return .just([key])
                    }

                    var passThrough = ImagePassThrough()
                    let middleKey = self?.getProfileKey(key, sizeType: .middle) ?? key
                    passThrough.key = middleKey
                    passThrough.fsUnit = userInfo.topImage.fsUnit
                    passThrough.fileType = .profileTopImage

                    self?.topImageKey = key

                    self?.topImageView?.bt.setLarkImage(with: .default(key: middleKey),
                                                        placeholder: self?.topImageView?.image,
                                                        passThrough: passThrough)
                    return .just([key])
                }
            }
            self.userResolver.navigator.present(body: body, from: fromVC)
        } else {
            let body = PreviewImagesBody(assets: [asset],
                                         pageIndex: 0,
                                         scene: .normal(assetPositionMap: [:], chatId: nil),
                                         shouldDetectFile: false,
                                         canSaveImage: false,
                                         canShareImage: false,
                                         canEditImage: false,
                                         hideSavePhotoBut: true,
                                         canTranslate: false,
                                         translateEntityContext: (nil, .other))
            self.userResolver.navigator.present(body: body, from: fromVC)
        }

        self.tracker?.trackBackgroundMainView()

        self.tracker?.trackMainClick("background", extra: ["target": "profile_background_main_view"])
    }

    public func replaceDescriptionWithInlineTrySDK(by text: String, completion: @escaping TextToInlineService.Completion) {
        guard let userInfo = userProfile?.userInfoProtocol else {
            return
        }
        let isMe = self.currentChatterId == userInfo.userID
        let textColor = text.isEmpty && isMe ? ProfileStatusView.Cons.emptyTextColor : ProfileStatusView.Cons.textColor
        if !text.isEmpty {
            inlineService?.replaceWithInlineTrySDK(sourceID: userInfo.userID,
                                                  sourceText: text,
                                                  type: .personalSig,
                                                  strategy: .forceServer,
                                                  textColor: textColor,
                                                  linkColor: ProfileStatusView.Cons.linkColor,
                                                   font: ProfileStatusView.Cons.textFont,
                                                   completion: { [weak self] (attriubuteText, urlRangeMap, textUrlRangeMap, sourceType) in
                guard let self = self else { return }
                self.descLock.lock()
                let copyAttr = NSMutableAttributedString(attributedString: attriubuteText)
                mainOrAsync { completion (copyAttr, urlRangeMap, textUrlRangeMap, sourceType) }
                self.descLock.unlock()
            })
        } else {
            let attr = NSMutableAttributedString(string: "\(BundleI18n.LarkProfile.Lark_Profile_EnterYourSignature)", attributes: [.foregroundColor: textColor, .font: ProfileStatusView.Cons.textFont])
            completion(attr, [:], [:], InlineSourceType.memory)
        }
    }

    @objc
    private func onBlockStatusChange(not: Notification) {
        if let userID = self.monitor?.getUserIdFromNotObjet(not.object),
           let currentUserID = self.userProfile?.userInfoProtocol.userID,
           userID == currentUserID {
            self.reloadData()
        }
    }

    private func uploadTopImage(_ data: Data) -> Observable<String> {
        return imageAPI?
            .uploadImageV2(data: data,
                           imageType: .profileTopImage)
            .flatMap { [weak self] key -> Observable<String> in
                guard let `self` = self, let profileAPI = self.profileAPI else { return .just(key) }
                return profileAPI.updateTopImage(key: key).map {
                    return key
                }
            } ?? .just("")
    }

    private func getProfileKey(_ key: String, sizeType: ProfileImageSizeType? = nil) -> String {
        if let type = sizeType {
            return key + "_" + type.rawValue.uppercased()
        }
        return key
    }
    
    func generateUserDescription(userInfo: UserInfoProtocol) -> ProfileStatusView? {
        var descriptionView: ProfileStatusView?
        let isMe = self.currentChatterId == userInfo.userID
        var descriptionContent = userInfo.description_p.text
        if let descriptionText = self.descriptionText,
            descriptionContent != descriptionText {
            Self.logger.info("generate user description use local data")
            descriptionContent = descriptionText
        } else {
            Self.logger.info("generate user description use service data")
        }

        let textColor = descriptionContent.isEmpty && isMe ? ProfileStatusView.Cons.emptyTextColor : ProfileStatusView.Cons.textColor
        if !descriptionContent.isEmpty || isMe {
            descriptionView = ProfileStatusView()
            var text = descriptionContent
            var pushCallback: (() -> Void)?
            let length = self.getLength(forText: text)
            if isMe {
                if descriptionContent.isEmpty {
                    text = BundleI18n.LarkProfile.Lark_Profile_EnterYourSignature
                }
                pushCallback = { [weak self] in
                    guard let fromVC = self?.profileVC else {
                        return
                    }
                    self?.userResolver.navigator.present(body: WorkDescriptionSetBody(completion: { [weak self] text in
                        guard let `self` = self else { return }
                        Self.logger.info("edit user sign description")
                        self.descriptionText = text
                        self.reloadData()
                    }), wrap: LkNavigationController.self, from: fromVC)
                    self?.tracker?.trackMainClick("signature", extra: ["target": "profile_signature_setting_view",
                                                                       "signature_length": length])
                }
            }
            setStartTime(sourceText: descriptionContent)
            if !descriptionContent.isEmpty {
                inlineService?.replaceWithInlineTrySDK(sourceID: userInfo.userID,
                                                      sourceText: descriptionContent,
                                                      type: .personalSig,
                                                      strategy: .forceServer,
                                                      textColor: textColor,
                                                      linkColor: ProfileStatusView.Cons.linkColor,
                                                      font: ProfileStatusView.Cons.textFont) { [weak self, weak descriptionView] attr, urlRange, textRange, sourceType in
                    guard let self = self else { return }
                    mainOrAsync {
                        descriptionView?.setStatus(originText: descriptionContent,
                                                   attributedText: attr,
                                                   urlRangeMap: urlRange,
                                                   textUrlRangeMap: textRange,
                                                   pushCallback: pushCallback)
                        self.trackInlineRender(sourceID: userInfo.userID, sourceText: descriptionContent, sourceType: sourceType)
                    }
                }
            } else {
                let attr = NSMutableAttributedString(string: text, attributes: [.foregroundColor: textColor, .font: ProfileStatusView.Cons.textFont])
                descriptionView?.setStatus(originText: descriptionContent, attributedText: attr, pushCallback: pushCallback)
            }
            descriptionView?.delegate = self
        }
        return descriptionView
    }

    func generateCompanyView() -> UIView? {
        guard let userInfo = userProfile?.userInfoProtocol else {
            return nil
        }
        Self.logger.info("generate companyView isUnifiedComponentFG: \(isUnifiedComponentFG)")
        if isUnifiedComponentFG {
            guard let tenantNameService = try? userResolver.resolve(assert: LarkTenantNameService.self) else {
                return nil
            }
            let tenantNameUIConfig = LarkTenantNameUIConfig(
                tenantNameFont: UIFont.systemFont(ofSize: 12),
                tenantNameColor: UIColor.ud.textTitle,
                isSupportAuthClick: true)
            let company = tenantNameService.generateTenantNameView(with: tenantNameUIConfig)
            let isFriend = fetchCurrentHasFriend(userInfo: userInfo)
            let isAllowPush = isAllowOpenTenantCertificationPage(isFriend: isFriend, userInfo: userInfo)
            let (tenantName, _) = company.config(tenantInfo: LarkTenantInfo(tenantName: userInfo.tenantName.getString(),
                                                                            isFriend: isFriend,
                                                                            tenantNameStatus: userInfo.tenantNameStatus,
                                                                            certificationInfo: userInfo.certificationInfo,
                                                                            tapCallback: { [weak self] in
                guard let self = self,
                        isAllowPush else {
                    return
                }
                self.pushTenantCertificationPage()
            }))
            guard !tenantName.isEmpty else { return nil }
            return company
        } else {
            let company = CompanyAuthView()
            let (tenantName, hasTenantCertification) = fetchSecurityTenantName(userInfo: userInfo)
            if tenantName.isEmpty { return nil }
            let isTenantCertification = (userInfo.certificationInfo.certificateStatus == .certificated)
            let isFriend = fetchCurrentHasFriend(userInfo: userInfo)
            let isAllowPush = isAllowOpenTenantCertificationPage(isFriend: isFriend, userInfo: userInfo)
            company.configUI(tenantName: tenantName,
                              hasAuth: hasTenantCertification,
                              isAuth: isTenantCertification) { [weak self] in
                guard let self = self,
                        isAllowPush else {
                    return
                }
                self.pushTenantCertificationPage()
            }
            return company
        }
    }

    private func pushTenantCertificationPage() {
        Self.logger.info("start push tenantCertification page")
        guard let fromVC = self.profileVC,
              let userInfo = userProfile?.userInfoProtocol,
              let url = try? URL.forceCreateURL(string: userInfo.certificationInfo.tenantCertificationURL) else { return }
        self.userResolver.navigator.open(url, from: fromVC)
        Self.logger.info("end push tenantCertification page")
        let isVerified = userInfo.hasTenantCertification_p && userInfo.isTenantCertification ? "true" : "false"
        self.tracker?.trackMainClick("certification", extra: ["target": "admin_feishu_certificate_h5_detail_view",
                                                               "is_verified": isVerified])
    }

    func isAllowOpenTenantCertificationPage(isFriend: Bool,
                                            userInfo: UserInfoProtocol) -> Bool {
        switch userInfo.tenantNameStatus {
        case .visible:
            return true
        case .notFriend:
            return isFriend ? true : false
        case .hide:
            return false
        case .unknown:
            break
        @unknown default:
            break
        }
        return true
    }

    private func fetchCurrentHasFriend(userInfo: UserInfoProtocol) -> Bool {
        var isFriend = false
        var relationship: ProfileRelationship = .none
        if userInfo.isRegistered {
            relationship = userInfo.friendStatus.getApplyStatus()
        }

        switch relationship {
        case .none, .accepted:
            //已成为好友
            isFriend = true
        case .accept, .apply, .applying:
            // 非好友关系
            break
        }
        return isFriend
    }

    private func fetchSecurityTenantName(userInfo: UserInfoProtocol) -> (String, Bool) {
        let isFriend = fetchCurrentHasFriend(userInfo: userInfo)
        Self.logger.info("fetch security tenantName isFriend: \(isFriend) tenantNameStatus: \(userInfo.tenantNameStatus)")
        let tenantName = userInfo.tenantName.getString()
        let status = userInfo.certificationInfo.certificateStatus
        let hasTenantCertification = tenantName.isEmpty ? false : (userInfo.certificationInfo.isShowCertSign && status != .teamCertificated)
        switch userInfo.tenantNameStatus {
        case .visible:
            return (tenantName, hasTenantCertification)
        case .notFriend:
            return isFriend ? (tenantName, hasTenantCertification) : (BundleI18n.LarkProfile.Lark_IM_Profile_AddAsExternalContactToViewOrgInfo_Placeholder, false)
        case .hide:
            return (BundleI18n.LarkProfile.Lark_IM_Profile_UserHideOrgInfo_Placeholder, false)
        case .unknown:
            break
        @unknown default:
            break
        }
        return (tenantName, hasTenantCertification)
    }

    func generateTagViews() -> [UIView] {
        guard let userInfo = userProfile?.userInfoProtocol else { return [] }
        var tagViews: [UIView] = []
        if userInfo.isResigned {
            let tagConfig = UDTagConfig.TextConfig(textColor: UIColor.ud.textCaption,
                                                   backgroundColor: UIColor.ud.N300)
            let tagView = UDTag(text: BundleI18n.LarkProfile.Lark_Status_DeactivatedTag, textConfig: tagConfig)
            tagViews.append(tagView)
        } else {
            if userInfo.isSpecialFocus {
                let icon = UDIcon.collectFilled
                let tagView = UDTag(icon: icon, iconConfig: .init(iconColor: UIColor.ud.colorfulYellow,
                                                                  backgroundColor: .clear,
                                                                  height: Cons.specialFocusHeight, // 外部的边长
                                                                  iconSize: CGSize(width: 20, height: 20)))
                tagViews.append(tagView)
            } else {
                Self.logger.info("profile \(userInfo.userID.md5()) not show special focus star isSpecialFocus: \(userInfo.isSpecialFocus)")
            }

            if userInfo.hasGender && userInfo.gender != .default {
                let genderIcon = userInfo.gender == .woman ? UDIcon.femaleFilled : UDIcon.maleFilled
                let bgColor = userInfo.gender == .woman ?  UIColor.ud.C400 : UIColor.ud.B400
                let tagView = UDTag(icon: genderIcon.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill),
                                    iconConfig: UDTagConfig.IconConfig(backgroundColor: bgColor))
                tagViews.append(tagView)
            }

            if self.isBlocked {
                let tagConfig = UDTagConfig.TextConfig(textColor: UIColor.ud.primaryOnPrimaryFill,
                                                       backgroundColor: UIColor.ud.functionDangerContentDefault)
                let tagView = UDTag(text: BundleI18n.LarkProfile.Lark_NewContacts_BlockedLabel, textConfig: tagConfig)
                tagViews.append(tagView)
            }

            if userInfo.isFrozen {
                let tagConfig = UDTagConfig.TextConfig(textColor: UIColor.ud.udtokenTagTextSRed,
                                                       backgroundColor: UIColor.ud.udtokenTagBgRed)
                let tagView = UDTag(text: BundleI18n.LarkProfile.Lark_Profile_AccountPausedLabel, textConfig: tagConfig)
                tagViews.append(tagView)
            } else {
                if userInfo.hasDoNotDisturbEndTime,
                   self.serverNTPTimeService?.afterThatServerTime(time: userInfo.doNotDisturbEndTime) == true {
                    let tagView = UDTag(icon: UDIcon.alertsOffFilled.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill),
                                        iconConfig: UDTagConfig.IconConfig(backgroundColor: UIColor.ud.functionDangerContentDefault))
                    tagViews.append(tagView)
                }

                if userInfo.hasWorkStatus {

                    let isSameYear = isSameYear(timeStamp1: userInfo.workStatus.startTime,
                                                timeStamp2: userInfo.workStatus.endTime)

                    let startTime = transformData(timeStamp: userInfo.workStatus.startTime, showYear: !isSameYear)
                    let endTime = transformData(timeStamp: userInfo.workStatus.endTime, showYear: !isSameYear)

                    var text = ""

                    if startTime == endTime {
                        text = String(format: BundleI18n.LarkProfile.Lark_Legacy_PersoncardWorkdayTimeOneday, startTime)
                    } else {
                        text = String(format: BundleI18n.LarkProfile.Lark_Legacy_PersoncardWorkdayTime, startTime, endTime)
                    }

                    let tagConfig = UDTagConfig.TextConfig(textColor: UIColor.ud.primaryOnPrimaryFill,
                                                           backgroundColor: UIColor.ud.functionDangerContentDefault)
                    let tagView = UDTag(text: text, textConfig: tagConfig)
                    tagViews.append(tagView)
                }
            }
        }
        return tagViews
    }
    
    public static let maxButtonCount = 4
    // swiftlint:disable function_body_length
    // nolint: long_function - 本次需求没有QA，为了避免产生问题，会在后期FG下线技术需求统一处理
    public func getCTA() -> [ProfileCTAItem] {
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
        for (index, cta) in ctaOrders.enumerated() {
            var icon = UIImage()
            var tapCallback: (() -> Void)?
            var longPressCallback: (() -> Void)?
            switch cta.ctaType {
            case .chat:
                icon = UDIcon.chatFilled
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
                icon = UDIcon.chatSecretFilled
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
                icon = UDIcon.privateSafeChatOutlined
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
                icon = UDIcon.callFilled
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
                icon = UDIcon.videoFilled
                tapCallback = { [weak self] in
                    guard let `self` = self, let _ = self.profileVC else { return }
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
        Self.logger.info("get cta datas: \(ctas.count)")
        // 若不需折叠，展示所有CTA
        var maxCounts = ctas.count > LarkProfileDataProvider.maxButtonCount ? LarkProfileDataProvider.maxButtonCount : ctas.count
        // 最多展示n个CTA，但CTA的数量m大于n时，将后m-n+1个CTA折叠在actionSheet中,
        if ctas.count > LarkProfileDataProvider.maxButtonCount {
            self.foldCTA(&ctas)
        }
        return Array(ctas[0..<maxCounts])
    }
    // swiftlint:enable function_body_length

    func foldCTA(_ ctas: inout [ProfileCTAItem]) {
        // 需要折叠时，展示前maxButtonCount个CTA
        let moreActionCtas = ctas[LarkProfileDataProvider.maxButtonCount - 1..<ctas.count]
        ctas[LarkProfileDataProvider.maxButtonCount - 1].icon = UDIcon.moreReactionOutlined
        ctas[LarkProfileDataProvider.maxButtonCount - 1].title = ""
        ctas[LarkProfileDataProvider.maxButtonCount - 1].tapCallback = { [weak self] in
            guard let `self` = self, let fromVC = self.profileVC else { return }
            let actionSheetAdapter = ActionSheetPopoverAdapter()
            let actionSheet = actionSheetAdapter.create()
            for item in moreActionCtas {
                actionSheetAdapter.addItem(title: item.title, entirelyCenter: true, action: item.tapCallback ?? {})
            }
            actionSheetAdapter.addCancelItem(title: BundleI18n.LarkProfile.Lark_Legacy_Cancel)
            guard let from = self.profileVC else {
                assertionFailure()
                return
            }
            self.userResolver.navigator.present(actionSheet, from: from)
        }
    }

    func isHideAddContactButtonOnProfile(userInfo: ProfileInfoProtocol) -> Bool {
        return userInfo.userInfoProtocol.friendStatus.getApplyStatus() == .apply &&
        userInfo.userInfoProtocol.hideAddConnectButton
    }

    public var isHideAddContactButtonOnProfile: Bool {
        if let userProfile = self.userProfile {
            return isHideAddContactButtonOnProfile(userInfo: userProfile)
        } else {
            return false
        }
    }
}

extension LarkProfileDataProvider: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        guard let fromVC = profileVC else { return }
        self.userResolver.navigator.push(url,
                              context: ["from": "self_signature"],
                              from: fromVC)
        if let userInfo = userProfile?.userInfoProtocol {
            if isAIProfile {
                // 点击 AIProfile 文档链接的埋点
                Tracker.post(TeaEvent("profile_ai_main_click", params: [
                    "shadow_id": aiShadowID,
                    "contact_type": isMyAIProfile ? "self" : "none_self",
                    "click": "signature"
                ]))
            } else {
                inlineService?.trackURLParseClick(sourceID: userInfo.userID,
                                                  sourceText: userInfo.description_p.text,
                                                  type: .personalSig,
                                                  originURL: url.absoluteString,
                                                  scene: "profile_sign")
            }
        }
    }

    public func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        guard let fromVC = profileVC else { return }
        self.userResolver.navigator.open(body: OpenTelBody(number: phoneNumber), from: fromVC)
    }

    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return false
    }

    public func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {}
    public func tapShowMore(_ label: LKLabel) {}
    public func showFirstAtRect(_ rect: CGRect) {}
}

// MARK: - Inline Render Track
extension LarkProfileDataProvider {
    private func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
            return res + min(char.utf8.count, 2)
        }
    }
    
    func setStartTime(sourceText: String) {
        // 更换签名需要重新记录开始时间
        if inlineTrackTime.sourceText != sourceText || inlineTrackTime.startTime <= 0 {
            inlineTrackTime = (sourceText, CACurrentMediaTime(), false, false)
        }
    }

    func trackInlineRender(sourceID: String, sourceText: String, sourceType: InlineSourceType) {
        let endTime = CACurrentMediaTime()
        mainOrAsync { [weak self] in
            // 需要判断sourceText，否则有异步时序问题
            guard let self = self, self.inlineTrackTime.sourceText == sourceText, !self.inlineTrackTime.tracked else { return }
            let tracked = self.inlineService?.trackURLInlineRender(
                sourceID: sourceID,
                sourceText: sourceText,
                type: .personalSig,
                sourceType: sourceType,
                scene: "profile_sign",
                startTime: self.inlineTrackTime.startTime,
                endTime: endTime,
                isFromPush: self.inlineTrackTime.isFromPush
            ) ?? false
            if tracked {
                self.inlineTrackTime.tracked = true
                self.inlineTrackTime.isFromPush = false
            }
        }
    }

    private func isSameYear(timeStamp1: Int64, timeStamp2: Int64) -> Bool {

        let timeInterval1: TimeInterval = TimeInterval(timeStamp1)
        let date1 = Date(timeIntervalSince1970: timeInterval1)

        let timeInterval2: TimeInterval = TimeInterval(timeStamp2)
        let date2 = Date(timeIntervalSince1970: timeInterval2)

        let comp1 = Calendar.current.dateComponents([.year], from: date1)
        let comp2 = Calendar.current.dateComponents([.year], from: date2)

        return comp1.year == comp2.year
    }

    private func transformData(timeStamp: Int64, showYear: Bool) -> String {
        let timeMatter = DateFormatter()
        if showYear {
            timeMatter.dateFormat = "yyyy/MM/dd"
        } else {
            timeMatter.dateFormat = "MM/dd"
        }

        let timeInterval: TimeInterval = TimeInterval(timeStamp)
        let date = Date(timeIntervalSince1970: timeInterval)

        return timeMatter.string(from: date)
    }
}

extension LarkProfileDataProvider {
    enum Cons {
        static var specialFocusHeight: Int = 20
        static var cropperStyleCustomRatio: CGFloat = 375 / 160
        static var avatarViewSize: CGFloat = 108
        static var avatarViewBorderSize: CGFloat = 113
    }
}
