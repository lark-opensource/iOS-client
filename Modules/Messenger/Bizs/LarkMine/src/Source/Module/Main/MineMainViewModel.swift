//
//  MineMainViewModel.swift
//  Lark
//
//  Created by 姚启灏 on 2018/6/25.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkFoundation
import LKCommonsLogging
import LarkCustomerService
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkGuide
import SuiteAppConfig
import LarkReleaseConfig
import LarkUIKit
import RustPB
import LarkStorage
import TangramService
import LarkLocalizations
import LarkVersion
import LarkContactComponent
import LarkCore
import LarkContainer
import LarkSetting

final class MineMainViewModel {
    static let logger = Logger.log(MineMainViewModel.self, category: "Module.Mine")

    private lazy var userStore = KVStores.Mine.build(forUser: passportUserService.user.userID)
    // shortshut to `self.userStore`
    private static let userStore = \MineMainViewModel.userStore

    let walletEnable: Bool

    let favoriteEnable: Bool

    let authAPI: AuthAPI

    let oncallAPI: OncallAPI

    let passportService: PassportService

    let passportUserService: PassportUserService

    let deviceService: DeviceManageServiceProtocol

    let userGeneralSettings: UserGeneralSettings

    let versionUpdateService: VersionUpdateService

    let chatterAPI: ChatterAPI

    let guideService: NewGuideService

    let customerServiceAPI: LarkCustomerServiceAPI

    let mineSidebarService: MineSidebarService

    let leanModeStatus: Observable<Bool>

    let chatterManager: ChatterManagerProtocol

    let badgeDependency: MineSettingBadgeDependency

    let inlineService: MessageTextToInlineService

    let tenantNameService: LarkTenantNameService

    let payManagerService: PayManagerService

    let userResolver: UserResolver

    var certificateStatus: Contact_V2_GetUserProfileResponse.UserInfo.CertificateStatus = .uncertificated

    var notifyDisable: Bool {
        return self.userGeneralSettings.notifyConfig.notifyDisable
    }

    var isCustomer: Bool {
        return self.passportUserService.user.type == .c
    }

    var currentUserObservable: Observable<PassportUserState> {
        return self.passportUserService.state
    }

    var currentChatterObservable: Observable<LarkModel.Chatter> {
        return self.chatterManager.currentChatterObservable
    }

    var validSessionsDriver: Driver<[LoginDevice]> {
        return self.deviceService.loginDevices.asDriver(onErrorJustReturn: [])
    }
    func fetchValidSession() {
        self.authAPI.fetchValidSessions().subscribe().disposed(by: self.disposeBag)
    }

    var isNotifyDriver: Driver<Bool> {
        return self.authAPI.isNotifyObservable.asDriver(onErrorJustReturn: true).distinctUntilChanged()
    }

    var isNotify: Bool {
        return self.authAPI.isNotify
    }

    let updateBadgeRelay = BehaviorRelay<Void>(value: ())

     var canConvertTeam: Bool {
        return !ReleaseConfig.isKA
         && !passportUserService.user.isIdPUser
    }

    var canShowUpgradeTeamBadge: Bool {
        get {
            return !passportUserService.user.type.isStandard /* single or c */
                && !userStore[KVKeys.Mine.upgradeTeamMineBadgeShowed]
        }
        set(canShow) {
            userStore[KVKeys.Mine.upgradeTeamMineBadgeShowed] = !canShow
            updateBadgeRelay.accept(())
        }
    }

    var teamConversionTitle: String {
        self.passportService.teamConversionEntryTitle()
    }

    var user: Chatter {
        return self.chatterManager.currentChatter
    }

    /// 钱包url
    var walletUrl: String?

    let disposeBag = DisposeBag()

    func trackTabMe() {
        MineTracker.trackTabMe()
    }

    public func fgValueBy(key: FeatureGatingManager.Key) -> Bool {
        let featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        let fg = featureGatingService?.staticFeatureGatingValue(with: key)
        return fg ?? false
    }

    init(walletEnable: Bool,
         authAPI: AuthAPI,
         passportService: PassportService,
         passportUserService: PassportUserService,
         deviceService: DeviceManageServiceProtocol,
         userGeneralSettings: UserGeneralSettings,
         versionUpdateService: VersionUpdateService,
         chatterAPI: ChatterAPI,
         guideService: NewGuideService,
         oncallAPI: OncallAPI,
         customerServiceAPI: LarkCustomerServiceAPI,
         mineSidebarService: MineSidebarService,
         leanModeStatus: Observable<Bool>,
         chatterManager: ChatterManagerProtocol,
         badgeDependency: MineSettingBadgeDependency,
         inlineService: MessageTextToInlineService,
         tenantNameService: LarkTenantNameService,
         payManagerService: PayManagerService,
         userResolver: UserResolver
    ) {
        self.authAPI = authAPI
        self.passportService = passportService
        self.passportUserService = passportUserService
        self.deviceService = deviceService
        self.userGeneralSettings = userGeneralSettings
        self.versionUpdateService = versionUpdateService
        self.chatterAPI = chatterAPI
        self.guideService = guideService
        self.oncallAPI = oncallAPI
        self.customerServiceAPI = customerServiceAPI
        self.mineSidebarService = mineSidebarService
        self.leanModeStatus = leanModeStatus
        self.chatterManager = chatterManager
        self.badgeDependency = badgeDependency
        self.inlineService = inlineService
        self.tenantNameService = tenantNameService
        self.payManagerService = payManagerService
        self.userResolver = userResolver
        self.walletEnable = walletEnable && AppConfigManager.shared.feature(for: .wallet).isOn

        self.favoriteEnable = AppConfigManager.shared.feature(for: .favorite).isOn

        self.deviceService.fetchLoginDevices()
        // 启动客服服务
        customerServiceAPI.launchCustomerService()
        self.getWalletUrl()
    }

    func bind() {
        self.currentChatterObservable.subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            let currentChatter = self.chatterManager.currentChatter
            self.userStore[KVKeys.Mine.description] = currentChatter.description_p.text
            self.userStore[KVKeys.Mine.descriptionType] = currentChatter.description_p.type.rawValue
        }).disposed(by: self.disposeBag)
    }

    func requestProfileInformation(completion: @escaping (String, Chatter.DescriptionType) -> Void) {
        // 强拉一次, 部门信息会变更
        let userId = self.user.id
        let chatterAPI = self.chatterAPI
        chatterAPI.fetchNewUserProfileInfomation(userId: userId, contactToken: "", chatId: "", sourceType: .unknownSource)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (profileModel) in
                guard let `self` = self else { return }
                let description = profileModel.userInfo.description_p.text
                let descriptionType = profileModel.userInfo.description_p.type
                // update userDefault
                self.userStore[KVKeys.Mine.description] = description
                self.userStore[KVKeys.Mine.descriptionType] = descriptionType.rawValue
                completion(description, descriptionType)
            }, onError: { (error) in
                MineMainViewModel.logger.error(
                    "拉取用户个人信息失败",
                    additionalData: [ "userId": userId ],
                    error: error
                )
            }).disposed(by: self.disposeBag)
    }

    // 拉取企业认证的状态
    func fetchLocalAndServerAuthState() -> Observable<(Bool, Bool, String)> {
        let userId = self.user.id
        let localData = self.chatterAPI
            .getNewUserProfileInfomation(userId: userId,
                                         contactToken: "",
                                         chatId: "")
        let serverData = self.chatterAPI
            .fetchNewUserProfileInfomation(userId: userId,
                                           contactToken: "",
                                           chatId: "",
                                           sourceType: .chat)
        return Observable.merge(localData, serverData)
            .map { [weak self] (res) -> (Bool, Bool, String) in
                guard let self = self, res.userInfo.hasCertificationInfo, res.userInfo.certificationInfo.isShowCertSign else {
                    return (false, false, "")
                }
                self.certificateStatus = res.userInfo.certificationInfo.certificateStatus
                let hasTenantCertification = (self.certificateStatus != .teamCertificated)
                let isTenantCertification = (self.certificateStatus == .certificated)
                let tenantCertificationURL = res.userInfo.certificationInfo.tenantCertificationURL
                return (hasTenantCertification, isTenantCertification, tenantCertificationURL)
            }
    }

    func updateUserDescription() -> (description: String?, descriptionTypeValue: Int?) {
        let descriptionTypeValue = userStore[KVKeys.Mine.descriptionType]
        if let description = userStore[KVKeys.Mine.description] {
            return (description, descriptionTypeValue)
        } else {
            return (nil, nil)
        }
    }

    func getHomePageOncalls(fromLocal: Bool) -> Observable<[Oncall]> {
        return oncallAPI.getHomePageOncalls(fromLocal: fromLocal)
    }

    private var inlineTrackTime: (description: String, startTime: CFTimeInterval) = ("", 0)
    func replaceWithInline(description: String,
                           completion: @escaping (_ description: NSAttributedString,
                                                  _ urlRangeMap: [NSRange: URL],
                                                  _ textUrlRangeMap: [NSRange: String]) -> Void,
                           isFromPush: Bool = false) {
        // 签名变更或未记录开始时间
        if inlineTrackTime.description != description || inlineTrackTime.startTime <= 0 {
            inlineTrackTime = (description, CACurrentMediaTime())
        }
        guard !description.isEmpty else {
            completion(.init(), [:], [:])
            return
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textPlaceholder,
            .font: UIFont.systemFont(ofSize: 12),
            MessageInlineViewModel.iconColorKey: UIColor.ud.iconN3,
            MessageInlineViewModel.tagTypeKey: TagType.normal
        ]
        let sourceID = self.user.id
        inlineService.replaceWithInlineTryMemory(
            sourceID: sourceID,
            sourceText: description,
            type: .personalSig,
            strategy: .tryLocal,
            attributes: attributes,
            completion: { [weak self] result, _, _, sourceType in
                guard let self = self else { return }
                completion(result.attriubuteText, result.urlRangeMap, result.textUrlRangeMap)
                // 存在异步过程，需要判断时序
                if self.inlineTrackTime.description == description {
                    self.inlineService.trackURLInlineRender(
                        sourceID: sourceID,
                        sourceText: description,
                        type: .personalSig,
                        sourceType: sourceType,
                        scene: "my_page",
                        startTime: self.inlineTrackTime.startTime,
                        endTime: CACurrentMediaTime(),
                        isFromPush: isFromPush
                    )
                }
            }
        )
    }

    func getWalletUrl() {
        self.payManagerService.getWalletScheme { [weak self] (walletUrl) in
            guard let self = self else { return }
            self.walletUrl = walletUrl
        }
    }
}
