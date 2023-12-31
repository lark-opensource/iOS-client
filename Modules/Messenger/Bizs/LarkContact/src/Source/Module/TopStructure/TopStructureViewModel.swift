//
//  TopStructureViewModel.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/10/18.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkFeatureGating
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import RustPB
import SuiteAppConfig
import LarkFeatureSwitch
import LarkKAFeatureSwitch
import LarkReleaseConfig
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import LarkContainer
import Contacts
import LarkAddressBookSelector
import LarkUIKit
import LarkStorage
import UGReachSDK
import UGBanner
import LarkSetting

final class TopStructureViewModel: UserResolverWrapper {
    static let logger = Logger.log(TopStructureViewModel.self, category: "TopStructureViewModel")

    let larkMyAIMainSwitch: Bool
    private let userAPI: UserAPI
    private let chatterAPI: ChatterAPI
    @ScopedInjectedLazy var myAIService: MyAIService?

    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService
    private let appConfigService: AppConfigService
    private let dependency: ContactDataDependency
    @ScopedProvider var reachService: UGReachSDKService?
    let unifiedInvitationService: UnifiedInvitationService
    private lazy var userStore = udkv(domain: contactDomain)
    let inviteStorageService: InviteStorageService

    let isEnableOncall: Bool
    let showNormalNavigationBar: Bool
    let isUsingNewNaviBar: Bool
    let awardExternalInviteEnable: Bool
    private let pushContactsOb: Observable<PushContactsInfo>
    // 新注册用户引导是否开启
    var newRegisterGuideEnbale: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: "lark.client.onboarding.opt")
    }
    @ScopedInjectedLazy private var structureService: StructureService?

    var isCurrentAccountInfoSimple: Bool {
        return passportUserService.user.type == .simple
    }
    var departmentEnable: Bool {
        return !self.isCurrentAccountInfoSimple
    }
    var needShowTeamConversionBanner: Bool {
        return !userStore[KVKeys.Contact.teamConversionContactEntryShowed]
            && !ReleaseConfig.isKA
            && !passportUserService.user.isIdPUser
            && passportUserService.user.type == .simple
    }

    private let disposeBag = DisposeBag()

    var currentUserType: Observable<LarkAccountInterface.PassportUserState> {
        return passportUserService.state
    }

    var myAIProfileInfo = BehaviorRelay<Contact_V2_AIProfile?>(value: nil)

    // 联系人入口list开关
    private(set) var contactEntries = ContactEntries()

    // 是否开启内部关联组织功能的FG
    var internalCollaborationFG: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: "lark.admin.orm.b2b.high_trust_parties")
    }

    // 联系人列表服务端开关控制fg，已全量
    var contactsEntryRefactorFG: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: "messenger.contacts.entry_refactor")
    }
    // reload table刷新信号
    var reloadOb: Observable<Void> {
        reloadSubject.asObservable()
    }
    private var reloadSubject = PublishSubject<Void>()

    /// 通讯录状态
    var contactAuthStatus: CNAuthorizationStatus = ContactService.getContactAuthorizationStatus()

    /// 是否需要展示组织架构
    var showOrgnization: Bool {
        return appConfigService.feature(for: .contactOrgnization).isOn
    }

    /// 是否需要展示机器人
    var showBots: Bool {
        return appConfigService.feature(for: .contactBots).isOn
    }

    /// 是否需要展示oncall
    var showHelpdesk: Bool {
        userResolver.fg.staticFeatureGatingValue(with: "suite_help_service_contact") &&
            appConfigService.feature(for: .contactHelpdesk).isOn
    }

    // 名片夹fg
    var showNameCard: Bool {
        userResolver.fg.staticFeatureGatingValue(with: "contact.contactcards.email")
    }

    lazy var bannerHandler: ContactsPermissionUGBannerHandler = {
        let handler = ContactsPermissionUGBannerHandler(resolver: self.userResolver)
        handler.requestAccessCallback = { [weak self] in
            // 申请权限后，关闭Banner
            self?.bannerReachPoint?.hide()
        }
        return handler
    }()

    lazy var bannerReachPoint: BannerReachPoint? = {
        let bizContextProvider = UGAsyncBizContextProvider(
            scenarioId: "SCENE_CONTACT") { [weak self] () -> Observable<[String: String]> in
            guard let self = self else { return Observable.just([:]) }
            let addressbookAuth = self.bannerHandler.addressbookAuth()
            return Observable<[String: String]>.create { (observer) -> Disposable in
                observer.onNext(["addressbookAuth": "\(addressbookAuth)"])
                return Disposables.create()
            }
        }
        let reachPoint: BannerReachPoint? = reachService?.obtainReachPoint(
            reachPointId: "RP_CONTACT_TOP",
            bizContextProvider: bizContextProvider
        )
        reachPoint?.delegate = self

        return reachPoint
    }()

    var needShowInviteContactBanner: Bool = false
    static let inviteContactBannerScenarioId = "SCENE_CONTACT_INVITE"
    static let inviteContactBannerRPId = "RP_CONTACT_INVITE"
    lazy var inviteContactBannerReachPoint: BannerReachPoint? = {
        let bizContextProvider = UGSyncBizContextProvider(scenarioId: Self.inviteContactBannerScenarioId) { [:] }
        let reachPoint: BannerReachPoint? = reachService?.obtainReachPoint(
            reachPointId: Self.inviteContactBannerRPId,
            bizContextProvider: bizContextProvider
        )
        return reachPoint
    }()

    lazy var bannerViewPublish: PublishSubject<(UIView, CGFloat)?> = {
        return PublishSubject<(UIView, CGFloat)?>()
    }()

    init(userAPI: UserAPI,
         chatterAPI: ChatterAPI,
         appConfigService: AppConfigService,
         dependency: ContactDataDependency,
         unifiedInvitationService: UnifiedInvitationService,
         inviteStorageService: InviteStorageService,
         isEnableOncall: Bool,
         showNormalNavigationBar: Bool,
         isUsingNewNaviBar: Bool,
         pushContactsOb: Observable<PushContactsInfo>,
         resolver: UserResolver) throws {
        self.userAPI = userAPI
        self.chatterAPI = chatterAPI
        self.userResolver = resolver
        self.larkMyAIMainSwitch = userResolver.fg.staticFeatureGatingValue(with: "lark.my_ai.main_switch")
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.unifiedInvitationService = unifiedInvitationService
        self.dependency = dependency
        self.inviteStorageService = inviteStorageService
        self.isEnableOncall = isEnableOncall
        self.showNormalNavigationBar = showNormalNavigationBar
        self.isUsingNewNaviBar = isUsingNewNaviBar
        self.appConfigService = appConfigService
        self.awardExternalInviteEnable = userResolver.fg.staticFeatureGatingValue(with: "invite.external.award.enable")
        self.pushContactsOb = pushContactsOb
        self.pushContactsOb.asDriver(onErrorJustReturn: PushContactsInfo(contactInfo: RustPB.Basic_V1_ContactInfo()))
            .drive(onNext: { pushContactsInfo in
                TopStructureViewModel.logger.debug("pushContactsInfo = \(pushContactsInfo)")
            }).disposed(by: self.disposeBag)

        if let onboardingUploadContactsMaxNum = self.dependency.onboardingUploadContactsMaxNum() {
            self.userStore[KVKeys.Contact.onboardingUploadContactsMaxNum] = onboardingUploadContactsMaxNum
        }
        if let uploadContactsIntervalMins = self.dependency.uploadContactsIntervalMins() {
            self.userStore[KVKeys.Contact.uploadContactsCDMins] = uploadContactsIntervalMins
            Tracer.trackUploadIntervalMin(intervalMin: uploadContactsIntervalMins)
        }
        if let contactUploadContactsMaxNum = self.dependency.contactUploadContactsMaxNum() {
            self.userStore[KVKeys.Contact.uploadContactsMaxNum] = contactUploadContactsMaxNum
        }
        self.refreshListByFecthContactEntries()
    }

    // 拉取联系人入口开关, 刷新列表
    func refreshListByFecthContactEntries() {
        guard contactsEntryRefactorFG, let structureService = self.structureService else { return }
        let localOb = structureService.fetchContactEntriesRequest(isFromServer: false,
                                                                  scene: .contacts).materialize()
            .flatMap { event -> Observable<ContactEntries> in
                switch event {
                case .next(let i): return .just(i)
                default: return .never()
                }
            }
            .map { (res) -> (ContactEntries, FetchSource) in
                return (res, .local)
            }
        let serverOb = structureService.fetchContactEntriesRequest(isFromServer: true,
                                                                   scene: .contacts).map { (res) -> (ContactEntries, FetchSource) in
            return (res, .server)
        }
        Observable.merge([localOb, serverOb])
            .observeOn(MainScheduler.instance)
            // 过滤掉数据相同的结果和处理远端先于本地回来的badcase(直接忽略本地的)
            .distinctUntilChanged({ (old, new) -> Bool in
                let isFilter = (old.0 == new.0) || new.1 == .local
                return isFilter
            })
            .subscribe(onNext: { [weak self] (res) in
                self?.contactEntries = res.0
                self?.reloadSubject.onNext(())
            }, onError: { [weak self] (error) in
                Self.logger.error("Contact.Request: fetchContactEntriesRequest error, error = \(error)")
//                self?.contactEntries.setTrueToAllProperty() 请求错误的时候打开全部入口,安卓也没有这个无理的逻辑 -.-
                self?.reloadSubject.onNext(())
            }).disposed(by: self.disposeBag)

    }

    deinit {
        reachService?.recycleReachPoint(reachPointId: "RP_CONTACT_TOP", reachPointType: BannerReachPoint.reachPointType)
        reachService?.recycleReachPoint(reachPointId: Self.inviteContactBannerRPId, reachPointType: BannerReachPoint.reachPointType)
    }

    func closeTeamConversionBanner() {
        TopStructureViewModel.logger.debug("close team conversion banner")
        userStore[KVKeys.Contact.teamConversionContactEntryShowed] = true
    }

    func fetchInviteEntryType(routeHandler: @escaping (InviteEntryType) -> Void) {
        unifiedInvitationService.handleInviteEntryRoute(routeHandler: routeHandler)
    }

    // 目前RP_SPOTLIGHT_ADD_NEW_CONTACT和banner收敛在同一个SCENE_CONTACT内，同时触发
    func tryExposeSceneContact() {
        bannerReachPoint?.register(bannerName: ContactsPermissionUGBannerHandler.bannerName,
                             for: bannerHandler)
        reachService?.tryExpose(by: "SCENE_CONTACT", actionRuleContext: nil, bizContextProvider: nil)
        inviteContactBannerReachPoint?.delegate = self
        reachService?.tryExpose(by: Self.inviteContactBannerScenarioId, specifiedReachPointIds: [Self.inviteContactBannerRPId])
    }

    func updateContactAuthStatusIfNeeded() {
        guard contactAuthStatus == .notDetermined else {
            return
        }
        self.contactAuthStatus = ContactService.getContactAuthorizationStatus()
    }
    var bannerWidth: CGFloat = 0
    func bannerWidthChanged(_ width: CGFloat) {
        fireWidth(width)
        bannerWidth = width
    }

    func fireWidth(_ width: CGFloat) {
        guard let bannerView = bannerReachPoint?.bannerView else {
            return
        }
        let newFrame = CGRect(x: bannerView.frame.minX, y: bannerView.frame.minY, width: width, height: bannerView.frame.height)
        bannerView.frame = newFrame
    }

    func getBannerViewDriver(extra: [String: String] = [:]) -> Driver<(UIView, CGFloat)?> {
        return bannerViewPublish.asDriver(onErrorJustReturn: nil)
    }
}

/// tracking
extension TopStructureViewModel {

    func trackEnterContactHome() {
        Tracer.trackEnterContactHome()
    }

    func trackNewContactBadgeShow() {
        Tracer.trackNewContactBadgeShow()
    }

    func trackNewContactBadgeShowClick() {
        Tracer.trackNewContactBadgeShowClick()
    }
}

extension TopStructureViewModel: BannerReachPointDelegate {
    func onShow(bannerView: UIView, bannerData: BannerInfo, reachPoint: BannerReachPoint) {
        if reachPoint.reachPointId == bannerReachPoint?.reachPointId {
            bannerViewPublish.onNext((bannerView, bannerView.intrinsicContentSize.height))
        } else {
            // 自定义Banner样式
            guard let jsonData = bannerData.customBanner.data.data(using: .utf8),
                  let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                  let title = jsonObject["title"] as? String,
                  let btnText = jsonObject["btnText"] as? String,
                  let btnDict = jsonObject["applink"] as? [String: String],
                  let applink = btnDict["ios"] else {
                return
            }
            let bannerView = TopStructureInviteContactBannerView(title: title, btnText: btnText, applink: applink, resolver: userResolver)
            needShowInviteContactBanner = true
            bannerViewPublish.onNext((bannerView, bannerView.getBannerHeight(width: self.bannerWidth)))
            Tracker.post(TeaEvent(Homeric.CONTACT_ADDMEMBER_CARD_VIEW))
        }
    }

    func onHide(bannerView: UIView, bannerData: BannerInfo, reachPoint: BannerReachPoint) {
        if reachPoint.reachPointId == inviteContactBannerReachPoint?.reachPointId {
            needShowInviteContactBanner = false
        }
        bannerViewPublish.onNext(nil)
    }
}
