//
//  RustPluginAssembly.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/5.
//

import Foundation
import Swinject
import LarkContainer
import LKCommonsLogging
import LarkAppLinkSDK
import LarkAccountInterface
import EENavigator
import LarkShareToken
import LarkRustClient
import LarkUIKit
import RxSwift
import UniverseDesignToast
import LarkAlertController
import LarkAssembler
import UIKit
import LarkSetting

class RustPluginAssembly: LarkAssemblyInterface {
    
    static let logger = Logger.plog(RustPluginAssembly.self, category: "SuiteLogin.RustPluginAssembly")
    
    @Provider var launcher: Launcher
    @Provider var api: LoginAPI
    @Provider var tokenManager: PassportTokenManager
    @Provider var switchUserService: NewSwitchUserService
    @Provider var loginService: V3LoginService
    @Provider var passportService: PassportService
    @Provider var idpWebViewService: IDPWebViewServiceProtocol

    //不通过 assembly 注册，AccountAssemblyTask 会执行注册调用
    func assemblePushHandler(container: Container) {
        if PassportUserScope.enableUserScopeTransitionRust {
            // 用户态适配开启，用户态 push 由 registRustPushHandlerInUserSpace 方法承载，这里注册全局 push
            if let globalService = try? container.resolve(assert: GlobalRustService.self) {
                Self.logger.info("n_action_rust_plugin: scoped push handler")
                let handlerInfo = containerPushHandlerInfo(container: container)
                globalService.registerPushHandler(factories: handlerInfo)
            } else {
                #if DEBUG || ALPHA
                    fatalError("[Passport] RustPluginAssembly fatal: cannot get global service!")
                #else
                    Self.logger.warn("n_action_rust_plugin: cannot resolve global rust service")
                #endif
            }
        } else {
            // 用户态适配关闭，使用原实现
            Self.logger.info("n_action_rust_plugin: container push handler")
            let handlerInfo = pushHandlerInfo(container: container)
            PushHandlerRegistry.shared.register(pushHandlers: handlerInfo)
        }
    }
    
    // MARK: - New Assembly protocol
    // (用户态关闭) 原有 Push Handler 注册方式
    private func pushHandlerInfo(container: Container) -> [Command: RustPushHandlerFactory] {
        return [
            .pushUserListUpdate: {
                return UserListUpdatePushHandler(pushCenter: container.pushCenter)
            }, // 用户列表更新推送
            .pushDeviceOnlineStatus: {
                DeviceUpdatePushHandler()
            }, // 在线设备更新
            .pushValidDevices: {
                ValidDevicesUpdatePushHandler()
            }, // 有效设备更新
            .pushSessionValidating: {
                CheckSessionPushHandler()
            }, // session 失效
            .pushUserLogout: {
                PipelineLongTimeNoLoginPushHandler()
            }, // Rust 长时间未登录更新
            .pushPackAndUploadLogProgress: {
                UploadLogProgressPushHandler()
            } // 打包主动上传日志
        ]
    }

    // (用户态开启) 注册全局 Push Handler
    private func containerPushHandlerInfo(container: Container) -> [Command: RustPushHandlerFactory] {
        return [
            .pushSessionValidating: {
                CheckSessionPushHandler()
            }, // session 失效
            .pushUserLogout: {
                PipelineLongTimeNoLoginPushHandler()
            }, // Rust 长时间未登录更新
            .pushPackAndUploadLogProgress: {
                UploadLogProgressPushHandler()
            } // 打包主动上传日志
        ]
    }

    // (用户态开启) 注册用户态 Push Handler
    // 由于 build 限制，这里无法增加灰度开关，灰度逻辑会包含在具体 handler 的 process 方法中
    func registRustPushHandlerInUserSpace(container: Container) {
        // 用户列表更新推送
        (Command.pushUserListUpdate, ScopedUserListUpdatePushHandler.init(resolver:))
        // 在线设备更新
        (Command.pushDeviceOnlineStatus, ScopedDeviceUpdatePushHandler.init(resolver:))
        // 有效设备更新
        (Command.pushValidDevices, ScopedValidDevicesUpdatePushHandler.init(resolver:))
    }

    // 某些 KA 不允许多账号同时登录，此时弹框提示用户 https://bytedance.feishu.cn/docs/doccnfLmKuFekUh9p7kbH3XvPMb
    private func alertForExclusiveLoginIfNeeded(from: UIViewController?) -> Bool {
        if let user = launcher.foregroundUser, user.isExcludeLogin { // user:current
            if let from = from {
                let alert = LarkAlertController()
                alert.setContent(text: I18N.Lark_Passport_MultipleAccount_ManualLogoutPopup(user.tenant.tenantName))
                alert.addSecondaryButton(text: I18N.Lark_Passport_MultipleAccount_ManualLogoutPopup_GotButton)
                from.present(alert, animated: true, completion: nil)
                
                Self.logger.info("Alert for exclusive login")
            }
            return true
        }
        
        Self.logger.info("Non-exclusive login")
        return false
    }
    
    public func registUnloginWhitelist(container: Swinject.Container) {
        "//applink.feishu.cn/client/passport/sso_login"
        "//applink.larksuite.com/client/passport/sso_login"
        "//applink.feishu.cn/client/passport/join_team"
        "//applink.larksuite.com/client/passport/join_team"
        "//applink.feishu.cn/client/passport/recover_account"
        "//applink.larksuite.com/client/passport/recover_account"
        "//applink.feishu.cn/client/passport/sso"
        "//applink.larksuite.com/client/passport/sso"
        "//applink.feishu.cn/client/passport/idp/landing"
    }
    
    public func registLarkAppLink(container: Swinject.Container) {
        Self.logger.info("account applink assemble")
        LarkAppLinkSDK.registerHandler(path: "/client/tenant/switch", handler: { (applink: AppLink) in
            guard applink.from != .app else { return }
            guard applink.context?.from() != nil else {
                Self.logger.errorWithAssertion("no from for tenant switch")
                return
            }
            let queryParameters = applink.url.queryParameters
            if let switchTo = queryParameters["userId"] {
                self.switchUserService.switchTo(userID: switchTo, credentialID: queryParameters["credential_id"], complete: nil, context: UniContextCreator.create(.applink))
            }
        })

        LarkAppLinkSDK.registerHandler(path: "/client/passport/sso_login", handler: { (applink: AppLink) in
            let context = UniContextCreator.create(.authorization)
            let queryParameters = applink.url.queryParameters
            if let ssoDomain = queryParameters["sso_domain"],
               let tenantName = queryParameters["tenant_name"] {
                Self.logger.info("app link handle sso login")
                self.launcher.handleSSOLogin(
                    ssoDomain,
                    tenantName: tenantName,
                    context: context
                )
            } else {
                Self.logger.error("app link handle sso login failed invalid params", additionalData: queryParameters)
            }
        })

        let joinTeamPath = "/client/passport/join_team"
        let disposeBag = DisposeBag()
        LarkAppLinkSDK.registerHandler(path: joinTeamPath, handler: { (applink: AppLink) in
            guard let flowKey = applink.url.queryParameters["X-Flow-Key"], !flowKey.isEmpty else {
                Self.logger.error("n_action_x_flow_key_is_empty", body:"joinTeamPath: \(joinTeamPath)")
                return
            }
            
            Self.logger.info("n_action_applink_join_team", body: "joinTeamPath: \(joinTeamPath), flowKey: \(flowKey)")

            if let from = applink.context?.from(), let fromVC = from.fromViewController {
                if self.alertForExclusiveLoginIfNeeded(from: fromVC) {
                    Self.logger.info("Skip app link for exclusive login for \(joinTeamPath)")
                    return
                }
            } else {
                Self.logger.error("Failed to get from VC for \(joinTeamPath)")
            }
            
            // accounts.feishu-boe.cn
            //https://applink.feishu.cn/client/passport/join_team?X-Flow-Key=8acbeacb-c243-4de0-8b2e-438ec1d769f4
            let context = UniContextCreator.create(.unknown)
            self.tokenManager.flowKey = flowKey
            func handler(vc: UIViewController?) {
                if let vc = vc {
                    let nav = LoginNaviController(rootViewController: vc)
                    nav.modalPresentationStyle = .formSheet
                    let navigation = Navigator.shared.navigation // user:checked (navigator)
                    if let presentingVC = navigation?.presentingViewController {
                        presentingVC.dismiss(animated: true, completion: nil)
                    }
                    Navigator.shared.navigation?.present(nav, animated: true, completion: nil) // user:checked (navigator)
                }
            }

            self.api.fetchRegisterDiscovery().post(nil, vcHandler: Display.pad ? handler(vc:) : nil, context: context).subscribe( onNext: {
                Self.logger.info("n_action_discovery_succ")
            }, onError: { error in
                Self.logger.error("n_action_discovery_error", error: error)
            }).disposed(by: disposeBag)
        })

        let teamConversionPath = "/client/tenant/team_conversion_selection"
        LarkAppLinkSDK.registerHandler(path: teamConversionPath, handler: { (applink: AppLink) in
            Self.logger.info("app link for \(teamConversionPath)")
            
            if let from = applink.context?.from(), let fromVC = from.fromViewController {
                if self.alertForExclusiveLoginIfNeeded(from: fromVC) {
                    Self.logger.info("Skip app link for exclusive login for \(teamConversionPath)")
                    return
                }
            } else {
                Self.logger.error("Failed to get from VC for \(teamConversionPath)")
            }
            
            if let navi = Navigator.shared.navigation { // user:checked (navigator)
                Self.logger.info("app link team conversion selection")
                self.passportService.pushToTeamConversion(
                    fromNavigation: navi,
                    trackPath: applink.teamConversionSource
                )
            } else {
                Self.logger.errorWithAssertion("no navigator app link team conversion selection")
            }
        })

        let tenantJoinTeamPath = "/client/tenant/join_team"
        LarkAppLinkSDK.registerHandler(path: tenantJoinTeamPath, handler: { (applink: AppLink) in
            Self.logger.info("app link for \(tenantJoinTeamPath)")
            
            if let from = applink.context?.from(), let fromVC = from.fromViewController {
                if self.alertForExclusiveLoginIfNeeded(from: fromVC) {
                    Self.logger.info("Skip app link for exclusive login for \(tenantJoinTeamPath)")
                    return
                }
                
                UDToast.showDefaultLoading(on: fromVC.view)
                Self.logger.info("app link join_team")
                let userCenterAPI = UserCenterAPI()
                let context = UniContextCreator.create(.unknown)
                _ = userCenterAPI.fetchUserCenter().subscribe { data in
                    let step = PassportStep.operationCenter
                    let userCenter = step.pageInfo(with: data.stepData.stepInfo) as? V4UserOperationCenterInfo
                    guard let userCenterInfo = userCenter, let joinTenantStep = userCenterInfo.joinTenantStep else {
                        UDToast.removeToast(on: fromVC.view)
                        Self.logger.error("no join team data in user center data.")
                        return
                    }
                    let vm = UserOperationCenterViewModel(step: PassportStep.operationCenter.rawValue, userCenterInfo: userCenterInfo, context: context)
                    _ = vm.toNextPage(stepData: joinTenantStep).subscribe(onNext:  {
                        UDToast.removeToast(on: fromVC.view)
                        Self.logger.info("push to join team page success.")
                    })
                } onError: { err in
                    UDToast.removeToast(on: fromVC.view)
                    Self.logger.error("fetch user center data error: \(err)")
                }
            } else {
                Self.logger.error("no navigator join_team selection")
            }
        })

        let upgradeTeamPath = "/client/tenant/upgrade_or_create_team"
        LarkAppLinkSDK.registerHandler(path: upgradeTeamPath, handler: { (applink: AppLink) in
            Self.logger.info("app link for \(upgradeTeamPath)")
            
            if let from = applink.context?.from(), let fromVC = from.fromViewController {
                if self.alertForExclusiveLoginIfNeeded(from: fromVC) {
                    Self.logger.info("Skip app link for exclusive login for \(upgradeTeamPath)")
                    return
                }
                
                UDToast.showDefaultLoading(on: fromVC.view)
                Self.logger.info("app link upgrade or create team")
                let userCenterAPI = UserCenterAPI()
                let context = UniContextCreator.create(.unknown)
                _ = userCenterAPI.fetchUserCenter().subscribe { data in
                    let step = PassportStep.operationCenter
                    let userCenter = step.pageInfo(with: data.stepData.stepInfo) as? V4UserOperationCenterInfo
                    guard let userCenterInfo = userCenter, let createTenantStep = userCenterInfo.createTenantStep else {
                        Self.logger.error("no upgrade or create team data in user center data.")
                        UDToast.removeToast(on: fromVC.view)
                        return
                    }
                    let vm = UserOperationCenterViewModel(step: PassportStep.operationCenter.rawValue, userCenterInfo: userCenterInfo, context: context)
                    _ = vm.toNextPage(stepData: createTenantStep).subscribe(onNext:  {
                        Self.logger.info("push to upgrade or create team page success.")
                        UDToast.removeToast(on: fromVC.view)
                    })
                } onError: { err in
                    Self.logger.error("fetch user center data error: \(err)")
                    UDToast.removeToast(on: fromVC.view)
                }
            } else {
                Self.logger.error("no navigator for upgrade or create team page")
            }
        })

        let personalUsePath = "/client/tenant/personal_use"
        LarkAppLinkSDK.registerHandler(path: personalUsePath, handler: { (applink: AppLink) in
            Self.logger.info("app link for \(personalUsePath)")
            
            if let from = applink.context?.from(), let fromVC = from.fromViewController {
                if self.alertForExclusiveLoginIfNeeded(from: fromVC) {
                    Self.logger.info("Skip app link for exclusive login for \(personalUsePath)")
                    return
                }
                
                UDToast.showDefaultLoading(on: fromVC.view)
                Self.logger.info("app link personal use")
                let userCenterAPI = UserCenterAPI()
                let context = UniContextCreator.create(.unknown)
                _ = userCenterAPI.fetchUserCenter().subscribe { data in
                    let step = PassportStep.operationCenter
                    let userCenter = step.pageInfo(with: data.stepData.stepInfo) as? V4UserOperationCenterInfo
                    guard let userCenterInfo = userCenter, let personalUseStep = userCenterInfo.personalUseStep else {
                        Self.logger.error("no personal use data in user center data.")
                        UDToast.removeToast(on: fromVC.view)
                        return
                    }
                    let vm = UserOperationCenterViewModel(step: PassportStep.operationCenter.rawValue, userCenterInfo: userCenterInfo, context: context)
                    _ = vm.toNextPage(stepData: personalUseStep).subscribe(onNext:  {
                        Self.logger.info("push to personal use page success.")
                        UDToast.removeToast(on: fromVC.view)
                    })
                } onError: { err in
                    Self.logger.error("fetch user center data error: \(err)")
                    UDToast.removeToast(on: fromVC.view)
                }
            } else {
                Self.logger.error("no navigator for personal use")
            }
        })

        LarkAppLinkSDK.registerHandler(path: "/client/passport/account_management") { (applink) in
            guard let from = applink.context?.from(),
                  let fromVC = from.fromViewController else {
                      Self.logger.errorWithAssertion("no from for account_management")
                      return
                  }
            Self.logger.info("app link account management")
            self.loginService.openAccountSecurityCenter(for: .accountManagement, from: fromVC)
        }

        LarkAppLinkSDK.registerHandler(path: "/client/passport/password") { (applink) in
            guard let from = applink.context?.from(),
                  let fromVC = from.fromViewController else {
                      Self.logger.errorWithAssertion("cannot find suitable vc to continue")
                      return
                  }

            Self.logger.info("app link password management")
            PassportBusinessContextService.shared.triggerChange(.accountManage)
            self.loginService.openAccountSecurityCenter(for: .accountPasswordSetting, from: fromVC)
        }

        LarkAppLinkSDK.registerHandler(path: "/client/passport/recover_account") { (appLink) in

            Self.logger.info("n_action_handle_recover_account_applink_start")

            Self.logger.info("n_action_handle_recover_account_applink_params_validation")
            guard let token = appLink.url.queryParameters["appeal_token"] else {
                Self.logger.errorWithAssertion("n_action_handle_recover_account_applink_params_validation_fail", additionalData: ["reason": "token null"])
                return
            }
            let type = appLink.url.queryParameters["type"]
            Self.logger.info("n_action_retrieve_applink_req")
            self.launcher.retrieveAppLink(token: token, type: type)
        }

        LarkAppLinkSDK.registerHandler(path: "/client/passport/sso") { (appLink) in
            guard let from = appLink.context?.from(),
                  let fromVC = from.fromViewController else {
                      Self.logger.errorWithAssertion("cannot find suitable vc to continue")
                      return
                  }

            guard let tokenStringInBase64 = appLink.url.queryParameters["token"] else {
                Self.logger.errorWithAssertion("no token params for /client/passport/sso")
                return
            }
            let context = UniContextCreator.create(.authorization)
            self.loginService.handleSSOLoginCallback(tokenStringInBase64, fromVC: fromVC, context: context)
        }
        
        let switchUserPath = "/client/passport/switch_user"
        LarkAppLinkSDK.registerHandler(path: switchUserPath) { (appLink) in
            Self.logger.info("n_action_applink_switch_user")
            if self.alertForExclusiveLoginIfNeeded(from: appLink.context?.from()?.fromViewController) {
                Self.logger.info("Skip app link for exclusive login for \(switchUserPath)")
                return
            }
         
            guard let userID = appLink.url.queryParameters["user_id"], !userID.isEmpty else {
                Self.logger.error("n_action_userId_is_empty",body: "switchUserPath: \(switchUserPath)")
                return
            }
            
            guard let flowKey = appLink.url.queryParameters["X-Flow-Key"], !flowKey.isEmpty else {
                Self.logger.error("n_action_x_flow_key_is_empty", body: "switchUserPath: \(switchUserPath)")
                return
            }
            
            guard let flowType = appLink.url.queryParameters["flow_type"], !flowType.isEmpty else {
                Self.logger.error("n_action_flow_type_is_empty", body: "switchUserPath: \(switchUserPath)")
                return
            }

            let context = UniContextCreator.create(.applink)
            self.tokenManager.flowKey = flowKey
            let serverInfo = PlaceholderServerInfo()
            serverInfo.flowType = flowType
            //接口请求域名改成web端传递的值, 避免跨unit加入租户因为flowKey找不到导致接口请求失败
            //https://meego.feishu.cn/larksuite/story/detail/14031489
            let origin = appLink.url.queryParameters["origin"]?.removingPercentEncoding
            //兜底包域名
            serverInfo.usePackageDomain = true
            self.loginService.handleInAppInviteLogin(customDomain:origin, serverInfo: serverInfo, userID: userID, fromVC: appLink.context?.from()?.fromViewController, context: context)
        }
        
        let accountCenterPath = "client/passport/account_center"
        LarkAppLinkSDK.registerHandler(path: accountCenterPath) { [weak self] (appLink) in
            Self.logger.info("n_action_applink_account_center")
            
            guard let from = appLink.context?.from(),
                  let fromVC = from.fromViewController else {
                      Self.logger.errorWithAssertion("no from for account_management")
                      return
                  }
            
            let queries = appLink.url.queryParameters
            var webURLKey: WebUrlKey = .accountCenterHomePage
            if let path = queries["path"], let key = WebUrlKey(rawValue: path) {
                webURLKey = key
            }
            
            Self.logger.info("n_action_applink_account_center", body: "open with key: \(webURLKey.rawValue)")
            self?.launcher.loginService.openAccountSecurityCenter(for: webURLKey, from: fromVC)
        }

        LarkAppLinkSDK.registerHandler(path: "/client/passport/idp/landing") { appLink in
            Self.logger.info("n_action_applink_idp_landing")
            self.idpWebViewService.finishedLogin(appLink.url.queryParameters)
        }

        // 日志上传
        let enableUpload = GlobalFeatureGatingManager.shared.globalFeatureValue(of: .init(.make(golbalKeyLiteral: "passport_no_user_log_upload")))
        if enableUpload {
            LarkAppLinkSDK.registerHandler(path: "/client/logifier/retrieval/upload") { appLink in
                Self.logger.info("n_action_applink_logifier_upload_page")
                let params = appLink.url.queryParameters
                guard let token = params["token"] else {
                    Self.logger.info("n_action_applink_logifier_upload_page: no token")
                    return
                }
                Self.logger.info("n_action_applink_logifier_upload_page token: \(token)")
                FetchClientLogHelper.uploadClientLog(prefilledToken: token)
            }
        }

        // iPad 授权免登
        // https://bytedance.feishu.cn/docx/doxcneveCZpLL4s6xywwhGfIWQc
        if UIDevice.current.userInterfaceIdiom == .pad {
            let authAutoLoginPath = "client/passport/free_login"
            LarkAppLinkSDK.registerHandler(path: authAutoLoginPath) { appLink in
                Self.logger.info("n_action_applink_auth_auto_login")
                let startDate = Date()
                let context = UniContextCreator.create(.authorization)
                PassportMonitor.flush(PassportMonitorMetaAuthorization.authorizationEnter, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "applink"], context: context)
                PassportMonitor.flush(PassportMonitorMetaAuthorization.startAuthorizationScan, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "applink"], context: context)

                guard let from = appLink.context?.from(),
                      let fromVC = from.fromViewController else {
                          Self.logger.errorWithAssertion("no from for auth_auto_login")
                    PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "applink"], context: context).setErrorCode("-1").setErrorMessage("auth_auto_login without from field.").setResultTypeFail().flush()
                    
                          return
                      }

                let params = appLink.url.queryParameters
                guard let token = params["token"] ?? params["qr_code"],
                      let bundleID = params["bundle_id"],
                      let schema = params["schema"] else {
                          Self.logger.errorWithAssertion("No token or bundle Id")
                    PassportMonitor.monitor(PassportMonitorMetaAuthorization.authorizationScanResult, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.authorizationType: "applink"], context: context).setErrorCode("-2").setErrorMessage("No token or bundleId or scheme.").setResultTypeFail().flush()
                    
                          return
                      }

                // 首次启动或登录后立即调起 需要等待首页加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    let resolver = container.getCurrentUserResolver() // user:current
                    let vc = CheckAuthTokenViewController(
                        vm: SSOBaseViewModel(resolver: resolver, info: .authAutoLogin(token, bundleID, schema), startDate: startDate), resolver:  container.getCurrentUserResolver() // user:current
                    )
                    vc.modalPresentationStyle = .overCurrentContext

                    Self.logger.info("n_action_applink_auth_auto_login_start")
                    Navigator.shared.present(vc, from: fromVC) // user:checked (navigator)
                }
            }
        }
        
        ShareTokenManager.shared.registerHandler(source: "ClientTenantTeamCodeHandler") { (params) in
            Self.logger.info("app link share token join team")
            self.launcher.tokenJoinTeam(params: params)
        }
    }
}

extension AppLink {
    var teamConversionSource: String? {
        self.url.queryParameters["source"]
    }
    var personalUseTitle: String? {
        self.url.queryParameters["title"]
    }
    var personalUseDescription: String? {
        self.url.queryParameters["description"]
    }
}
