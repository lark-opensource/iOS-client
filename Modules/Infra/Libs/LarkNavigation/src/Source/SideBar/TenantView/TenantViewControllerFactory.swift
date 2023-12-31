//
//  TenantViewControllerFactory.swift
//  LarkNavigation
//
//  Created by Supeng on 2021/6/30.
//

import UIKit
import Foundation
import LarkAccountInterface
import LarkContainer
import EENavigator
import LKCommonsTracker
import Homeric
import LarkSetting
import RxSwift
import LKCommonsLogging
import LarkLeanMode
import SuiteAppConfig
import UniverseDesignToast
import LarkTab

class TenantViewControllerDependencyImpl: TenantViewControllerDependency, UserResolverWrapper {
    internal var userResolver: UserResolver

    static private let logger = Logger.log(TenantViewControllerDependencyImpl.self, category: "Navgation.SideBar")
    private var passportService: PassportService
    private var switchAccountService: SwitchAccountService
    private var leanModeService: LeanModeService
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.passportService = try self.userResolver.resolve(assert: PassportService.self)
        self.switchAccountService = try self.userResolver.resolve(assert: SwitchAccountService.self)
        self.leanModeService = try self.userResolver.resolve(assert: LeanModeService.self)
    }

    private var showAdd: Bool {
        // 某些 KA 不允许账户同登，此时屏蔽加入团队入口
        let isExcludeLogin = passportService.foregroundUser?.isExcludeLogin ?? false
        let fg = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        let fgValue = fg?.staticFeatureGatingValue(with: "lark.tenant.penetration.enable") ?? false
        let fgValue1 = fg?.staticFeatureGatingValue(with: "suite_join_function") ?? false
        return fgValue && fgValue1 && !isExcludeLogin
    }

    var currentTenants: [TenantModel] {
        Self.convertUsersToTenantModels(badges: [:],
                                        users: passportService.userList,
                                        showAdd: showAdd)
    }

    var currentTenantsObservable: Observable<[TenantModel]> {
        let badgeDriver = switchAccountService.accountsBadgesDriver.asObservable()
        let tenantsObservable: Observable<[User]>
        let fg = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        let canTransfer = fg?.staticFeatureGatingValue(with: "suite_transfer_function") ?? false
        if canTransfer {
            tenantsObservable = passportService.menuUserListObservable
        } else {
            tenantsObservable = passportService.state.map({ state in
                if let user = state.user {
                    return [user]
                } else {
                    return []
                }
            })
        }

        return Observable.combineLatest(badgeDriver, tenantsObservable)
            .observeOn(MainScheduler.instance)
            .map({ (badges, users) in
                Self.convertUsersToTenantModels(badges: badges,
                                                users: users,
                                                showAdd: self.showAdd)
            })
    }

    func changeTenant(from: Tenant, to: Tenant, vc: UIViewController) {
        Self.logger.info("Try to change tenant from \(from.id) to \(to.id)")

        // lean mode not allowed to switch account
        if AppConfigManager.shared.leanModeIsOn {
            guard let from = Navigator.shared.mainSceneWindow else {
                let description = "no main scene for switchAccount"
                assertionFailure(description)
                Self.logger.error(description)
                return
            }
            UDToast.showTips(with: BundleI18n.LarkNavigation.Lark_Security_LeanModeFeatureNotAvailableGeneralMessage, on: from)
            return
        }

        (vc.parent as? SideBarAbility)?.hideSideBar(animate: false) {
            self.passportService.switchTo(userID: to.id)
            Self.logger.info("Changed tenant from \(from.id) to \(to.id)")

            let currentUserList = self.passportService.userList
            guard let fromUser = currentUserList.first(where: { $0.userID == from.id}),
                  let toUser = currentUserList.first(where: { $0.userID == to.id}) else {
                return
            }
            let tenantID = fromUser.userID
            let targetTenantID = toUser.userID
            let targetSessionType = { () -> String in
                switch toUser.userStatus {
                case .invalid:
                    return "invalid"
                case .new:
                    return "new_account"
                case .normal:
                    return "have_session"
                case .restricted:
                    return "no_permission_account"
                }
            }()

            var belongedTab = "unknown"
            if let mainTabbar = UIApplication.shared.windows.compactMap({ (window) -> MainTabbarController? in
                UIViewController.topMost(of: window.rootViewController, checkSupport: false)?
                                .tabBarController as? MainTabbarController
            }).first {
                switch mainTabbar.selectedTab {
                case .feed:         belongedTab = "im"
                case .calendar:     belongedTab = "cal"
                case .appCenter:    belongedTab = "platform"
                case .doc:          belongedTab = "doc"
                case .mail:         belongedTab = "email"
                case .contact:      belongedTab = "contact"
                case .byteview:     belongedTab = "vc"
                case .todo:         belongedTab = "todo"
                case .moment:       belongedTab = "moments"
                case .wiki:         belongedTab = "wiki"
                default:
                    break
                }
            }

            Tracker.post(TeaEvent(Homeric.NAVIGATION_TENANT_CLICK,
                                  params: ["click": "tenant",
                                           "tenantID": tenantID,
                                           "targetTenantID": targetTenantID,
                                           "tenant_session_type": targetSessionType,
                                           "target": "none",
                                           "belonged_tab": belongedTab]))
        }
    }

    func addAccount(vc: UIViewController, from: UIView) {
        guard let nav = Navigator.shared.navigation else { return }
        from.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { from.isUserInteractionEnabled = true})

        func pushToTeamConversion() {
            passportService.pushToTeamConversion(fromNavigation: nav, trackPath: "sidebar_icon")

            Tracker.post(TeaEvent(Homeric.NAVIGATION_TENANT_CLICK,
                                  params: ["click": "add_tenant",
                                           "target": "onboarding_team_join_create_upgrade_view"]))
        }

        if let sideBarVC = vc.parent as? SideBarAbility {
            sideBarVC.hideSideBar(animate: true) { pushToTeamConversion() }
        } else {
            pushToTeamConversion()
        }
    }

    private static func convertUsersToTenantModels(badges: AccountsBadges, users: [User], showAdd: Bool) -> [TenantModel] {
        var models: [TenantModel] = users.enumerated().map { (index, item) in
            TenantModel.tenant(Tenant(id: item.userID,
                                      showIndicator: index == 0,
                                      badge: { () -> Tenant.TenantItemBadge in
                                        if case .normal = item.userStatus, let badgeNumber = badges[item.userID], badgeNumber > 0 {
                                            return .number(Int(badgeNumber))
                                        } else if case .new = item.userStatus {
                                            return .new
                                        } else {
                                            return .none
                                        }
                                      }(),
                                      name: item.tenant.localizedTenantName,
                                      avatarKey: item.tenant.iconURL,
                                      showExclamationMark: item.userStatus == .restricted || item.userStatus == .invalid,
                                      showShadow: item.userStatus == .invalid))
        }

        if showAdd {
            models.append(.add)
        }
        return models
    }

    var leanmodeIsOpen: Bool {
        return self.leanModeService.currentLeanModeStatusAndAuthority.canUseLeanMode
    }

    func switchToLeanMode(vc: UIViewController) {
        (vc.parent as? SideBarAbility)?.hideSideBar(animate: false) {
            self.leanModeService.switchLeanModeStatus()
        }
    }
}

enum TenantViewControllerFactory {
    static func createTenantVC(userResolver: UserResolver) throws -> TenantViewController {
        TenantViewController(dependency: try TenantViewControllerDependencyImpl(userResolver: userResolver))
    }
}
