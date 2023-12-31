//
//  ContactInviteInfoAPI.swift
//  LarkContact
//
//  Created by ByteDance on 2022/12/7.
//

import Foundation
import LarkAccountInterface
import LarkMessengerInterface
import LarkOpenFeed
import LKCommonsLogging
import LarkSDKInterface
import LarkAppConfig
import Swinject
import RxSwift
import RustPB
import RunloopTools
import LarkModel
import EENavigator
import LarkUIKit
import LarkAvatarComponent
import WidgetKit
import LarkRustClient
import ServerPB
import LarkContainer
import LarkStorage
import LarkFeatureGating

final class ContactInviteInfoAPI: ContactInviteInfoService {
    private typealias InviteBannerStatus = Contact_V1_GetUserInvitationMessageResponse.BannerStatus

    static let logger = Logger.log(ContactInviteInfoAPI.self, category: "LarkContact.ContactInviteInfoAPI")

    private let inviteStorageService: InviteStorageService?
    private let contactAPI: ContactAPI?
    private let resolver: UserResolver
    private let disposeBag = DisposeBag()
    private lazy var userStore = resolver.udkv(domain: contactDomain)

    init(resolver: UserResolver) {
        self.resolver = resolver
        self.inviteStorageService = try? resolver.resolve(assert: InviteStorageService.self)
        self.contactAPI = try? resolver.resolve(assert: ContactAPI.self)
    }

    // 后期可以由 server 提供一个业务聚合接口，用于各处入口控制
    func fetchInviteInfo() {
        guard let passportUserService = try? resolver.resolve(assert: PassportUserService.self) else { return }
        let tenantId = passportUserService.userTenant.tenantID

        /// 混合license组合管理的ORM改造
        /// https://bytedance.feishu.cn/wiki/wikcn5ztkKLHKp5U2QThtB2fJPg
        let enableInviteAccess = resolver.fg.staticFeatureGatingValue(with: "suite.admin.create_user.targeted_invitation")
        Self.logger.info("launch home to fetch member invite info")
        if enableInviteAccess {
            contactAPI?.getInvitationAccessInfo()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] response in
                    self?.inviteStorageService?.setInviteInfo(value: response.administratorAccess,
                                                              key: InviteStorage.inviteAdministratorAccessKey)
                    self?.inviteStorageService?.setInviteInfo(value: response.invitationAccess,
                                                              key: InviteStorage.invitationAccessKey)
                    Self.logger.info("enable show member invite entry",
                                     additionalData: [
                                        "administratorAccess": "\(response.administratorAccess)",
                                        "invitationAccess": "\(response.invitationAccess)"
                                     ]
                    )
                }, onError: {
                    Self.logger.info("error occured >>> \($0.localizedDescription)")
                })
                .disposed(by: disposeBag)

            fetchWhetherAnAdmin()?
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] (isAdmin: Bool) in
                    self?.inviteStorageService?.setInviteInfo(
                        value: isAdmin,
                        key: InviteStorage.isAdministratorKey
                    )
                    Self.logger.info("fetch whether i am an adminitor",
                                                        additionalData: [
                                                            "isAdmin": "\(isAdmin)"]
                    )
                } onError: {
                    Self.logger.info("error occured >>> \($0.localizedDescription)")
                }
                .disposed(by: disposeBag)
        } else {
            fetchMemberInviteInfo()?
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (enableShow, bannerStatus) in
                    // FG开启之前，老接口控制 Feed页 和 通讯录 中两个地方的邀请成员入口
                    self?.inviteStorageService?.setInviteInfo(value: enableShow,
                                                              key: InviteStorage.invitationAccessKey)
                    self?.inviteStorageService?.setInviteInfo(
                        value: enableShow,
                        key: InviteStorage.inviteAdministratorAccessKey
                    )
                    Self.logger.info("enable show member invite entry",
                                                        additionalData: [
                                                            "enableShow": "\(enableShow)",
                                                            "bannerStatus": "\(bannerStatus)"]
                    )
                }, onError: {
                    Self.logger.info("error occured >>> \($0.localizedDescription)")
                })
                .disposed(by: disposeBag)

            fetchWhetherAnAdmin()?
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] (isAdmin: Bool) in
                    self?.inviteStorageService?.setInviteInfo(
                        value: isAdmin,
                        key: InviteStorage.isAdministratorKey
                    )
                    Self.logger.info("fetch whether i am an adminitor",
                                                        additionalData: [
                                                            "isAdmin": "\(isAdmin)"]
                    )
                } onError: {
                    Self.logger.info("error occured >>> \($0.localizedDescription)")
                }
                .disposed(by: disposeBag)
        }
    }

    private func fetchMemberInviteInfo() -> Observable<(Bool, InviteBannerStatus)>? {
        guard let chatterAPI = try? resolver.resolve(assert: ChatterAPI.self) else { return nil }
        return chatterAPI.fetchUserInvitationMessage()
            .map({ (response: Contact_V1_GetUserInvitationMessageResponse) -> (Bool, InviteBannerStatus) in
                return (response.enableShow, response.bannerStatus)
            })
    }

    private func fetchWhetherAnAdmin() -> Observable<Bool>? {
        guard let userAPI = try? resolver.resolve(assert: UserAPI.self) else { return nil }
        guard let passportUserService = try? resolver.resolve(assert: PassportUserService.self) else { return nil }
        let userId = passportUserService.user.userID
        return userAPI.fetchUserProfileInfomation(userId: userId)
            .map({ (response: UserProfile) -> Bool in
                return response.adminInfo.isAdmin
            })
    }

    func setAvatarObserver() {
        guard let userPushCenter = try? resolver.userPushCenter else { return }
        let observer = userPushCenter
            .observable(for: PushChatters.self).flatMap { pushChatters -> Observable<[AvatarTuple]> in
                let tuples = pushChatters.chatters.map { chatter -> AvatarTuple in
                    return AvatarTuple(identifier: chatter.id,
                                       avatarKey: chatter.avatarKey,
                                       medalKey: chatter.medalKey,
                                       medalFsUnit: "")
                }
                return .just(tuples)
            }

        AvatarService.setInputObserver(observer)
    }

    func trackPushNotificationStatus() {
        Tracer.trackPushNotificationStatus()
    }

    func firstLoginEventReport() {
        // ACK首登事件上报
        let rustService = try? self.resolver.resolve(assert: RustService.self)
        let localBag = DisposeBag()
        var request = ServerPB_Flow_BizEventReportRequest()
        request.eventKey = "new_user_create_team_strong_guide"
        rustService?.sendPassThroughAsyncRequest(request, serCommand: .bizEventReport).retry(1).subscribe(onNext: { [weak self] in
            // 上报成功的话清除本地记录
            if let self = self {
                self.userStore.removeValue(forKey: KVKeys.Contact.firstLoginStatus)
            }
            Self.logger.info("report create team strong guide event success!")
        }, onError: { [weak self] error in
            // 上报失败，本地先保存下
            if let self = self {
                self.userStore[KVKeys.Contact.firstLoginStatus] = true
            }
            Self.logger.error("report create team strong guide event fail: \(error)")
        }).disposed(by: localBag)
    }

    func runOnboardingFlow() {
        self.firstLoginEventReport()
        if userStore[KVKeys.Contact.firstLoginStatus] {
            return
        }
        guard let getSceneMaterialsAPI = try? self.resolver.resolve(assert: GetSceneMaterialsAPI.self) else { return }
        guard let passportService = try? resolver.resolve(assert: PassportService.self) else { return }
        // 只有国内&非pad只有新流程
        var scenes: [OnboardingSceneType] = passportService.isOversea || Display.pad ? [.oldOnboarding] : [.oldOnboarding, .register, .newOnBoarding]
        getSceneMaterialsAPI.getMaterialsBySceneRequest(scenes: scenes)?
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { resp in
                // onboarding tasks,执行顺序 表单 -> 强引导 -> onboarding
                var tasks: [OnboardingTask] = []
                // 强制表单页
                if let registerResp = resp.scenes[OnboardingSceneType.register.rawValue],
                    registerResp.result,
                    let material = registerResp.materials.first(where: {
                        !$0.entity.weblink.link.isEmpty
                    }) {
                    let url = material.entity.weblink.link
                    let registerTask = OnboardingTask(taskType: .register, url: url)
                    tasks.append(registerTask)
                }
                // 强引导页
                if let oldOnboardingResp = resp.scenes[OnboardingSceneType.oldOnboarding.rawValue], oldOnboardingResp.result {
                    let oldOnboardingTask = OnboardingTask(taskType: .memberInvite)
                    tasks.append(oldOnboardingTask)
                }
                // Onboarding页
                if let onboardingResp = resp.scenes[OnboardingSceneType.newOnBoarding.rawValue],
                   onboardingResp.result,
                    let material = onboardingResp.materials.first(where: {
                        !$0.entity.weblink.link.isEmpty
                    }) {
                    // 获取全屏配置
                    var isFullScreen = false
                    if let data = material.entity.weblink.display.data(using: .utf8),
                       let displayConfig = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let pageSize = displayConfig["page_size"] as? Int {
                        isFullScreen = (pageSize == 1)
                    }
                    let url = material.entity.weblink.link
                    let extraInfo = ["isFullScreen": isFullScreen]
                    let onboardingTask = OnboardingTask(taskType: .onboarding, url: url, extraInfo: extraInfo)
                    tasks.append(onboardingTask)
                }
                Self.logger.info("onboarding task list: \(tasks)")
                if !tasks.isEmpty {
                    let manager = OnboardingTaskManager.getSharedInstance()
                    manager.removeAllTasks()
                    manager.addTasks(tasks: tasks)
                    manager.executeNextTask()
                }
            }, onError: { error in
                Self.logger.error("onboarding request error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    lazy var coldStartDialogManager = {
        return ColdStartDialogManager(resolver: resolver)
    }()

    public func fetchTenantCreateGuide() {
        guard let feedContext = try? resolver.resolve(assert: FeedContextService.self) else { return }
        var localDispose = DisposeBag()
        // 监听feedVC页面，直到feedVC发出viewWillAppear或周期之后的信号，就停止监听
        // 监听到feed页面创建时候再进行弹出，避免页面弹出在先，切换租户后给吞噬了
        let feedViewWillAppear: FeedPageState = .viewWillAppear
        feedContext.pageAPI.pageStateObservable.asObservable().single { $0.rawValue >= feedViewWillAppear.rawValue }
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else {
                    return
                }
                localDispose = DisposeBag()
                guard let window = self.resolver.navigator.mainSceneWindow else {
                    return
                }
                guard let getSceneMaterialsAPI = try? self.resolver.resolve(assert: GetSceneMaterialsAPI.self) else { return }
                getSceneMaterialsAPI.getMaterialsBySceneRequest(scenes: [.firstLoginEvent])?
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] resp in
                        guard let self = self else { return }
                        // 是否首登事件
                        let isFirstLogin = resp.scenes[OnboardingSceneType.firstLoginEvent.rawValue]?.result ?? false
                        if !isFirstLogin {
                            Self.logger.info("not first login")
                            self.coldStartDialogManager.triggerColdStartDialog()
                            return
                        }
                        self.runOnboardingFlow()
                    }, onError: { error in
                        Self.logger.error("onboarding request error: \(error)")
                    }).disposed(by: self.disposeBag)
        }).disposed(by: localDispose)
    }
}
