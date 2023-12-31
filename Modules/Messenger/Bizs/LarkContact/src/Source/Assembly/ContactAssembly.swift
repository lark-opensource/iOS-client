//
//  ContactAssembly.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/7/30.
//

import UIKit
import Foundation
import LarkContainer
import Swinject
import LarkModel
import LarkCore
import LarkNavigation
import EENavigator
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LKCommonsLogging
import LarkAppConfig
import LarkMessengerInterface
import EETroubleKiller
import LarkUIKit
import LarkAppLinkSDK
import LarkDebugExtensionPoint
import AnimatedTabBar
import SuiteAppConfig
import LarkSnsShare
import BootManager
import LarkRustClient
import LarkOpenChat
import LarkTab
import LarkSearchCore
import RxCocoa
import RxSwift
import LarkWaterMark
import RustPB
import LarkAccount
import UniverseDesignColor
import UniverseDesignToast
import LarkProfile
import LarkAssembler
import LarkSetting
import LarkOpenFeed
import IESGeckoKit

public enum ContactContainerSettings {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.profile") //Global
        return v
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public typealias ContactDependency = PersonCardHandlerDependency
    & ContactMeetingDependency

public final class ContactAssembly: LarkAssemblyInterface {

    static let logger = Logger.log(ContactAssembly.self, category: "Contact.ContactAssembly")

    public let config: ContactAssemblyConfig

    deinit {
        Self.logger.info("n_action_contact_assembly_deinit")
    }

    public init(config: ContactAssemblyConfig) {
        self.config = config
        Self.logger.info("n_action_contact_assembly_init")
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(NewContactLaunchTask.self)
        NewBootManager.register(IndustryOnboardingTask.self)
        NewBootManager.register(IndustryOnboardingFeedTask.self)
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(ContactContainerSettings.userScope)
        let userGraph = container.inObjectScope(ContactContainerSettings.userGraph)
        let resolver = container

        user.register(LDRGuideAPI.self) { r in
            return RustLDRGuideAPI(resolver: r)
        }

        user.register(GetSceneMaterialsAPI.self) { r in
            return ServerGetSceneMaterialsAPI(resolver: r)
        }

        user.register(SetContactInfomationMonitorService.self) { (r) -> SetContactInfomationMonitorService in
            return SetInfomationMonitor(resolver: r)
        }

        user.register(UnifiedInvitationService.self) { (r) -> UnifiedInvitationService in
            let inviteStorageService = try r.resolve(assert: InviteStorageService.self)
            let userAPI = try r.resolve(assert: UserAPI.self)
            let contactAPI = try r.resolve(assert: ContactAPI.self)
            let passportService = try resolver.resolve(assert: PassportService.self)
            let isOversea = passportService.isOversea
            return try UnifiedInvitationServiceImp(resolver: r,
                                                   inviteStorageService: inviteStorageService,
                                                   userAPI: userAPI,
                                                   contactAPI: contactAPI,
                                                   isOversea: isOversea)
        }

        user.register(InviteStorageService.self) { r -> InviteStorageService in
            return try InviteStorageServiceImpl(resolver: r)
        }

        user.register(LarkProfileAPI.self) { (r) -> LarkProfileAPI in
            let rustClient = try r.resolve(assert: RustService.self)
            return LarkProfileAPIImp(client: rustClient)
        }

        user.register(StructureService.self) { r in
            return StructureServiceImpl(resolver: r)
        }

        user.register(ContactDataService.self) { (r) -> ContactDataService in
            let contactAPI = try r.resolve(assert: ContactAPI.self)
            let passportService = try resolver.resolve(assert: PassportService.self)
            let isOversea = passportService.isOversea
            return ContactDataManager(contactAPI: contactAPI, isOversea: isOversea)
        }

        user.register(ContactApplicationViewControllerRouter.self) { r -> ContactApplicationViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(NewExternalContactsViewControllerRouter.self) { r -> NewExternalContactsViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(GroupedExternalContactsViewControllerRouter.self) { r -> GroupedExternalContactsViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(ContactAddListRouter.self) { r -> ContactAddListRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(OnCallViewControllerRouter.self) { r -> OnCallViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(RobotViewControllerRouter.self) { r -> RobotViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(GroupsViewControllerRouter.self) { r -> GroupsViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(DepartmentViewControllerRouter.self) { r -> DepartmentViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(CollaborationDepartmentViewControllerRouter.self) { r -> CollaborationDepartmentViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(CustomerContactRouter.self) { r -> CustomerContactRouter in
            return try CustomerContactRouterFactory(resolver: r).create()
        }

        user.register(CustomerSelectRouter.self) { r -> CustomerSelectRouter in
            return CustomerSelectRouterImpl(resolver: r)
        }

        user.register(TopStructureViewControllerRouter.self) { r -> TopStructureViewControllerRouter in
            return TopStructureRouterFactory.create(with: r)
        }

        user.register(AddContactViewControllerRouter.self) { r -> AddContactViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(ExternalInviteSendRouter.self) { r -> ExternalInviteSendRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(UnifiedPartnerInvitationRouter.self) { (r) -> UnifiedPartnerInvitationRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(ExternalContactsInvitationRouter.self) { (r) -> ExternalContactsInvitationRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(ExternalContactSplitRouter.self) { (r) -> ExternalContactSplitRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(ExternalContactImportRouter.self) { (r) -> ExternalContactImportRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(InviteByContactsSearchRouter.self) { (r) -> InviteByContactsSearchRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(AddrBookContactRouter.self) { (r) -> AddrBookContactRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(LarkProfileDataProviderDependency.self) { r -> LarkProfileDataProviderDependency in
            return LarkProfileDataProviderDependencyImp(resolver: r)
        }

        user.register(ProfileFactory.self) { resolver -> ProfileFactory in
            return LarkProfileFactory(resolver: resolver)
        }

        container.register(ContactMeetingDependency.self) { (r) -> ContactMeetingDependency in
            return try r.resolve(assert: ContactDependency.self)
        }

        user.register(ContactSearchViewControllerRouter.self) { r -> ContactSearchViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(MemberInviteSplitPageRouter.self) { r -> MemberInviteSplitPageRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(MemberInviteRouter.self) { r -> MemberInviteRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(MemberInviteNoDirectionalControllerRouter.self) { r -> MemberInviteNoDirectionalControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(TeamCodeInviteControllerRouter.self) { (r) -> TeamCodeInviteControllerRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(MemberInviteGuideRouter.self) { (r) -> MemberInviteGuideRouter in
            return try ContactRouter(resolver: r)
        }

        user.register(ContactInviteInfoService.self) { (r) -> ContactInviteInfoService in
            return try ContactInviteInfoAPI(resolver: r)
        }

        userGraph.register(ContactSearchViewController.self) { (r) -> ContactSearchViewController in
            let searchAPI = try r.resolve(assert: SearchAPI.self)
            let serverNTPTimeService = try r.resolve(assert: ServerNTPTimeService.self)
            let router = try r.resolve(assert: ContactSearchViewControllerRouter.self)

            return try ContactSearchViewController(searchAPI: searchAPI,
                                               serverNTPTimeService: serverNTPTimeService,
                                               router: router,
                                               resolver: r)
        }

        user.register(CollaborationSearchViewControllerRouter.self) { r -> CollaborationSearchViewControllerRouter in
            return try ContactRouter(resolver: r)
        }

        userGraph.register(CollaborationSearchViewController.self) { r -> CollaborationSearchViewController in
            let userAPI = try r.resolve(assert: UserAPI.self)
            let departmentAPI = CollaborationDepartmentAPI(userAPI: userAPI)
            let vm = CollaborationSearchResultViewModel(departmentAPI: departmentAPI, associationContactType: nil)
            let searchResultViewController = CollaborationSearchResultViewController(vm: vm)
            let chatterDriver = try r.userPushCenter.driver(for: PushChatters.self)
            let router = try r.resolve(assert: CollaborationSearchViewControllerRouter.self)
            return CollaborationSearchViewController(
                searchResultViewController: searchResultViewController,
                departmentAPI: departmentAPI,
                chatterDriver: chatterDriver,
                router: router,
                associationContactType: nil,
                resolver: r
            )
        }

        userGraph.register(NewExternalContactsViewController.self) { (r) -> NewExternalContactsViewController in
            let externalContactsAPI = try r.resolve(assert: ExternalContactsAPI.self)
            let pushDriver = try r.userPushCenter.driver(for: PushNewExternalContacts.self)
            let viewModel = try NewExternalContactsViewModel(externalContactsAPI: externalContactsAPI,
                                                         pushDriver: pushDriver,
                                                         resolver: r)
            let router = try r.resolve(assert: NewExternalContactsViewControllerRouter.self)
            let externalVC = NewExternalContactsViewController(viewModel: viewModel, router: router, resolver: r)
            return externalVC
        }

        userGraph.register(GroupedExternalContactsViewController.self) { (r) -> GroupedExternalContactsViewController in
            // grouped
            let externalContactsAPI = try r.resolve(assert: ExternalContactsAPI.self)
            let pushDriver = try r.userPushCenter.driver(for: PushNewExternalContacts.self)
            let viewModel = try GroupedExternalContactsViewModel(externalContactsAPI: externalContactsAPI,
                                                             pushDriver: pushDriver,
                                                             resolver: r)
            let router = try r.resolve(assert: GroupedExternalContactsViewControllerRouter.self)
            let groupedExternalVC = try GroupedExternalContactsViewController(viewModel: viewModel, router: router, resolver: r)
            return groupedExternalVC
        }

        userGraph.register(InvitationViewController.self) { (r, content: String) -> InvitationViewController in
            let passportService = try r.resolve(assert: PassportService.self)
            let viewModel = InvitationViewModel(
                chatApplicationAPI: try r.resolve(assert: ChatApplicationAPI.self),
                content: content,
                appConfiguration: try r.resolve(assert: AppConfiguration.self),
                inviteAbroadphone: r.fg.staticFeatureGatingValue(with: "invite.abroadphone.enable"),
                isOversea: passportService.isOversea
            )
            return InvitationViewController(viewModel: viewModel, resolver: r)
        }

        // 默认的ChatterPicker 默认页
        userGraph.register(UIView.self, name: "LarkChatterPickerDefaultView") { (r, picker: ChatterPicker) -> UIView in
            let passportUserService = try r.resolve(assert: PassportUserService.self)
            if passportUserService.userTenant.isCustomer {
                let vm = CustomerSelectViewModel(isShowGroup: false,
                                                 externalContactsAPI: try r.resolve(assert: ExternalContactsAPI.self),
                                                 pushDriver: try r.userPushCenter.driver(for: PushExternalContacts.self))
                let config = CustomerVC.Config(openMyGroups: { _ in assertionFailure("unreachable code!!") })
                let vc = CustomerVC(viewModel: vm, config: config, selectionSource: picker)
                let wrapper = VCWraper()
                wrapper.childController = vc
                return wrapper
            } else {
                return StructureView(frame: .zero, dependency: DefaultStructureViewDependencyImpl(r: r, picker: picker), resolver: r)
            }
        }

        userGraph.register(NameCardWrapperViewController.self) { (r) -> NameCardWrapperViewController in
            let pushCenter = try r.userPushCenter
            let nameCardAPI = try r.resolve(assert: NamecardAPI.self)
            let nameCardListVC = NameCardWrapperViewController(namecardAPI: nameCardAPI, pushCenter: pushCenter, resolver: r)
            return nameCardListVC
        }

        /// LDR 页面
        userGraph.register(LDRGuideViewController.self) { (r) -> LDRGuideViewController in
            let passportService = try resolver.resolve(assert: PassportService.self)
            let isOversea = passportService.isOversea
            let viewModel = try LDRGuideViewModel(isOversea: isOversea, resolver: r)
            let ldrGuideVC = LDRGuideViewController(vm: viewModel, resolver: r)
            return ldrGuideVC
        }

        container.register(ContactDataDependency.self) { r in ContactDataDependencyImpl(resolver: r) }
        container.register(UnifiedInvitationDependency.self) { r in UnifiedInvitationDependencyImpl(resolver: r) }
    }

    public func registURLInterceptor(container: Container) {
        // 客服群
        (CustomServiceChatBody.pattern, { (url: URL, from: NavigatorFrom) in
            Navigator.shared.showDetailOrPush(url: url, tab: .feed, from: from) //Global
        })

        // 好友申请
        (ContactApplicationsBody.pattern, { (url: URL, from: NavigatorFrom) in
            Navigator.shared.showDetailOrPush(url: url, tab: .contact, from: from) //Global
        })

        // 邀请成员
        (MemberDirectedInviteBody.pattern, { (url: URL, from: NavigatorFrom) in
            let departments = (url.queryParameters["departments"])?.components(separatedBy: ",") ?? []
            let body = MemberDirectedInviteBody(
                sourceScenes: .urlLink,
                isFromInviteSplitPage: false,
                departments: departments
            )
            if Display.pad {
                Navigator.shared.present( //Global
                    body: body,
                    wrap: LkNavigationController.self,
                    from: from,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                Navigator.shared.push(body: body, from: from) //Global
            }
        })

        // 国内邀请成员分流页
        (MemberInviteSplitBody.pattern, { (url: URL, from: NavigatorFrom) in
            let departments = (url.queryParameters["departments"])?.components(separatedBy: ",") ?? []
            let body = MemberInviteSplitBody(
                sourceScenes: .urlLink,
                departments: departments
            )
            if Display.pad {
                Navigator.shared.present( //Global
                    body: body,
                    wrap: LkNavigationController.self,
                    from: from,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                Navigator.shared.push(body: body, from: from) //Global
            }
        })

        // 海外邀请成员分流页
        (MemberInviteLarkSplitBody.pattern, { (url: URL, from: NavigatorFrom) in
            let departments = (url.queryParameters["departments"])?.components(separatedBy: ",") ?? []
            let body = MemberInviteLarkSplitBody(
                sourceScenes: .urlLink,
                departments: departments
            )
            if Display.pad {
                Navigator.shared.present( //Global
                    body: body,
                    wrap: LkNavigationController.self,
                    from: from,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                Navigator.shared.push(body: body, from: from) //Global
            }
        })

        // B2B 企业关联邀请页
        (AssociationInviteBody.pattern, { (_: URL, from: NavigatorFrom) in
            let body = AssociationInviteBody(source: .urlLink, contactType: .external)
            if Display.pad {
                Navigator.shared.present( //Global
                    body: body,
                    wrap: LkNavigationController.self,
                    from: from,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                Navigator.shared.push(body: body, from: from) //Global
            }
        })

        // 团队码邀请
        (TeamCodeInviteBody.pattern, { (url: URL, from: NavigatorFrom) in
            let departments = (url.queryParameters["departments"])?.components(separatedBy: ",") ?? []
            let body = TeamCodeInviteBody(
                sourceScenes: .urlLink,
                departments: departments
            )
            if Display.pad {
                Navigator.shared.present( //Global
                    body: body,
                    wrap: LkNavigationController.self,
                    from: from,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            } else {
                Navigator.shared.push(body: body, from: from) //Global
            }
        })
    }

    public func registRouter(container: Container) {
        let resolver = container
        /// TODO: 暂时放这里，等杨京支持
        let wrapperURL: () -> Router = {
            /// 注册step给passport
            guard let accountServiceUG = try? resolver.resolve(assert: AccountServiceUG.self) else { return Router() } //Global
            accountServiceUG.registPassportEventBus(stepName: "ug_purpose_collection") { stepInfo in
                var logTool = UGBrowserTool()
                func fallback() {
                    if let backupStepInfo = stepInfo["backup"] as? [String: Any] {
                        accountServiceUG.dispatchNext(stepInfo: backupStepInfo) { [weak logTool] in
                            /// call success
                            logTool?.log("dispatch next: backup success")
                        } failure: { [weak logTool] error in
                            /// call failure
                            logTool?.log("dispatch next: backup failure: \(error)")
                        }
                    }
                }
                guard let url = stepInfo["url"] as? String,
                      let URL = URL(string: url),
                      let window = Navigator.shared.mainSceneWindow else { //Global
                    logTool.log("open url fail, may be window is nil, stepInfo: \(stepInfo)")
                    fallback()
                    return
                }
                var hud = UDToast.showLoading(on: window)
                UGBrowserTool.checkURLReceivable(url: url) { [weak hud, weak logTool] receivable in
                    logTool?.log("url: \(url), receivable: \(receivable)")
                    hud?.remove()
                    if receivable {
                        let browserBody = UGBrowserBody(url: URL, stepInfo: stepInfo, fallback: fallback)
                        Navigator.shared.push(body: browserBody, from: window) //Global
                    } else {
                        fallback()
                    }
                }
            }
            #if LarkContact_UGOversea
            accountServiceUG.registPassportEventBus(stepName: "remote_register_info") { stepInfo in
                var logTool = UGOverseaBrowserTool()
                func fallback(reason: String) {
                    //slardar监控
                    if let accountServiceUG = try? resolver.resolve(assert: AccountServiceUG.self) { //Global
                        accountServiceUG.fallbackProbe(by: reason, in: "remote_register_info")
                    }
                    if let backupStepInfo = stepInfo["backup"] as? [String: Any] {
                        accountServiceUG.dispatchNext(stepInfo: backupStepInfo) { [weak logTool] in
                            /// call success
                            logTool?.log("dispatch next: backup success")
                        } failure: { [weak logTool] error in
                            /// call failure
                            logTool?.log("dispatch next: backup failure: \(error)")
                        }
                    }
                }
                guard let url = stepInfo["scene_url"] as? String,
                      var URL = URL(string: url),
                      let window = Navigator.shared.mainSceneWindow else { //Global
                    logTool.log("open url fail, may be window is nil, stepInfo: \(stepInfo)")
                    fallback(reason: "parseError")
                    return
                }

                //传入当前端内语言
                let lang = accountServiceUG.getLang()
                URL = URL.append(parameters: lang)
                let browserBody = UGOverseaBrowserBody(url: URL, stepInfo: stepInfo, fallback: fallback)
                Navigator.shared.push(body: browserBody, from: window) //Global

                // 进入global入口埋点
                accountServiceUG.enterGlobalRegistEnterProbe()
            }
            accountServiceUG.registPassportEventBus(stepName: "global_idp_login_step") { stepInfo in
                var logTool = UGOverseaBrowserTool()
                func fallback(reason: String) {
                    //slardar监控
                    if let accountServiceUG = try? resolver.resolve(assert: AccountServiceUG.self) { //Global
                        accountServiceUG.fallbackProbe(by: reason, in: "global_idp_login_step")
                    }
                    if let backupStepInfo = stepInfo["backup"] as? [String: Any] {
                        accountServiceUG.dispatchNext(stepInfo: backupStepInfo) { [weak logTool] in
                            /// call success
                            logTool?.log("dispatch next: backup success")
                        } failure: { [weak logTool] error in
                            /// call failure
                            logTool?.log("dispatch next: backup failure: \(error)")
                        }
                    }
                }
                guard let url = stepInfo["url"] as? String,
                      let URL = URL(string: url),
                      let window = Navigator.shared.mainSceneWindow else { //Global
                    logTool.log("open url fail, may be window is nil, stepInfo: \(stepInfo)")
                    fallback(reason: "parseError")
                    return
                }
                let browserBody = UGOverseaBrowserBody(url: URL, stepInfo: stepInfo, fallback: fallback)
                Navigator.shared.push(body: browserBody, from: window) //Global
            }
            #endif

          if self.config.canAddFriend {
              Navigator.shared.registerRoute.type(AddFriendBody.self)
                  .factory(cache: true, NewAddFriendHandler.init(resolver:))

            var friendRegexp: NSRegularExpression?

              Navigator.shared.registerRoute
                  .match { url in
                      do {
                          let pattern = "^http(s)?\\://([^.]+\\.)?/?([^/]+/)*add_contact/?\\?token=.+"
                          let tmpFriendRegexp = try friendRegexp ?? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                          friendRegexp = tmpFriendRegexp
                          let urlStr = url.absoluteString
                          let range = NSRange(location: 0, length: urlStr.count)
                          return !tmpFriendRegexp.matches(in: urlStr, options: [], range: range).isEmpty
                      } catch {
                          return false
                      }
                  }
                  .handle { r, req, res in
                      if let token = req.parameters["token"] as? String {
                          if Display.pad {
                              res.end(error: nil)
                              r.navigator.present(
                                body: AddFriendBody(token: token),
                                context: req.context,
                                wrap: LkNavigationController.self,
                                from: req.from,
                                prepare: { (vc) in
                                    vc.modalPresentationStyle = .formSheet
                                })
                          } else {
                              res.redirect(body: AddFriendBody(token: token))
                          }
                      } else {
                          res.end(error: RouterError.invalidParameters("token"))
                      }
                  }

              Navigator.shared.registerRoute
                  .match { url in
                      let urlStr = url.absoluteString
                      return urlStr == "//client/contact/share"
                  }.handle { _, _, res in
                      let body = ExternalContactsInvitationControllerBody(scenes: .myQRCode, fromEntrance: .profile)
                      res.redirect(body: body)
                  }

            URLInterceptorManager.shared.register(AddFriendBody.pattern) { (url, from) in
                Navigator.shared.showDetailOrPush(url: url, tab: .feed, from: from) //Global
            }
          }
          return Router()
        }
        wrapperURL()
        getRegistRouter(container: container)
    }

    private func getRegistRouter(container: Container) -> Router {
        let resolver = container

        Navigator.shared.registerRoute.plain(Tab.contact.urlString)
        .priority(.high)
        .factory(cache: true, ContactTopStructureHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ChatterPickerBody.self)
                    .factory(ChatterPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(TeamChatterPickerBody.self)
                    .factory(TeamChatterPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(VCChatterPickerBody.self)
                    .factory(VCChatterPickerHandler.init(resolver:))
        Navigator.shared.registerRoute.type(MedalVCBody.self)
            .factory(cache: true, MedalHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ApplyCommunicationPermissionBody.self)
                    .factory(ApplyCommunicationPermissionHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ContactSearchPickerBody.self)
                    .factory(ContactSearchPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(CalendarChatterPickerBody.self)
                    .factory(CalendarChatterPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MailChatterPickerBody.self)
                    .factory(MailChatterPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MailGroupChatterPickerBody.self)
                    .factory(MailGroupChatterPickerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(OnCallViewControllerBody.self)
                    .factory(OnCallViewControllerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(RobotViewControllerBody.self)
                    .factory(RobotViewControllerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(GroupsViewControllerBody.self)
                    .factory(GroupsViewControllerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ContactPickListBody.self)
                    .factory(ContactPickListHandler.init(resolver:))

        Navigator.shared.registerRoute.type(CreateGroupPickBody.self)
                    .factory(cache: true, CreateGroupPickHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ProfileCardBody.self)
                    .factory(cache: true, ProfileCardHandler.init(resolver:))

        Navigator.shared.registerRoute.type(PersonCardBody.self)
                    .factory(cache: true, NewPersonCardHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MyAIProfileBody.self)
                    .factory(cache: true, MyAIProfileHandler.init(resolver:))

        Navigator.shared.registerRoute.type(PersonCardLinkBody.self)
                    .factory(cache: true, PersonCardLinkHandler.init(resolver:))

        Navigator.shared.registerRoute.type(GroupModeViewBody.self)
                    .factory(cache: true, GroupModeViewRouter.init(resolver:))

        Navigator.shared.registerRoute.type(GroupNameVCBody.self)
                    .factory(cache: true, GroupNameVCRouter.init(resolver:))

        Navigator.shared.registerRoute.type(ContactApplicationsBody.self)
                    .factory(ContactApplicationHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SmartMemberInviteBody.self)
                    .factory(SmartMemberInviteHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MemberInviteSplitBody.self)
                    .factory(MemberInviteSplitHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MemberInviteLarkSplitBody.self)
                    .factory(MemberInviteLarkSplitHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MemberDirectedInviteBody.self)
                    .factory(InviteMemberHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SetAliasViewControllerBody.self)
                    .factory(SetAliasViewControllerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SetInformationViewControllerBody.self)
                    .factory(SetInformationViewControllerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MemberNoDirectionalBody.self)
                    .factory(MemberNoDirectionalHandler.init(resolver:))

        Navigator.shared.registerRoute.type(TeamCodeInviteBody.self)
                    .factory(TeamCodeInviteHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MemberInviteGuideBody.self)
                    .factory(MemberInviteGuideHandler.init(resolver:))

        Navigator.shared.registerRoute.type(LDRGuideBody.self)
            .factory(LDRGuideHandler.init(resolver:))

        Navigator.shared.registerRoute.type(UGBrowserBody.self)
            .factory(UGBrowserHandler.init(resolver:))
        #if LarkContact_UGOversea
        Navigator.shared.registerRoute.type(UGOverseaBrowserBody.self)
            .factory(UGOverseaBrowserHandler.init(resolver:))
        #endif

        Navigator.shared.registerRoute.type(SMBGuideBody.self)
            .factory(SMBGuideHandler.init(resolver:))

        Navigator.shared.registerRoute.type(UnifiedInvitationBody.self)
            .factory(UnifiedPartnerInvitationControllerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SmartUnifiedInvitationBody.self)
            .factory(SmartUnifiedInvitationHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ExternalContactDynamicBody.self)
            .factory(ExternalContactDynamicHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ExternalContactsInvitationControllerBody.self)
            .factory(ExternalContactsInvitationControllerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ExternalContactSplitBody.self)
            .factory(ExternalContactSplitHandler.init(resolver:))

        Navigator.shared.registerRoute.type(AssociationInviteBody.self)
            .factory(AssociationInviteHandler.init(resolver:))

        Navigator.shared.registerRoute.type(AssociationInviteQRPageBody.self)
            .factory(AssociationInviteQRPageHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ContactsSearchBody.self)
            .factory(ContactsSearchHandler.init(resolver:))

        Navigator.shared.registerRoute.type(AddContactViewControllerBody.self)
            .factory(AddContactViewControllerHandler.init(resolver:))

        Navigator.shared.registerRoute.type(CreateGroupWithRecordBody.self)
            .factory(cache: true, CreateGroupWithRecordHandler.init(resolver:))

        Navigator.shared.registerRoute.type(CreateDepartmentGroupBody.self)
            .factory(cache: true, CreateDepartmentGroupHandler.init(resolver:))

        Navigator.shared.registerRoute.type(CreateGroupBody.self)
            .factory(cache: true, CreateGroupHandler.init(resolver:))

        Navigator.shared.registerRoute.type(CreateGroupWithFaceToFaceBody.self)
            .factory(CreateGroupWithFaceToFaceHandler.init(resolver:))

        // 打电话
        Navigator.shared.registerRoute.type(OpenTelBody.self)
            .factory(OpenTelHandler.init(resolver:))

        // 邀请外部联系人
        Navigator.shared.registerRoute.type(ExternalInviteSendControllerBody.self)
            .factory(ExternalInviteSendControllerHandler.init(resolver:))

        // 邀请外部联系人引导页
        Navigator.shared.registerRoute.type(ExternalInviteGuideBody.self)
            .factory(ExternalInviteGuideHandler.init(resolver:))

        // 添加联系人
        Navigator.shared.registerRoute.type(AddContactRelationBody.self)
            .factory(AddContactRelationControllerHandler.init(resolver:))

        // 部门
        Navigator.shared.registerRoute.type(DepartmentBody.self)
            .factory(DepartmentHandler.init(resolver:))

        // 关联组织
        Navigator.shared.registerRoute.type(CollaborationDepartmentBody.self)
            .factory(CollaborationDepartmentHandler.init(resolver:))

        // 外部联系人列表
        Navigator.shared.registerRoute.type(ExternalContactsBody.self)
            .factory(ExternalContactsHandler.init(resolver:))

        // 特别关注人列表
        Navigator.shared.registerRoute.type(SpecialFocusListBody.self)
            .factory(SpecialFocusListHandler.init(resolver:))

        // 邀请人
        Navigator.shared.registerRoute.type(InvitationBody.self)
            .factory(InvitationHandler.init(resolver:))

        // 选择区号
        Navigator.shared.registerRoute.type(SelectCountryNumberBody.self)
            .factory(SelectCountryNumberHandler.init(resolver:))

        // 外部群加人
        Navigator.shared.registerRoute.type(ExternalGroupAddMemberBody.self)
            .factory(cache: true, ExternalGroupAddMemberHandler.init(resolver:))

        // 单向联系人多选添加好友弹窗
        Navigator.shared.registerRoute.type(MAddContactApplicationAlertBody.self)
            .factory(cache: true, MAddContactApplicationAlertBodyHandler.init(resolver:))

        // 单向联系人添加好友弹窗
        Navigator.shared.registerRoute.type(AddContactApplicationAlertBody.self)
            .factory(cache: true, AddContactApplicationAlertHandler.init(resolver:))

        // 名片夹 - 编辑页面
        Navigator.shared.registerRoute.type(NameCardEditBody.self)
            .factory(NameCardEditHandler.init(resolver:))

        // 名片夹 - 列表
        Navigator.shared.registerRoute.type(NameCardListBody.self)
            .factory(NameCardListHandler.init(resolver:))

        // 名片夹- profile
        return Navigator.shared.registerRoute.type(NameCardProfileBody.self)
            .factory(cache: true, NameCardProfileHandler.init(resolver:))
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushChatApplications, ChatApplicationPushHandler.init(resolver:))
        // 特别关注人
        (Command.pushFocusChatter, PushFocusChatterHandler.init(resolver:))
        (Command.mailSharedAccountChangePush, MailShareAccountChangedHandler.init(resolver:))
        (Command.mailContactMateChange, MailContactChangedHandler.init(resolver:))
        // 导致IM会话的引导banner状态发生变化的实时事件的推送
        (Command.pushContactApplicationBannerAffectEvent, PushContactApplicationBannerAffectEventHandler.init(resolver:))
        // 联系人
        (Command.pushChatApplicationBadge, ChatApplicationBadgePushHandler.init(resolver:))
    }

   public func registLarkAppLink(container: Container) {
        let resolver = container
        if config.canAddFriend {
            // 添加好友
            LarkAppLinkSDK.registerHandler(path: AddFriendBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let queryParameters = applink.url.queryParameters
                if let token = queryParameters["token"] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        let body = AddFriendBody(token: token)
                        if Display.pad {
                            Navigator.shared.present(  //Global
                                body: body,
                                wrap: LkNavigationController.self,
                                from: from,
                                prepare: { vc in
                                    vc.modalPresentationStyle = LarkCoreUtils.formSheetStyle()
                                })
                        } else {
                            Navigator.shared.push(body: body, from: from)  //Global
                        }
                    })
                }
            })

            // 国内成员邀请分流页
            LarkAppLinkSDK.registerHandler(path: MemberInviteSplitBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let queryParameters = applink.url.queryParameters
                let sourceScenes = MemberInviteSourceScenes.transform(queryParameters["from_scenes"] ?? "unknown")
                let departments = (queryParameters["departments"])?.components(separatedBy: ",") ?? []
                let body = MemberInviteSplitBody(sourceScenes: sourceScenes, departments: departments)
                if Display.pad {
                    Navigator.shared.present(  //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 海外成员邀请分流页
            LarkAppLinkSDK.registerHandler(path: MemberInviteLarkSplitBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let queryParameters = applink.url.queryParameters
                let sourceScenes = MemberInviteSourceScenes.transform(queryParameters["from_scenes"] ?? "unknown")
                let departments = (queryParameters["departments"])?.components(separatedBy: ",") ?? []
                let body = MemberInviteLarkSplitBody(sourceScenes: sourceScenes, departments: departments)
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 成员邀请智能路由
            LarkAppLinkSDK.registerHandler(path: SmartMemberInviteBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let queryParameters = applink.url.queryParameters
                let sourceScenes = MemberInviteSourceScenes.transform(queryParameters["from_scenes"] ?? "unknown")
                let departments = (queryParameters["departments"])?.components(separatedBy: ",") ?? []
                let body = SmartMemberInviteBody(sourceScenes: sourceScenes, departments: departments)
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 成员邀请定向邀请页
            LarkAppLinkSDK.registerHandler(path: MemberDirectedInviteBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let queryParameters = applink.url.queryParameters
                let sourceScenes = MemberInviteSourceScenes.transform(queryParameters["from_scenes"] ?? "unknown")
                let isFromInviteSplitPage = ((queryParameters["isFromInviteSplitPage"] ?? "false") == "true")
                let departments = (queryParameters["departments"])?.components(separatedBy: ",") ?? []
                let body = MemberDirectedInviteBody(sourceScenes: sourceScenes,
                                                    isFromInviteSplitPage: isFromInviteSplitPage,
                                                    departments: departments)
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 成员邀请非定向页面
            LarkAppLinkSDK.registerHandler(path: MemberNoDirectionalBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let queryParameters = applink.url.queryParameters
                let sourceScenes = MemberInviteSourceScenes.transform(queryParameters["from_scenes"] ?? "unknown")
                let type = queryParameters["type"] ?? "qr_code"
                let departments = (queryParameters["departments"])?.components(separatedBy: ",") ?? []
                let body = MemberNoDirectionalBody(displayPriority: MemberNoDirectionalBody.DisplayPriority.transform(type),
                                                   sourceScenes: sourceScenes,
                                                   departments: departments)
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 成员邀请团队码
            LarkAppLinkSDK.registerHandler(path: TeamCodeInviteBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let queryParameters = applink.url.queryParameters
                let sourceScenes = MemberInviteSourceScenes.transform(queryParameters["from_scenes"] ?? "unknown")
                let departments = (queryParameters["departments"])?.components(separatedBy: ",") ?? []
                let body = TeamCodeInviteBody(sourceScenes: sourceScenes, departments: departments)
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 外部联系人智能路由(非定向/分流页)
            LarkAppLinkSDK.registerHandler(path: ExternalContactDynamicBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else {
                    return
                }
                let queryParameters = applink.url.queryParameters
                let scenes = ExternalContactsInvitationScenes.transform(queryParameters["scenes"] ?? "contact_external")
                let fromEntrance = ExternalInviteSourceEntrance.transform(queryParameters["from_scenes"] ?? "unknown")
                let body = ExternalContactDynamicBody(scenes: scenes, fromEntrance: fromEntrance)
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 外部联系人非定向邀请页
            LarkAppLinkSDK.registerHandler(path: ExternalContactsInvitationControllerBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let queryParameters = applink.url.queryParameters
                let scenes = ExternalContactsInvitationScenes.transform(queryParameters["scenes"] ?? "contact_external")
                let fromEntrance = ExternalInviteSourceEntrance.transform(queryParameters["from_scenes"] ?? "unknown")
                let body = ExternalContactsInvitationControllerBody(scenes: scenes, fromEntrance: fromEntrance)
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 外部联系人搜索页面(定向)
            LarkAppLinkSDK.registerHandler(path: ContactsSearchBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let queryParameters = applink.url.queryParameters
                let inviteMsg = queryParameters["invite_msg"] ?? ""
                let uniqueId = queryParameters["unique_id"] ?? ""
                let fromEntrance = ExternalInviteSourceEntrance.transform(queryParameters["from_scenes"] ?? "unknown")
                let body = ContactsSearchBody(inviteMsg: inviteMsg, uniqueId: uniqueId, fromEntrance: fromEntrance)
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 统一邀请分流页面
            LarkAppLinkSDK.registerHandler(path: UnifiedInvitationBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let body = UnifiedInvitationBody()
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // 智能决策统一邀请分流页面的路由(统一邀请or添加朋友)
            LarkAppLinkSDK.registerHandler(path: SmartUnifiedInvitationBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let body = SmartUnifiedInvitationBody()
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })

            // B2B 企业关联邀请页的路由
            LarkAppLinkSDK.registerHandler(path: AssociationInviteBody.applinkPattern, handler: {(applink: AppLink) in
                guard let from = applink.context?.from() else { return }
                let body = AssociationInviteBody(source: .urlLink, contactType: .external)
                if Display.pad {
                    Navigator.shared.present( //Global
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .formSheet }
                    )
                } else {
                    Navigator.shared.push(body: body, from: from) //Global
                }
            })
        }

       LarkAppLinkSDK.registerHandler(path: "/client/contact/department/view", handler: { (appLink: AppLink) in
           Self.logger.info("n_action_contact_app_link_department_view_enter")
           let parameters = appLink.url.queryParameters
           guard let departmentID = parameters["departmentID"] else { return }

           if let tenantID = parameters["tenantID"] {
               Self.handleCollaborationDepartmentAppLink(appLink, resolver: resolver, departmentID: departmentID, tenantID: tenantID)
           } else {
               Self.handleDepartmentAppLink(appLink, resolver: resolver, departmentID: departmentID)
           }
       })

       // ldr 页面
       LarkAppLinkSDK.registerHandler(path: LDRGuideBody.applinkPattern, handler: {_ in
           //  兼容老版本applink，不做任何处理，后续可以考虑下掉
       })

       // 勋章列表页面
       LarkAppLinkSDK.registerHandler(path: MedalVCBody.applinkPattern, handler: {(applink: AppLink) in
           guard let from = applink.context?.from() else { return }
           let body = MedalVCBody(userID: "")
           if Display.pad {
               Navigator.shared.present( //Global
                body: body,
                wrap: LkNavigationController.self,
                from: from,
                prepare: { $0.modalPresentationStyle = .formSheet }
               )
           } else {
               Navigator.shared.push(body: body, from: from) //Global
           }
       })
#if !LARK_NO_DEBUG
       LarkAppLinkSDK.registerHandler(path: "/client/picker/demo", handler: { (applink: AppLink) in
           guard let from = applink.context?.from() else { return }
           let nav = UINavigationController(rootViewController: SearchPickerWebController(resolver: container.getCurrentUserResolver()))
           nav.modalPresentationStyle = .fullScreen
           Navigator.shared.present(nav, from: from)
       })
#endif
    }

    public func registUnloginWhitelist(container: Container) {
        UGBrowserBody.pattern
        #if LarkContact_UGOversea
        UGOverseaBrowserBody.pattern
        #endif
    }
#if !LARK_NO_DEBUG
    public func registDebugItem(container: Container) {
        // let resolver = container.synchronize()
        // 安全原因，不要打开此入口，如果有相应临时需求，请本地打开注释编译
        // DebugRegistry.registerDebugItem(WaterMarkDebugItem(waterMarkService: try resolver.resolve(assert: WaterMarkService.self)), to: .debugTool)
        ({ SearchPickerDebugItem(resolver: container.getCurrentUserResolver()) }, SectionType.debugTool)
    }
#endif
    public func registTabRegistry(container: Container) {
        (Tab.contact, { (_: [URLQueryItem]?) -> TabRepresentable in
            let chatApplicationAPI = try? container.resolve(assert: ChatApplicationAPI.self)
            let pushChatApplicationBadege = try? container.userPushCenter.driver(for: PushChatApplicationBadege.self)

            return LarkContactTab(
                chatApplicationAPI: chatApplicationAPI,
                pushChatApplicationBadege: pushChatApplicationBadege)
        })
    }

    @_silgen_name("Lark.OpenChat.Messenger.ContactAssembly")
    public static func providerRegister() {
        ChatBannerModule.register(ChatContactBannerModule.self)
        CryptoChatBannerModule.register(CryptoChatContactBannerModule.self)
    }

    /// 跳转组织架构
    private static func handleDepartmentAppLink(_ appLink: AppLink, resolver: Resolver, departmentID: String) {
        guard let from = appLink.context?.from(),
              let window = Navigator.shared.mainSceneWindow else { return } //Global
        Self.logger.info("n_action_contact_app_link_department: id \(departmentID)")
        var request = RustPB.Contact_V1_GetDepartmentStructureRequest()
        request.departmentID = departmentID

        try? resolver
            .resolve(assert: RustService.self)
            .async(RequestPacket(message: request)) { (responsePacket: ResponsePacket<RustPB.Contact_V1_GetDepartmentStructureResponse>) -> Void in
                DispatchQueue.main.async {
                    do {
                        let department = try responsePacket.result.get().departmentStructure.department
                        let body = DepartmentBody(department: department,
                                                  departmentPath: [department],
                                                  showNameStyle: ShowNameStyle.nameAndAlias,
                                                  showContactsTeamGroup: true,
                                                  isFromContactTab: false,
                                                  subDepartmentsItems: [])
                        var params = NaviParams()
                        params.forcePush = true
                        Navigator.shared.push(body: body, naviParams: params, from: from) //Global
                    } catch {
                        Self.logger.info("n_action_contact_app_link_department_push_error: \(error.localizedDescription)")
                    }
                }
            }
    }

    /// 跳转关联组织
    private static func handleCollaborationDepartmentAppLink(_ appLink: AppLink, resolver: Resolver, departmentID: String, tenantID: String) {
        guard let from = appLink.context?.from(),
              let window = Navigator.shared.mainSceneWindow else { return } //Global
        Self.logger.info("n_action_contact_app_link_collaboration_department: id \(departmentID); tenant id: \(tenantID)")
        var request = RustPB.Contact_V1_GetCollaborationStructureRequest()
        request.tenantID = tenantID
        request.departmentID = departmentID

        try? resolver
            .resolve(assert: RustService.self)
            .async(RequestPacket(message: request)) { (responsePacket: ResponsePacket<RustPB.Contact_V1_GetCollaborationStructureResponse>) -> Void in
                DispatchQueue.main.async {
                    do {
                        let department = try responsePacket.result.get().departmentStructure.department
                        let body = CollaborationDepartmentBody(tenantId: tenantID,
                                                               department: department,
                                                               departmentPath: [department],
                                                               showNameStyle: .nameAndAlias,
                                                               showContactsTeamGroup: true,
                                                               associationContactType: nil)
                        var params = NaviParams()
                        params.forcePush = true
                        Navigator.shared.push(body: body, naviParams: params, from: from) //Global
                    } catch {
                        Self.logger.info("n_action_contact_app_link_collaboration_department_push_error: \(error.localizedDescription)")
                    }
                }
            }
    }

    @_silgen_name("Lark.Feed.FloatMenu.Contact")
    static public func feedFloatMenuRegister() {
        FeedFloatMenuModule.register(ExternalInviteMenuSubModule.self)
        FeedFloatMenuModule.register(MemberInviteMenuSubModule.self)
    }
}

// 整个StructureViewDependency的依赖有些多. 提取出来方便定制不同的默认页
struct StructureViewDependencyConfig {
    var enableGroup: Bool = true
    // TODO: 根据场景
    var enableOwnedGroup: Bool?
    var supportSelectGroup: Bool = false
    var enableBot: Bool = false
    var enableOrganization: Bool = true
    var supportSelectOrganization: Bool = false
    var enableExternal: Bool = true
    var userGroupSceneType: UserGroupSceneType?
    var enableUserGroup: Bool {
        guard userGroupSceneType != nil else { return false }
        return true
    }
    var enableOnCall: Bool = false
    var enableEmailContact: Bool = false
    var enableSharedMailAccount: Bool = false
    var enableEmailAddress: Bool = false
    var tableBackgroundColor: UIColor = UIColor.ud.bgBase
    var showTopBorder: Bool = false
    var isCrossTenantChat: Bool = false
    var enableRelatedOrganizations: Bool = false
    var preferEnterpriseEmail: Bool = false
    var enableSearchFromFilter: Bool = false
}

final class DefaultStructureViewDependencyImpl: StructureViewDependency {
    var enableOwnedGroup: Bool?
    private let r: UserResolver
    private let config: StructureViewDependencyConfig
    weak var picker: ChatterPicker?
    let pickerScene: String?
    var checkMyGroupsSelectDeniedReason: MyGroupsCheckSelectDeniedReason?

    init(r: UserResolver, picker: ChatterPicker, config: StructureViewDependencyConfig = StructureViewDependencyConfig(), checkMyGroupsSelectDeniedReason: MyGroupsCheckSelectDeniedReason? = nil) {
        self.r = r
        self.picker = picker
        self.pickerScene = picker.scene
        self.config = config
        self.enableOwnedGroup = config.enableOwnedGroup
        self.checkMyGroupsSelectDeniedReason = checkMyGroupsSelectDeniedReason
        if let behavior = picker.params.myGroupContactBehavior {
            self.checkMyGroupsSelectDeniedReason = PickerMyGroupsCheckSelectDeniedReasonImp(behavior: behavior)
        }
    }

    var source: ChatterPickerSource?

    var hasGroup: Bool { config.enableGroup }

    var supportSelectGroup: Observable<Bool> {
        if config.supportSelectGroup, let picker = picker {
            return picker.rx.observeWeakly(Bool.self, "includeChat", options: [.initial, .new])
                .compactMap { $0 }
        } else {
            return .just(false)
        }
    }

    var hasBot: Bool {
        guard let appConfigService = try? r.resolve(assert: AppConfigService.self) else { return false }
        return config.enableBot && appConfigService.feature(for: .contactBots).isOn
    }

    var hasOrganization: Observable<Bool> {
        if config.enableOrganization,
           let appConfigService = try? r.resolve(assert: AppConfigService.self),
           appConfigService.feature(for: .contactOrgnization).isOn,
            let passportUserService = passportUserService {
            return passportUserService.state.map { $0.user.type != .simple }.startWith(true)
        } else {
            return .just(false)
        }
    }

    var hasRelatedOrganizations: Observable<Bool> {
        if config.enableRelatedOrganizations, let picker = picker {
            return picker.rx.observeWeakly(Bool.self, "includeOuterTenant", options: [.initial, .new])
            .compactMap { $0 }
        } else {
            return .just(false)
        }
    }

    var supportSelectOrganization: Observable<Bool> {
        if config.supportSelectOrganization, let picker = picker {
            return picker.rx.observeWeakly(Bool.self, "includeDepartment", options: [.initial, .new])
                .compactMap { $0 }
        } else {
            return .just(false)
        }
    }

    var shouldCheckHasSelectOrganizationPermission: Bool {
        if let picker = picker as? AddChatterPicker {
            return picker.includeDepartmentForAddChatter
        }
        return false
    }

    var targetPreview: Bool {
        if let picker = picker {
            return picker.targetPreview
        }
        return false
    }

    var hasExternal: Observable<Bool> {
        if config.enableExternal, let picker = picker {
            return picker.rx.observeWeakly(Bool.self, "includeOuterTenant", options: [.initial, .new])
            .compactMap { $0 }
        } else {
            return .just(false)
        }
    }

    var userGroupSceneType: UserGroupSceneType? {
        return config.userGroupSceneType
    }

    var hasUserGroup: Bool {
        return config.enableUserGroup
    }

    var hasEmailConatact: Bool {
        return config.enableEmailContact
    }

    var hasSharedMailAccount: Bool {
        return config.enableSharedMailAccount
    }

    var hasEmailAddress: Bool {
        return config.enableEmailAddress
    }

    var hasSearchFromFilterRecommend: Bool {
        return config.enableSearchFromFilter
    }

    var preferEnterpriseEmail: Bool {
        return config.preferEnterpriseEmail
    }

    var hasOncall: Bool {
        guard let appConfigService = try? r.resolve(assert: AppConfigService.self) else { return false }
        return config.enableOnCall && appConfigService.feature(for: .contactHelpdesk).isOn
    }

    var tableBackgroundColor: UIColor {
        return config.tableBackgroundColor
    }

    var showTopBorder: Bool {
        return config.showTopBorder
    }

    var selectionSource: SelectionDataSource? { picker }
    var forceSelectedChattersInChatId: String? { picker?.forceSelectedInChatId }

    var contactActionType: RustPB.Basic_V1_Auth_ActionType? {
        if let searchPicker = picker as? SearchPickerView {
            return searchPicker.searchConfig.permissions?.first
        }
        // 没配置全，新权限需要补充
        if isCryptoModel { return .inviteSameCryptoChat }
        if checkInvitePermission {
            if config.isCrossTenantChat {
                return .inviteSameCrossTenantChat
            }
            return .inviteSameChat
        }
        return picker?.permissions.first
    }

    var showContactsTeamGroup: Bool { false }
    var showNameStyle: ShowNameStyle { .justAlias }

    var checkInvitePermission: Bool { picker?.permissions.contains { $0.isCheckInvitePermission() } == true }
    // FIXME: 建群时isCryptoModel可变。虽然变的地方不会用到默认页。但还是用绑定的会更安全一些
    var isCryptoModel: Bool { picker?.permissions.contains { $0.isCrypto() } == true }
    var isCrossTenantChat: Bool { config.isCrossTenantChat }

    var passportUserService: PassportUserService? { try? r.resolve(assert: PassportUserService.self) }
    var serverNTPTimeService: ServerNTPTimeService? { try? r.resolve(assert: ServerNTPTimeService.self) }
    var externalContactsAPI: ExternalContactsAPI? { try? r.resolve(assert: ExternalContactsAPI.self) }
    var userAPI: UserAPI? { try? r.resolve(assert: UserAPI.self) }
    var chatAPI: ChatAPI? { try? r.resolve(assert: ChatAPI.self) }
    var clientAPI: RustService? { try? r.resolve(assert: RustService.self) }
    var namecardAPI: NamecardAPI? { try? r.resolve(assert: NamecardAPI.self) }
    var chatterDriver: Driver<PushChatters>? { try? r.userPushCenter.driver(for: PushChatters.self) }
    var newExternalContactsDriver: Driver<NewPushExternalContactsWithChatterIds>? { try? r.userPushCenter.driver(for: NewPushExternalContactsWithChatterIds.self) }
    var externalContactsDriver: Driver<PushExternalContactsWithChatterIds>? { try? r.userPushCenter.driver(for: PushExternalContactsWithChatterIds.self) }

    var mailGroupId: Int?
    var mailGroupRole: MailGroupRole?
    var mailAccountId: String?

    // from filter recommendation
    var fromFilterRecommendList: [SearchResultType] = []
    var defaultOption: [Option] = []
}
