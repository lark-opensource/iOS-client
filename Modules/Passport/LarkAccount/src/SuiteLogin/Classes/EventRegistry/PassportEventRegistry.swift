//
//  PassportEventRegistry.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/8/23.
//

import Foundation
import LarkPerf
import RxSwift
import LKCommonsLogging
import LarkContainer
import EENavigator
import LarkEnv
import LarkAlertController
import Homeric
import LarkUIKit
import RoundedHUD
import ECOProbeMeta
import UIKit
import UniverseDesignToast
import LarkAccountInterface

class EventBusNavigationService {
    static let logger = Logger.plog(EventBusNavigationService.self, category: "SuiteLogin.EventBusNavigationService")

    func getNavigation(for context: PassportBusinessContext) -> UINavigationController? {
        if let navi = PassportNavigator.topMostVC?.nearestNavigation {
            Self.logger.info("valid navigation controller: \(navi) for context: \(context) from top most navigation")
            return navi
        } else if let window = PassportNavigator.keyWindow,
                  let rootVC = window.rootViewController,
                  let navi = rootVC.nearestNavigation {
            Self.logger.info("valid navigation controller: \(navi) for context: \(context) from navigator")
            return navi
        } else {
            Self.logger.error("no valid navigation controller for context: \(context)")
            return nil
        }
    }
}

class PassportEventRegistry {
    static let logger = Logger.plog(PassportEventRegistry.self, category: "SuiteLogin.PassportEventRegistry")

    var eventBus: LoginPassportEventBus { LoginPassportEventBus.shared }
    let eventBusNavigationService: EventBusNavigationService = EventBusNavigationService()

    @Provider var idpService: IDPServiceProtocol
    @Provider var envManager: EnvironmentInterface
    @Provider var newSwitchUserService: NewSwitchUserService
    @Provider var loginService: V3LoginService

    @Provider var recoverAccountApi: RecoverAccountAPI // user:checked (global-resolve)
    @Provider var loginAPI: LoginAPI
    @Provider var bioAuthService: BioAuthService
    @Provider var idpWebViewService: IDPWebViewServiceProtocol

    var currentBusinessContext: PassportBusinessContext {
        return PassportBusinessContextService.shared.currentContext
    }

    let disposeBag = DisposeBag()

    func currentNavigation() -> UINavigationController? {
        let nav = self.eventBusNavigationService.getNavigation(for: self.currentBusinessContext)
        nav?.navigationBar.isTranslucent = false
        nav?.navigationBar.barTintColor = UIColor.ud.N00
        self.eventBus.registerMiddleware( EventBusCheckPopMiddleware(navigation: nav) )
        return nav
    }

    func showVC(_ vc: UIViewController, vcHandler: EventBusVCHandler?, animated: Bool = true) {
        if let vcHandler = vcHandler {
            vcHandler(vc)
        } else if let navigation = self.currentNavigation() {
            func push(_ viewController: UIViewController, into navigationController: UINavigationController) {
                navigation.pushViewController(vc, animated: animated)
                
                // 在 push 的时候清理 vc (而不是 pop 的时候），用来兼容 navigationController 不是 LoginNaviController 的情况
                // （如端内登录是用的是主端的 RootNavigationController： https://meego.feishu.cn/larksuite/issue/detail/3474060?parentUrl=%2Flarksuite%2FissueView%2Fj1ZvyBxbrF）
                // 某些VC（如 V4LoginVerifyViewController 会在 push 之后修改 needSkipWhilePop 的值，因此延迟到下一个 runloop 执行
                DispatchQueue.main.async {
                    var delayedCloseAllStartPoint = false
                    let vcs = navigationController.viewControllers.filter { (vc) -> Bool in
                        var shouldKeepVC = true

                        if let checkNeedPopVC = vc as? NeedSkipWhilePopProtocol, vc != viewController {
                            shouldKeepVC = !checkNeedPopVC.needSkipWhilePop
                        }

                        // 被 skip 的 vc 可能 closeAllStartPoint 为 true
                        // 这个时候将标记位移到下一个保留的页面
                        if !shouldKeepVC {
                            if vc.closeAllStartPoint {
                                delayedCloseAllStartPoint = true
                            }
                        } else {
                            if delayedCloseAllStartPoint {
                                vc.closeAllStartPoint = true
                                delayedCloseAllStartPoint = false
                            }
                        }

                        return shouldKeepVC
                    }
                    
                    if vcs.count != navigationController.viewControllers.count {
                        navigationController.viewControllers = vcs
                    }
                }
            }
            
            if let presentedViewController = navigation.presentedViewController {
                presentedViewController.dismiss(animated: true, completion: {
                    push(vc, into: navigation)
                })
            } else {
                push(vc, into: navigation)
            }
        } else {
            Self.logger.debug("no currentNavigation for currentContext: \(self.currentBusinessContext)")
            let navigation = LoginNaviController(rootViewController: vc)
            navigation.modalPresentationStyle = .fullScreen

            if let mainSceneTopMost = PassportNavigator.topMostVC {
                mainSceneTopMost.present(navigation, animated: animated, completion: nil)
            } else {
                Self.logger.errorWithAssertion("no main scene top most for showVC")
            }
        }
    }

    // func present(_ vc: UIViewController, animated: Bool = true) {
    //     guard let topVC = PassportNavigator.topMostVC else {
    //         Self.logger.errorWithAssertion("no topVC to present vc")
    //         return
    //     }
    //     topVC.present(vc, animated: animated, completion: nil)
    // }

    private func showLoadingHUD(with text: String = BundleI18n.LarkAccount.Lark_Legacy_BaseUiLoading) -> UDToast? {
        guard let window = PassportNavigator.keyWindow else {
            return nil
        }

        return UDToast.showLoading(with: text,
                                   on: window,
                                   disableUserInteraction: true)
    }

    func setupUserEventRegister(eventBus: ScopedLoginEventBus) {
        eventBus.register(
            step: .qrLoginConfirm,
            handler: ScopedServerInfoEventBusHandler<QRCodeLoginConfirmInfo>(handleWork: { args in
                Self.logger.info("n_action_qr_login_confirm: enter")

                let resolver = args.userResolver
                let uid = resolver.userID
                Self.logger.info("n_action_qr_login_confirm: \(uid)")
                let confirmInfo = args.serverInfo
                guard let riskLevel = confirmInfo.riskBlockInfo.riskLevel else {
                    Self.logger.errorWithAssertion("n_action_qr_login_confirm: no_risk_level")
                    return
                }

                switch riskLevel {
                case .alert:
                    let handler = QRLoginConfirmAlertHandler(resolver: resolver)
                    handler.handle(info: confirmInfo, context: args.context, payload: args.additional, success: args.successHandler, failure: args.errorHandler)
                case .danger:
                    let handler = QRLoginConfirmDangerHandler(resolver: resolver)
                    handler.handle(info: confirmInfo, context: args.context, payload: args.additional, success: args.successHandler, failure: args.errorHandler)
                }
            })
        )
    }

    func setupEventRegister(eventBus: LoginPassportEventBus) {
        // MARK: Login & Register
        eventBus.register(
            step: .login,
            handler: ServerInfoEventBusHandler<V3LoginInfo>(handleWork: { (args) in
                self.currentNavigation()?.popToRootViewController(animated: true)
                args.successHandler()
            })
        )

        eventBus.register(
            step: .setPersonalInfo,
            handler: ServerInfoEventBusHandler<V4PersonalInfo>(handleWork: { args in
                // TODO: 通过改造后的 UniContext 来识别是外部还是内部的注册，以决定是否显示语言选项按钮（simplifyLogin）
                let inputInfo: V3InputInfo? = args.additional as? V3InputInfo
                let userCenterInfo: V4UserOperationCenterInfo? = args.additional as? V4UserOperationCenterInfo
                let vc = self.loginService.createRegisterViewController(personalInfo: args.serverInfo, userCenterInfo: userCenterInfo, inputInfo: inputInfo, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // 目前用于登录后关闭账号申诉 AppLink 流程
        eventBus.register(
            step: .closeAll,
            handler: ServerInfoEventBusHandler<CloseAllInfo>(handleWork: { (args) in
                guard let vcs = self.currentNavigation()?.viewControllers,
                      let index = vcs.firstIndex(where: { $0.closeAllStartPoint }) else {
                    Self.logger.errorWithAssertion("close all failed no found start point")
                    args.successHandler()
                    return
                }
                
                if let message = args.serverInfo.toast, !message.isEmpty, let mainSceneWindow = PassportNavigator.keyWindow {
                    RoundedHUD.showTips(with: message, on: mainSceneWindow)
                }

                //如果找到的页面是root vc , 执行 dimiss 的操作
                if let navVC = self.currentNavigation(), index == 0 {
                    Self.logger.info("close all dismiss navigation controller")
                    navVC.dismiss(animated: true, completion: nil)
                    args.successHandler()
                    return
                }

                // 移到起点前面
                let popToVC = vcs[index - 1]
                Self.logger.info("close all back to \(type(of: popToVC))")
                self.currentNavigation()?.popToViewController(popToVC, animated: true)
                args.successHandler()
            })
        )

        eventBus.register(
            step: .verifyIdentity,
            handler: ServerInfoEventBusHandler<V4VerifyInfo>(handleWork: { args in
                self.logVerifyCodeSteps(args.serverInfo)
                let wrapper = args.additional as? VerifyTokenCompletionWrapper ?? nil
                let vc = self.loginService.createVerifyViewController(verifyInfo: args.serverInfo, verifyTokenCompletionWrapper: wrapper, context: args.context)
                vc.setCloseAllStartPointIfHas(additional: CommonConst.closeAllParam)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        eventBus.register(step: .multiVerify,
                          handler: ServerInfoEventBusHandler<MultiVerifyBaseStepInfo>(handleWork: { args in
            guard let vm = try? MultiVerifyViewModel(step: PassportStep.multiVerify.rawValue, verifyInfo: args.serverInfo, context: args.context) else {
                    args.errorHandler(.invalidEvent)
                    Self.logger.info("init MultiVerifyViewModel fail")
                    return
                }
                let vc = MultiVerifyViewController(vm: vm)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )
        
        eventBus.register(
            step: .checkSecPwd,
            handler: ServerInfoEventBusHandler<CheckSecurityPasswordStepInfo>(handleWork: { args in
                var verifyStep: VerifySecurityPasswordStepInfo?
                var resetStep: V4StepData?
                if args.serverInfo.isOpen {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: args.serverInfo.nextStep.stepInfo as Any, options: .prettyPrinted)
                        verifyStep = try JSONDecoder().decode(VerifySecurityPasswordStepInfo.self, from: data)
                    } catch {
                        assertionFailure("Invalid server data")
                    }
                } else {
                    resetStep = args.serverInfo.nextStep
                }
                SecurityWindow.showSecurityVC(isOpen: args.serverInfo.isOpen, verifyStep: verifyStep, resetStep: resetStep, context: UniContextCreator.create(.checkSecurityPassword))
                args.successHandler()
            })
        )
        
        eventBus.register(
            step: .setSecPwd,
            handler: ServerInfoEventBusHandler<SetSecurityPasswordStepInfo>(handleWork: { args in
                let vc = SecuritySetPwdViewController(action: .reset, step: args.serverInfo) {}
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )
        
        eventBus.register(
            step: .verifySecPwd,
            handler: ServerInfoEventBusHandler<VerifySecurityPasswordStepInfo>(handleWork: { args in
                SecurityWindow.showSecurityVC(isOpen: true, verifyStep: args.serverInfo, context: args.context)
                args.successHandler()
            })
        )

        eventBus.register(
            step: .ok,
            handler: ServerInfoEventBusHandler<OKInfo>(handleWork: { args in
                // 为了解决 verify token 场景下验证码完成后回调的问题
                args.successHandler()
            })
        )

        eventBus.register(
            step: .newVerifyIdentity,
            handler: ServerInfoEventBusHandler<V3VerifyInfo>(handleWork: { (args) in
                let vc = self.loginService.createVerifyVC(
                    verifyInfo: args.serverInfo,
                    context: args.context
                )
                vc.setCloseAllStartPointIfHas(additional: CommonConst.closeAllParam)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )
        
        eventBus.register(
            step: .verifyCode,
            handler: ServerInfoEventBusHandler<V4VerifyInfo>(handleWork: { args in
                let wrapper = args.additional as? VerifyTokenCompletionWrapper ?? nil
                let vc = self.loginService.createVerifyViewController(verifyInfo: args.serverInfo, verifyTokenCompletionWrapper: wrapper, context: args.context)
                vc.setCloseAllStartPointIfHas(additional: CommonConst.closeAllParam)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // UserList
        eventBus.register(
            step: .userList,
            handler: ServerInfoEventBusHandler<V4SelectUserInfo>(handleWork: { (args) in
                let vc = self.loginService.createSelectUserVC(args.serverInfo, context: args.context)
                vc.closeAllStartPoint = true
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // App Permission
        eventBus.register(
            step: .appPermission,
            handler: ServerInfoEventBusHandler<AppPermissionInfo>(handleWork: { (args) in
                let vc = self.loginService.createAppPermissionVC(args.serverInfo, context: args.context)
                vc.closeAllStartPoint = true
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // Apply Form
        eventBus.register(
            step: .applyForm,
            handler: ServerInfoEventBusHandler<ApplyFormInfo>(handleWork: { (args) in
                let vc = self.loginService.createApplyFormVC(args.serverInfo, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // TenantCreate
        eventBus.register(
            step: .prepareTenant,
            handler: ServerInfoEventBusHandler<V3CreateTenantInfo>(handleWork: { (args) in
                let vc: UIViewController
                switch self.currentBusinessContext {
                case .outerLoginOrRegister, .innerLoginOrRegister:
                    vc = self.loginService.createTenantCreatedVC(args.serverInfo, context: args.context)
                case .joinTeam:
                    vc = self.loginService.createTenantVC(args.serverInfo, additionalInfo: args.additional, context: args.context)
                default:
                    Self.logger.error("invalid step tenantCreate for context: \(self.currentBusinessContext)")
                    args.successHandler()
                    return
                }
                vc.setCloseAllStartPointIfHas(additional: CommonConst.closeAllParam)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )
        
        // SetPwd
        eventBus.register(
            step: .setPwd,
            handler: ServerInfoEventBusHandler<V4SetPwdInfo>(handleWork: { args in
                Self.logger.info("invalid step setPwd for current context \(self.currentBusinessContext)")
                let vc: UIViewController = self.loginService.createSetPwdVC(args.serverInfo, api: self.loginAPI, context: args.context)
                vc.closeAllStartPoint = true
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        eventBus.register(
            step: .v3SetPwd,
            handler: ServerInfoEventBusHandler<V3SetPwdInfo>(handleWork: { args in
                Self.logger.info("handle old set pwd step")
                let vc = self.loginService.createV3SetPwdVC(args.serverInfo, api: self.loginAPI, context: args.context)
                vc.setCloseAllStartPointIfHas(additional: args.additional)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // SetName
        eventBus.register(
            step: .setName,
            handler: ServerInfoEventBusHandler<V4SetNameInfo>(handleWork: { (args) in
                let vc = self.loginService.createSetNameVC(args.serverInfo, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // DispatchSetName
        eventBus.register(
            step: .dispatchSetName,
            handler: ServerInfoEventBusHandler<V4DispatchSetNameInfo>(handleWork: { (args) in
                Self.logger.info("n_action_dispatch_set_name")

                let udToast = PassportLoadingService.showLoading()

                self.loginAPI.setName(serverInfo: args.serverInfo, name: nil, optIn: nil, context: args.context)
                    .post(vcHandler: args.vcHandler, context: args.context)
                    .subscribe(onNext: {  _ in
                        Self.logger.info("n_action_dispatch_set_name_succ")
                        udToast?.remove()
                        args.successHandler()
                    }, onError: { error in
                        Self.logger.error("n_action_dispatch_set_name_fail", error: error)
                        udToast?.remove()
                        args.errorHandler(EventBusError.internalError(.clientError(error.localizedDescription)))
                        if let topVC = PassportNavigator.topMostVC {
                            Self.logger.error("n_action_dispatch_set_name_fail", body:"show toast", error: error)
                            V3ErrorHandler(vc: topVC, context: args.context, showToastOnWindow: true).handle(error)
                        }
                    })
                    .disposed(by: self.disposeBag)
            })
        )

        //user_operation_center
        eventBus.register(
            step: .operationCenter,
            handler: ServerInfoEventBusHandler<V4UserOperationCenterInfo>(handleWork: { (args) in
                let vc: UIViewController
                vc = self.loginService.createOperationCenter(args.serverInfo, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // JoinTenant
        eventBus.register(
            step: .joinTenant,
            handler: ServerInfoEventBusHandler<V4JoinTenantInfo>(handleWork: { (args) in
                let vc: UIViewController
                switch self.currentBusinessContext {
                case .outerLoginOrRegister, .innerLoginOrRegister:
                    vc = self.loginService.createJoinTenant(
                        args.serverInfo,
                        additionalInfo: args.additional,
                        api: self.loginService.passportAPI,
                        context: args.context
                    )
                case .joinTeam:
                    vc = self.loginService.createJoinTenant(
                        args.serverInfo,
                        additionalInfo: args.additional,
                        api: self.loginService.joinTeamAPI,
                        useHUDLoading: true,
                        context: args.context
                    )
                default:
                    Self.logger.error("invalid step dispatchNext for context: \(self.currentBusinessContext)")
                    args.successHandler()
                    return
                }
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        eventBus.register(
            step: .joinTenantReview,
            handler: ServerInfoEventBusHandler<V4JoinTenantReviewInfo>(handleWork: { (args) in
                let vc: UIViewController
                vc = self.loginService.createJoinTenantReview(
                    args.serverInfo,
                    additionalInfo: args.additional,
                    api: self.loginService.passportAPI,
                    context: args.context
                )
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // JoinTenantCode
        eventBus.register(
            step: .joinTenantCode,
            handler: ServerInfoEventBusHandler<V4JoinTenantCodeInfo>(handleWork: { (args) in

                let vc: UIViewController
                switch self.currentBusinessContext {
                case .outerLoginOrRegister, .innerLoginOrRegister:
                    vc = self.loginService.createJoinTenantCode(
                        args.serverInfo,
                        additionalInfo: args.additional,
                        api: self.loginService.passportAPI,
                        context: args.context
                    )
                case .joinTeam:
                    vc = self.loginService.createJoinTenantCode(
                        args.serverInfo,
                        additionalInfo: args.additional,
                        api: self.loginService.joinTeamAPI,
                        useHUDLoading: true,
                        context: args.context
                    )
                default:
                    Self.logger.error("invalid step dispatchNext for context: \(self.currentBusinessContext)")
                    args.successHandler()
                    return
                }

                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // JoinTenantScan
        eventBus.register(
            step: .joinTenantScan,
            handler: ServerInfoEventBusHandler<V4JoinTenantScanInfo>(handleWork: { args in
                let vc: UIViewController
                switch self.currentBusinessContext {
                case .outerLoginOrRegister, .innerLoginOrRegister:
                    vc = self.loginService.createJoinTenantScan(
                        args.serverInfo,
                        additionalInfo: args.additional,
                        api: self.loginService.passportAPI,
                        context: args.context
                    )
                case .joinTeam:
                    vc = self.loginService.createJoinTenantScan(
                        args.serverInfo,
                        additionalInfo: args.additional,
                        api: self.loginService.joinTeamAPI,
                        useHUDLoading: true,
                        context: args.context
                    )
                default:
                    Self.logger.error("invalid step dispatchNext for context: \(self.currentBusinessContext)")
                    args.successHandler()
                    return
                }
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // WebStep
        eventBus.register(
            step: .webStep,
            handler: ServerInfoEventBusHandler<V3WebStepInfo>(handleWork: { (args) in
                let uuid = UUID().uuidString
                guard let url = SuiteLoginUtil.queryURL(urlString: args.serverInfo.url, params: ["stepInfoKey": uuid], keepOldItems: true) else {
                    args.errorHandler(.invalidParams)
                    Self.logger.error("EventBus: cannot handle event [\(args.event)] because url add query error url length: \(args.serverInfo.url.count)")
                    return
                }
                guard let from = PassportNavigator.topMostVC else {
                    Self.logger.errorWithAssertion("no main scene for webStep")
                    return
                }
                self.loginService.dependency.setValue(value: args.serverInfo.stepInfoJSON, forKey: uuid)
                self.loginService.dependency.openDynamicURL(url, from: from)
                args.successHandler()
            })
        )

        // idpLogin
        eventBus.register(
            step: .idpLogin,
            handler: ServerInfoEventBusHandler<IDPLoginInfo>(handleWork: { (args) in
                Self.logger.info("n_action_idp_auth")
                
                var monitorKeyType = ""
                switch self.currentBusinessContext {
                case .outerLoginOrRegister, .innerLoginOrRegister:
                    monitorKeyType = "register_or_login"
                case .switchUser:
                    monitorKeyType = "switch_user"
                case .accountManage:
                    monitorKeyType = "contact_manager"
                default:
                    Self.logger.error("no monitorKeyType for context: \(self.currentBusinessContext)")
                }

                let sceneInfo = [
                    MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.idpEnter.rawValue,
                    MultiSceneMonitor.Const.type.rawValue: monitorKeyType,
                    MultiSceneMonitor.Const.result.rawValue: "success",
                    "idp_type": args.serverInfo.authenticationChannel?.rawValue ?? ""
                ]

                /// 这个全局取的写法有问题
                if let from = self.currentNavigation() {
                    var successBlockCalled = false
                    self.idpService.signInWith(
                        channel: args.serverInfo.authenticationChannel,
                        idpLoginInfo: args.serverInfo,
                        from: from,
                        sceneInfo: sceneInfo,
                        switchUserStatusSub: nil,
                        context: args.context
                    )
                    .subscribe(onNext: { [weak self] (idpServiceStep) in
                        if self?.currentBusinessContext == PassportBusinessContext.switchUser {
                            SwitchUserMonitor.shared.update(step: .verify)
                            SwitchUserUnifyMonitor.shared.update(step: .promptSwitch)
                        }
                        switch idpServiceStep {
                        case .inAppWebPage(let vc):
                            self?.showVC(vc, vcHandler: args.vcHandler, animated: true)
                            args.successHandler()
                            successBlockCalled = true
                        case .systemWebPage(let urlString):
                            if let url = NSURL(string: urlString) as URL? {
                                Self.logger.info("n_action_idp_auth_external")
                                UIApplication.shared.open(url, completionHandler: nil)
                            } else {
                                Self.logger.error("n_action_idp_auth_external_fail", body: "url is nil")
                            }
                            args.successHandler()
                            successBlockCalled = true
                        case .stepData(let step, let stepInfo):
                            // 此处可能会因为 enter_app 切对端耗时较长，增加 loading
                            // https://meego.feishu.cn/larksuite/issue/detail/5227607?parentUrl=%2Flarksuite%2FissueView%2Fj1ZvyBxbrF
                            var hud: UDToast?
                            if let step = PassportStep(rawValue: step), step == .enterApp {
                                hud = self?.showLoadingHUD()
                            }

                            self?.eventBus.post(
                                event: step,
                                context: V3RawLoginContext(stepInfo: stepInfo, context: args.context),
                                success: {
                                    hud?.remove()

                                    if !successBlockCalled {
                                        args.successHandler()
                                    }
                                }) { (err) in
                                    hud?.remove()

                                    args.errorHandler(err)
                                }
                        }
                    }, onError: { (err) in
                        Self.logger.error("failed to login with idp cp: \(String(describing: args.serverInfo.authenticationChannel?.rawValue)), error: \(err)")
                        V3ErrorHandler(vc: from, context: args.context).handle(err)
                        args.errorHandler(EventBusError.invalidEvent)
                    })
                    .disposed(by: self.disposeBag)
                }
            })
        )
        
        // idpLoginPage
        eventBus.register(
            step: .idpLoginPage,
            handler: ServerInfoEventBusHandler<V3EnterpriseInfo>(handleWork: { (args) in
                let vc = self.loginService.createEnterpriseLoginVC(enterpriseInfo: args.serverInfo, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // recover account carrier
        eventBus.register(
            step: .recoverAccountCarrier,
            handler: ServerInfoEventBusHandler<V3RecoverAccountCarrierInfo>(handleWork: { (args) in
                let from = self.getRecoverAccountSourceType(additionalInfo: args.additional)
                let vc = self.loginService.createRecoverAccountCarrierVC(recoverAccountCarrierInfo: args.serverInfo, from: from, context: args.context)
                vc.setCloseAllStartPointIfHas(additional: args.additional)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )
        
        eventBus.register(
            step: .retrieveOpThree,
            handler: ServerInfoEventBusHandler<V4RetrieveOpThreeInfo>(handleWork: { (args) in
                let vc = self.loginService.createRetrieveOpThreeVC(recoverAccountCarrierInfo: args.serverInfo, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                vc.setCloseAllStartPointIfHas(additional: args.additional)
                args.successHandler()
            })
        )
        
        eventBus.register(
            step: .bioAuth,
            handler: ServerInfoEventBusHandler<V4BioAuthInfo>(handleWork: { (args) in
                let from = self.getRecoverAccountSourceType(additionalInfo: args.additional)

                let vc = self.loginService.createBioAuthVC(
                    step: args.event,
                    bioAuthInfo: args.serverInfo,
                    additionalInfo: args.additional,
                    from: from,
                    context: args.context
                )
                vc.setCloseAllStartPointIfHas(additional: args.additional)
                vc.view.layoutIfNeeded()
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                vc.setCloseAllStartPointIfHas(additional: args.additional)
                args.successHandler()
            })
        )
        
        eventBus.register(
            step: .bioAuthTicket,
            handler: ServerInfoEventBusHandler<V4BioAuthTicketInfo>(handleWork: { (args) in
                let info = args.serverInfo as V4BioAuthTicketInfo
                
                var identityName: String?
                var identityNumber: String?
                if let additionalInfo = args.additional as? [String: Any] {
                    identityName = additionalInfo["name"] as? String
                    identityNumber = additionalInfo["identity_number"] as? String
                }
                guard let flowType = info.flowType else {
                    Self.logger.error("bioAuthTicket step: no flowType error.")
                    return
                }
                let bioAuthInfo = BioAuthFaceInfo(nextInString: info.nextInString, flowType: flowType, usePackageDomain: info.usePackageDomain, ticket: info.ticket, identityNumber: identityNumber, identityName: identityName, sdkScene: info.sdkScene, aid: info.aid)
                self.bioAuthService.doBioAuthVerify(info: bioAuthInfo, context: args.context, success: args.successHandler, error: args.errorHandler)
            })
        )

        // bio auth choose
        eventBus.register(
            step: .verifyChoose,
            handler: ServerInfoEventBusHandler<V3RecoverAccountChooseInfo>(handleWork: { (args) in
                let from = self.getRecoverAccountSourceType(additionalInfo: args.additional)
                Self.logger.info(
                    "handle verify choose",
                    additionalData: [
                        "source_type": String(describing: args.serverInfo.sourceType)
                    ])
                if args.serverInfo.sourceType == BioAuthSourceType.recoverAccount {
                    guard let additionalInfo = args.additional as? [String: Any],
                          let name = additionalInfo["name"] as? String,
                          let identityNumber = additionalInfo["identity_number"] as? String else {
                        args.errorHandler(EventBusError.invalidParams)
                        return
                    }
                    args.serverInfo.name = name
                    let recoverAccountFaceInfo = args.serverInfo.nextServerInfo(for: PassportStep.verifyFace.rawValue) as? V3RecoverAccountFaceInfo
                    recoverAccountFaceInfo?.name = name
                    recoverAccountFaceInfo?.identityNumber = identityNumber
                    args.serverInfo.verifyFaceInfo = recoverAccountFaceInfo

                    let recoverAccountBankInfo = args.serverInfo.nextServerInfo(for: PassportStep.recoverAccountBank.rawValue) as? V3RecoverAccountBankInfo
                    recoverAccountBankInfo?.name = name
                    args.serverInfo.recoverAccountBankInfo = recoverAccountBankInfo
                } else {
                    let verifyFaceInfo = args.serverInfo.nextServerInfo(for: PassportStep.verifyFace.rawValue) as? V3RecoverAccountFaceInfo
                    args.serverInfo.verifyFaceInfo = verifyFaceInfo
                }
                let vc = self.loginService.createRecoverAccountChooseVC(
                    step: args.event,
                    recoverAccountChooseInfo: args.serverInfo,
                    from: from,
                    context: args.context
                )
                vc.setCloseAllStartPointIfHas(additional: args.additional)
                vc.view.layoutIfNeeded()
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // bio auth face
        eventBus.register(
            step: .verifyFace,
            handler: ServerInfoEventBusHandler<V3RecoverAccountFaceInfo>(handleWork: { (args) in
                Self.logger.info(
                    "handle verify face",
                    additionalData: [
                        "source_type": String(describing: args.serverInfo.sourceType)
                    ])
                let from = self.getRecoverAccountSourceType(additionalInfo: args.additional)
                if args.serverInfo.sourceType == BioAuthSourceType.recoverAccount {
                    self.bioAuthService.doRecoverAccountVerifyFace(
                        info: args.serverInfo,
                        from: from,
                        context: args.context,
                        success: args.successHandler,
                        error: args.errorHandler
                    )
                } else {
                    self.bioAuthService.doBioAuthVerifyFace(
                        info: args.serverInfo,
                        from: from,
                        context: args.context,
                        success: args.successHandler,
                        error: args.errorHandler
                    )
                }
            })
        )

        // recover account bank
        eventBus.register(
            step: .recoverAccountBank,
            handler: ServerInfoEventBusHandler<V3RecoverAccountBankInfo>(handleWork: { (args) in
                let from = self.getRecoverAccountSourceType(additionalInfo: args.additional)
                let vc = self.loginService.createRecoverAccountBankVC(recoverAccountBankInfo: args.serverInfo, from: from, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // set credential
        eventBus.register(
            step: .setInputCredential,
            handler: ServerInfoEventBusHandler<V3SetInputCredentialInfo>(handleWork: { (args) in
                let from = self.getRecoverAccountSourceType(additionalInfo: args.additional)
                let vc = self.loginService.createSetInputCredentialVC(setInputCredentialInfo: args.serverInfo, from: from, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )
        
        eventBus.register(
            step: .setCredential,
            handler: ServerInfoEventBusHandler<SetCredentialInfo>(handleWork: { (args) in
                let vc = self.loginService.createNewSetCredentialVC(setInputCredentialInfo: args.serverInfo, context: args.context)
                vc.setCloseAllStartPointIfHas(additional: args.additional)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // MARK: Switch User

        eventBus.register(
            step: .authType,
            handler: ServerInfoEventBusHandler<AuthTypeInfo>(handleWork: { (args) in
                let vc = self.loginService.createAuthTypeVC(step: PassportStep.authType.rawValue, authTypeInfo: args.serverInfo, context: args.context)
                vc.setCloseAllStartPointIfHas(additional: args.additional)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        // MagicLink
        eventBus.register(
            step: .magicLink,
            handler: ServerInfoEventBusHandler<V3MagicLinkInfo>(handleWork: { (args)  in
                let vc = self.loginService.createMagicLinkVC(info: args.serverInfo, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler)
                args.successHandler()
            })
        )

        // MARK: AccountManage
        eventBus.register(
            step: .accountSafety,
            handler: ServerInfoEventBusHandler<AccountMessage>(handleWork: { args in
                guard let from = PassportNavigator.topMostVC else {
                    args.errorHandler(EventBusError.invalidParams)
                    Self.logger.errorWithAssertion("no main scene for accountSafety")
                    return
                }
                self.loginService.openAccountSecurityCenter(for: .accountSecurityCenter, from: from)
                args.successHandler()
            })
        )

        eventBus.register(
            step: .simpleResponseSuccess,
            handler: CommonEventBusHandler(handleWork: { (args) in
                args.successHandler()
            })
        )

        eventBus.register(
            step: .enterApp,
            handler: ServerInfoEventBusHandler<V4EnterAppInfo>(handleWork: { (args) in
                // TODO: 完善 scene info

                self.loginService
                    .enterAppDidCall(enterAppInfo: args.serverInfo,
                                     sceneInfo: [:],
                                     success: args.successHandler,
                                     error: { error in
                    args.errorHandler(EventBusError.internalError(error))
                }, context: args.context)
            })
        )

        eventBus.register(
            step: .qrLoginPolling,
            handler: ServerInfoEventBusHandler<QRCodeLoginInfo>(handleWork: { [weak self] (args) in
                guard let self = self else { return }
                guard let info = args.serverInfo as? QRCodeLoginInfo else {
                    Self.logger.errorWithAssertion("no info")
                    return
                }

                Self.logger.info("n_action_qr_login_polling_step")
                let vc = QRCodeLoginViewController(vm: QRLoginViewModel(token: info.token, registEnable: true, context: args.context))
                let navigation = LoginNaviController(rootViewController: vc)
                navigation.modalPresentationStyle = .fullScreen

                if let mainSceneTopMost = PassportNavigator.topMostVC {
                    Self.logger.info("n_action_qr_login_polling_present")
                    mainSceneTopMost.present(navigation, animated: true, completion: nil)
                } else {
                    Self.logger.errorWithAssertion("n_action_qr_login_no_main_scene_top_most")
                }
                args.successHandler()
            })
        )

        eventBus.register(
            step: .accountAppeal,
            handler: ServerInfoEventBusHandler<V3AccountAppeal>(handleWork: { (args) in
                guard let url = URL(string: args.serverInfo.appealUrl),
                      let from = PassportNavigator.topMostVC else {
                    Self.logger.errorWithAssertion("appeal url not valid or no from vc \(args.serverInfo.appealUrl)")
                    args.errorHandler(EventBusError.internalError(.badServerData))
                    return
                }
                let newUrl = WebConfig.commonParamsUrlFrom(url: url, with: [WebConfig.Key.hideNavi: WebConfig.Value.hideNavi])
                if args.context.from == .invalidSession{
                    self.loginService.dependency.openDynamicURL(newUrl, from: from, isPresent: true) { vc in
                        vc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                    }
                }else{
                    self.loginService.dependency.openDynamicURL(newUrl, from: from)
                }
                args.successHandler()
            })
        )
        
        eventBus.register(
            step: .showDialog,
            handler: ServerInfoEventBusHandler<V4ShowDialogStepInfo>(handleWork: { [weak self] (args) in
                guard let self = self else { return }

                guard let title = args.serverInfo.title, !title.isEmpty,
                      let subTitle = args.serverInfo.subTitle, !subTitle.isEmpty else {
                    Self.logger.info("showDialog no title no suTitle do nothing")
                    args.successHandler()
                    return
                }
                guard let topVC = PassportNavigator.topMostVC else {
                    Self.logger.error("n_action_showdialog_show", body: "show dialog step no topVC to present vc")
                    args.errorHandler(EventBusError.internalError(.badLocalData("no topVC to present vc")))
                    return
                }

                //rust push 最新实现追加了 hold launch阶段的push，session失效不用再判断是否是开屏阶段，进入首屏后会发送push
                //现在dismissSignal，feed会在数据成功之后push，拉取失败不发送信号
                if PassportSwitch.shared.disableSessionInvalidDialogDuringLaunch == false {
                    let launchSignal = (topVC as? UserControlledLaunchTransition)?.dismissSignal
                    if args.context.from == .invalidSession, let signal = launchSignal, signal.value == false {
                        // 当前是开屏 忽略
                        Self.logger.warn("n_action_showdialog_show", body: "show dialog step launch vc, present next time")
                        args.errorHandler(EventBusError.internalError(.badLocalData("app launching")))
                        return
                    }
                }

                let btnList = args.serverInfo.btnList ?? []
                let buttonInfo: [String] = btnList.map { $0.description }
                Self.logger.info("n_action_showdialog_show", additionalData: [ "buttons" : buttonInfo, "topVC": "\(type(of: topVC))"])

                let dialogScene: DialogScene

                if btnList.contains(where: { $0.actionType == .ssoLogin }) {
                    dialogScene = .sso
                    SuiteLoginTracker.track(Homeric.PASSPORT_SSO_ALERT_VIEW)
                } else if btnList.contains(where: { $0.actionType == .acceptOptIn }) {
                    dialogScene = .otpIn
                } else if btnList.contains(where: { $0.actionType == .gotIt && $0.nextStep == nil }) &&
                            args.context.from == .invalidSession {
                    dialogScene = .invalidSession
                } else {
                    dialogScene = .unknown
                }

                func autoSwitchUser() {
                    UserManager.shared.makeForegroundUserInvalid()
                    self.newSwitchUserService.autoSwitch(complete: { isFinished in
                        args.successHandler()
                        //监控
                        if isFinished {
                            //监控
                            PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.process_invalid_front_user_end_switch_succ,
                                                  categoryValueMap: ["switch_reason": 1],
                                                  context: args.context) // 1: session invalid
                        }
                    }, context: UniContextCreator.create(.invalidSession))
                }

                func track(_ info: CollectionInfo?) {
                    guard let info = info else {
                        return
                    }

                    SuiteLoginTracker.track(info.eventKey, params: info.params ?? [:])
                }
                
                /// 互通整改： https://bytedance.feishu.cn/wiki/wikcnRhkws8DE0L4HgODzEbOm9c
                /// 1. 对于失效的跨域租户，客户端在用户切换到该身份时主动删除用户信息并隐藏侧边栏头像（需求），此时服务端 switch\_identity 会下发 showDialog 并且 logoutReason 为 crossBrand
                /// 2. 用户退出前台跨域用户时不删除前台用户，切换到下一个租户（需求）
                /// 3. 对于登录态有效的跨域身份不做处理（需求）
                /// 4. 用户退出前台非跨域用户时不会被动切换到失效session，理论上不用处理
                let crossBrand = args.serverInfo.logoutReason == .crossBrand
                let foregroundUserCrossBrand = UserManager.shared.foregroundUser?.userID == args.serverInfo.logoutUserID // user:current
                
                let nextStepAction = { (nextStep: V4ShowDialogStepInfo.NextStep) in
                    LoginPassportEventBus.shared.post(
                        event: nextStep.event,
                        context: V3RawLoginContext(
                            stepInfo: nextStep.info,
                            vcHandler: args.vcHandler,
                            context: args.context
                        ),
                        success: {
                            if crossBrand {
                                Self.logger.info("n_action_showdialog_cross_brand")
                                
                                /// 互通整改 2：前台跨域租户失效切换到下个租户
                                if foregroundUserCrossBrand { // user:current
                                    Self.logger.info("n_action_showdialog_cross_brand_auto_switch")
                                    autoSwitchUser()
                                } else {
                                    args.errorHandler(.internalError(.userCanceled))
                                }
                            } else {
                                args.successHandler()
                            }
                        }, error: { error in
                            args.errorHandler(error)
                        })
                }
                
                let middlewareAction = { (actionBtn: V4ShowDialogStepInfo.ActionBtn) in

                    /// 互通整改 1：删除非前台跨域身份信息
                    if let userID = args.serverInfo.logoutUserID, crossBrand {
                        Self.logger.info("n_action_showdialog_login_disabled", additionalData: [ "userid" : userID])
                        
                        // You don't mess with foreground user
                        if !foregroundUserCrossBrand { // user:current
                            Self.logger.info("n_action_showdialog_remove_user", additionalData: [ "userid" : userID])
                            UserManager.shared.removeUsers(by: [userID])
                        }
                    }
                                        
                    if actionBtn.actionType == .gotIt {
                        if dialogScene == .invalidSession {
                            autoSwitchUser()
                        } else if let next = actionBtn.nextStep {
                            nextStepAction(next)
                        } else {
                            args.errorHandler(.internalError(.userCanceled))
                        }
                    } else {
                        if let next = actionBtn.nextStep {
                            nextStepAction(next)
                        } else {
                            args.successHandler()
                        }
                    }
                    
                    // track && logs
                    if actionBtn.actionType == .gotIt {
                        Self.logger.info("n_action_showdialog_cancel", additionalData: [ "button" : actionBtn.description])
                    } else {
                        Self.logger.info("n_action_showdialog_click", additionalData: [ "button" : actionBtn.description])
                    }

                    if dialogScene == .sso {
                        if actionBtn.actionType == .ssoLogin {
                            SuiteLoginTracker.track(Homeric.PASSPORT_SSO_ALERT_CLICK, params: [
                                "click" : "sso_login",
                                "target" : "passport_sso_login_view"
                            ])
                        } else if actionBtn.actionType == .gotIt {
                            SuiteLoginTracker.track(Homeric.PASSPORT_SSO_ALERT_CLICK, params: [
                                "click" : "i_know"
                            ])
                        }
                    }

                    if dialogScene == .otpIn {
                        Self.logger.info("n_action_showdialog_opt_in_click",
                                         additionalData: ["action_type" : actionBtn.actionType?.rawValue ?? 0])
                    }
                    
                    SuiteLoginTracker.track(Homeric.PASSPORT_DIALOG_CLICK,
                                            params: ["is_session_expired:": (args.context.from == .invalidSession) ? "true" : "false",
                                                     "click": "button_click",
                                                     "target": "none",
                                                     "action_type": String(actionBtn.actionType?.rawValue ?? 0)
                                                    ]
                                            )
                    track(actionBtn.collectionInfo)
                }
                
                func dismissCheck(actionType: V4ShowDialogStepInfo.ActionBtn.ActionType) -> Bool {
                    // 前台租户失效时点「我知道了」之外的按钮，弹框不消失，但如果是跨域租户，弹框消失（因为后续可能会继续弹框验证）
                    return !(args.context.from == .invalidSession)
                        || actionType == .gotIt
                        || foregroundUserCrossBrand // user:current
                }
                
                let alert = LarkAlertController()
                alert.setTitle(text: title)
                alert.setContent(text: subTitle)

                switch dialogScene {
                case .otpIn:
                    btnList.enumerated().forEach { (index, button) in
                        if index == 0 {
                            alert.addPrimaryButton(text: button.text ?? "", numberOfLines: 0, dismissCompletion: {
                                middlewareAction(button)
                            })
                        } else {
                            alert.addSecondaryButton(text: button.text ?? "", numberOfLines: 0, dismissCompletion: {
                                middlewareAction(button)
                            })
                        }
                    }
                default:
                    if btnList.count > 1, let secBtn = btnList.last {
                        alert.addSecondaryButton(text: secBtn.text ?? "", numberOfLines: 0, dismissCompletion: {
                            middlewareAction(secBtn)
                        })
                    }

                    if let mainBtn = btnList.first {
                        alert.addPrimaryButton(text: mainBtn.text ?? "", numberOfLines: 0, dismissCheck: {
                            let checkResult = dismissCheck(actionType: (mainBtn.actionType ?? .unknown))
                            if !checkResult { // 如果可以消失，就消失后再执行action
                                middlewareAction(mainBtn) //alertview 不支持消失的情况下执行 action,暂时这么实现
                            }
                            return checkResult
                        }) {
                            middlewareAction(mainBtn)
                        }
                    }
                }

                if dialogScene == .otpIn, let baseVC = topVC as? BaseViewController {
                    baseVC.stopLoading()
                }
                topVC.present(alert, animated: true, completion: nil)
                SuiteLoginTracker.track(Homeric.PASSPORT_DIALOG_VIEW,
                                        params: ["is_session_expired:": (args.context.from == .invalidSession) ? "true" : "false"])
                track(args.serverInfo.collectionInfo)
            })
        )

        eventBus.register(
            step: .guideDialog,
            handler: ServerInfoEventBusHandler<GuideDialogStepInfo>(handleWork: { (args) in
                // 目前只风险 session 场景使用，弹窗触发逻辑和 session 失效保持一致
                guard let type = args.serverInfo.dialogType else {
                    Self.logger.error("n_action_guide_dialog", body: "no dialog type")
                    args.errorHandler(EventBusError.internalError(.badLocalData("no dialog type")))
                    return
                }
                Self.logger.info("n_action_guide_dialog", body: "enter")
                switch type {
                case .actionPanel:
                    let handler = GuideDialogActionPanelHandler()
                    handler.handle(info: args.serverInfo, context: args.context, vcHandler: args.vcHandler, success: args.successHandler, failure: args.errorHandler)
                case .alert:
                    let handler = GuideDialogAlertHandler()
                    handler.handle(info: args.serverInfo, context: args.context, vcHandler: args.vcHandler, success: args.successHandler, failure: args.errorHandler)
                }
            })
        )

        eventBus.register(
            step: .switchIdentity,
            handler: ServerInfoEventBusHandler<SwitchIdentityStepInfo>(handleWork: { [weak self] (args) in
                guard let self = self else { return }
                guard let user = args.serverInfo.userList.first else {
                    Self.logger.error("n_action_switch_identity_step", body: "no user info")
                    return
                }
                let context = UniContextCreator.create(.sessionReauth)
                Self.logger.info("n_action_switch_identity_step", body: "enter")
                self.newSwitchUserService.switchTo(userID: user.user.id,
                                                   complete: nil,
                                                   context: context)
            })
        )

        eventBus.register(
            step: .exemptRemind,
            handler: ServerInfoEventBusHandler<OKInfo>(handleWork: { [weak self] (args) in
                guard let self = self else { return }
                Self.logger.info("n_action_exempt_remind_step", body: "enter")
                UserCheckSessionAPI()
                    .exemptRemind()
                    .subscribe(onNext: { _ in
                        Self.logger.info("n_action_session_reauth_exempt_request_succeeded")
                        args.successHandler()
                    }, onError: { error in
                        Self.logger.error("n_action_session_reauth_exempt_request_failed", error: error)
                        args.errorHandler(EventBusError.internalError(.badServerData))
                    })
                    .disposed(by: self.disposeBag)
            })
        )
        
        eventBus.register(
            step: .resetOtp,
            handler: ServerInfoEventBusHandler<ResetOtpInfo>(handleWork: { (args) in
                guard let url = URL(string:args.serverInfo.url ?? ""),
                      let from = PassportNavigator.topMostVC else{
                    Self.logger.error("reset otp step no url!")
                    args.successHandler()
                    return
                }
                let newUrl = WebConfig.commonParamsUrlFrom(url: url, with: [WebConfig.Key.hideNavi: WebConfig.Value.hideNavi])
                self.loginService.dependency.openDynamicURL(newUrl, from: from)
                args.successHandler()
            })
        )

        eventBus.register(
            step: .getAuthURL,
            handler: ServerInfoEventBusHandler<GetAuthURLInfo>(handleWork: { (args) in
                Self.logger.info("n_action_get_auth_url")
                
                let info = args.serverInfo
                let body = SSOUrlReqBody(idpName: info.tenantDomain, userId: info.userID, targetSessionKey: info.targetSessionKey, authChannel: info.channel, rawStepInfo: info.rawStepInfo, context: args.context)
                
                Self.logger.info("n_action_get_auth_url_req")
                self.idpService.fetchConfigForIDP(body)
                    .post(vcHandler: args.vcHandler, context: args.context)
                    .subscribe(onNext: {  _ in
                        Self.logger.info("n_action_get_auth_url_req_suc")
                        args.successHandler()
                    }, onError: { error in
                        Self.logger.error("n_action_get_auth_url_req_fail", error: error)
                        args.errorHandler(EventBusError.internalError(.clientError(error.localizedDescription)))
                    })
                    .disposed(by: self.disposeBag)

            })
        )

        eventBus.register(
            step: .chooseOptIn,
            handler: ServerInfoEventBusHandler<ChooseOptInInfo>(handleWork: { (args) in
                Self.logger.info("n_action_showdialog_choose_opt_in_req")
                if let topVC = PassportNavigator.topMostVC as? BaseViewController {
                    topVC.showLoading()
                }
                let info = args.serverInfo
                self.loginAPI
                    .chooseOptIn(serverInfo: info, select: info.optIn, context: args.context)
                    .post(vcHandler: args.vcHandler, context: args.context)
                    .subscribe(onNext: {  _ in
                        Self.logger.info("n_action_showdialog_choose_opt_in_succ")
                        if let topVC = PassportNavigator.topMostVC as? BaseViewController {
                            topVC.stopLoading()
                        }
                        args.successHandler()
                    }, onError: { error in
                        Self.logger.error("n_action_showdialog_choose_opt_in_error", error: error)
                        if let topVC = PassportNavigator.topMostVC as? BaseViewController {
                            topVC.stopLoading()
                        }
                        args.errorHandler(EventBusError.internalError(.clientError(error.localizedDescription)))

                        // 由于 opt-in 的 alert 弹出时验证码已经被消费，当该请求失败时回到信息输入页
                        self.currentNavigation()?.popViewController(animated: true)
                    })
                    .disposed(by: self.disposeBag)
            })
        )

        eventBus.register(
            step: .verificationCompleted,
            handler: ServerInfoEventBusHandler<VerificationCompletedInfo>(handleWork: { (args) in
                let verificationCompleteStepHandler = VerificationCompleteStepHandler(eventArgs: args, currentNavigation: self.currentNavigation())
                verificationCompleteStepHandler.handle()
            })
        )
        
        eventBus.register(
            step: .realNameGuideWay,
            handler: ServerInfoEventBusHandler<RealNameGuideWayInfo>(handleWork: { (args) in
                
                Self.logger.info("n_action_realname_guide_way_start")
                
                guard let appealType = args.serverInfo.appealType else {
                    args.errorHandler(EventBusError.internalError(.badServerData))
                    Self.logger.error("n_action_realname_guide_way_start", body: "Invalid params")
                    return
                }
                
                self.loginAPI
                    .realNameGuideWay(serverInfo: args.serverInfo, appealType: appealType, context: args.context)
                    .post(CommonConst.closeAllParam, vcHandler: args.vcHandler, context: args.context)
                    .subscribe(onNext: {  _ in
                        Self.logger.info("n_action_realname_guide_way_succ")

                        args.successHandler()
                    }, onError: { error in
                        Self.logger.error("n_action_realname_guide_way_fail", error: error)

                        args.errorHandler(EventBusError.internalError(.clientError(error.localizedDescription)))
                    })
                    .disposed(by: self.disposeBag)
            })
        )
        
        eventBus.register(
            step: .webUrl,
            handler: ServerInfoEventBusHandler<V3WebUrl>(handleWork: { [weak self] (args) in
                guard let self = self else { return }
                
                Self.logger.info("n_action_open_web_url")
                var urlString = args.serverInfo.uri
                if let tempURL = URL(string: urlString), tempURL.scheme == nil {
                    urlString = CommonConst.prefixHTTPS + urlString
                }
                
                guard let url = URL(string: urlString) else {
                    Self.logger.info("n_action_open_web_url_fail")
                    args.errorHandler(EventBusError.internalError(.badServerData))
                    return
                }
                
                guard let from = PassportNavigator.topMostVC else {
                    Self.logger.info("n_action_open_web_url_fail")
                    args.errorHandler(EventBusError.internalError(.clientError("No top most scene found")))
                    return
                }

                if args.serverInfo.mode == CommonConst.openInSystemBrowser {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    if let additional = args.additional as? [String: Bool],
                       let isPresent = additional["presentWebURL"] as? Bool, isPresent {
                        self.loginService.dependency.openDynamicURL(url, from: from, isPresent: true, prepare: { vc in vc.modalPresentationStyle = .fullScreen })
                    } else {
                        self.loginService.dependency.openDynamicURL(url, from: from)
                    }
                }
                args.successHandler()
                Self.logger.info("n_action_open_web_url_succ", body: url.absoluteString)
            })
        )
        
        eventBus.register(
            step: .addEmail,
            handler: ServerInfoEventBusHandler<AddMailStepInfo>(handleWork: { [weak self] (args) in
                Self.logger.info("n_action_add_email")
                guard let self = self else { return }
                
                let viewController = self.loginService.createAddEmailViewController(info: args.serverInfo, context: args.context)
                self.showVC(viewController, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        eventBus.register(
            step: .ugCreateTenant,
            handler: ServerInfoEventBusHandler<UGCreateTenantInfo>(handleWork: { (args) in
                guard args.serverInfo.flowType != nil else {
                    Self.logger.error("ug create tenant info flowType cannot be found.")
                    args.errorHandler(EventBusError.internalError(.badServerData))
                    return
                }

                self.loginAPI
                    .v4CreateTenant(serverInfo: args.serverInfo, context: args.context)
                    .post(vcHandler: args.vcHandler, context: args.context)
                    .subscribe(onNext: {  _ in
                        Self.logger.info("n_action_ug_create_tenant_succ")
                        args.successHandler()
                    }, onError: { error in
                        Self.logger.error("n_action_ug_create_tenant_fail", error: error)
                        if let topVC = PassportNavigator.topMostVC {
                            Self.logger.error("n_action_ug_create_tenant_fail", body:"show toast", error: error)
                            V3ErrorHandler(vc: topVC, context: args.context, showToastOnWindow: true).handle(error)
                        }
                        args.errorHandler(EventBusError.internalError(.clientError(error.localizedDescription)))
                    })
                    .disposed(by: self.disposeBag)

            })
        )

        eventBus.register(
            step: .ugJoinByCode,
            handler: ServerInfoEventBusHandler<UGJoinByCodeInfo>(handleWork: { (args) in
                guard args.serverInfo.flowType != nil else {
                    Self.logger.error("ug join code info flowType cannot be found.")
                    args.errorHandler(EventBusError.internalError(.badServerData))
                    return
                }

                self.loginAPI.joinTenantByCode(serverInfo: args.serverInfo, teamCode: args.serverInfo.tenantCode, context: args.context)
                    .post(vcHandler: args.vcHandler, context: args.context)
                    .subscribe(onNext: {  _ in
                        Self.logger.info("n_action_ug_join_code_succ")
                        args.successHandler()
                    }, onError: { error in
                        Self.logger.error("n_action_ug_join_code_fail", error: error)
                        if let topVC = PassportNavigator.topMostVC {
                            Self.logger.error("n_action_ug_join_code_fail", body:"show toast", error: error)
                            V3ErrorHandler(vc: topVC, context: args.context, showToastOnWindow: true).handle(error)
                        }
                        args.errorHandler(EventBusError.internalError(.clientError(error.localizedDescription)))
                    })
                    .disposed(by: self.disposeBag)
            })
        )
        
        eventBus.register(
            step: .setSpareCredential,
            handler: ServerInfoEventBusHandler<SetSpareCredentialInfo>(handleWork: { [weak self] args in
                guard let self = self else { return }
                Self.logger.info("n_action_set_spare_credential_step")
                
                let vc = self.loginService.createSetSpareCredentialViewController(info: args.serverInfo, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        eventBus.register(
            step: .showPage,
            handler: ServerInfoEventBusHandler<ShowPageInfo>(handleWork: { [weak self] args in
                guard let self = self else { return }
                Self.logger.info("n_action_show_page_step")

                let vc = self.loginService.createShowPageViewController(info: args.serverInfo, context: args.context)
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        registerNativeEvent(eventBus: eventBus)
    }

    func registerNativeEvent(eventBus: LoginPassportEventBus) {

         //directOpenIDP
        eventBus.register(
            event: V3NativeStep.directOpenIDP.rawValue,
            handler: AdditionalInfoEventBusHandler<V3EnterpriseInfo>(handleWork: { [weak self]  args in
                guard let self = self else { return }
                let vc = self.idpWebViewService.loginPageForIDPName(nil, context: args.context, success: { (idpServiceStep) in
                    switch idpServiceStep {
                    case .stepData(let step, let stepInfo):
                        Self.logger.info("n_action_post_idp_step_\(step)")
                        LoginPassportEventBus.shared.post(
                            event: step,
                            context: V3RawLoginContext(stepInfo: stepInfo, context: args.context),
                            success: {
                                Self.logger.info("n_action_idp_step_\(step)_succ")
                                args.successHandler()
                            },
                            error: { error in
                                Self.logger.error("n_action_idp_step_\(step)_error")
                                args.errorHandler(error)
                            }
                        )
                    case .inAppWebPage(let vc):
                        Self.logger.error("n_action_idp_inAppWebPage")
                        self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                        args.successHandler()
                    case .systemWebPage(let urlString):
                        if let url = NSURL(string: urlString) as URL? {
                            Self.logger.info("n_action_idp_auth_external")
                            UIApplication.shared.open(url, completionHandler: nil)
                        } else {
                            Self.logger.error("n_action_idp_auth_external_fail", body: "url is nil")
                        }
                        args.successHandler()
                    default:
                        Self.logger.error("n_action_next_step_not_idp")
                        args.errorHandler(EventBusError.internalError(.clientError("No top most scene found")))
                        break
                    }
                }, error: { error in
                    args.errorHandler(EventBusError.internalError(V3LoginError.badResponse(error.localizedDescription)))
                    Self.logger.error("n_action_idp_page_error_\(error)")
                })

                self.showVC(vc, vcHandler: args.vcHandler)
            })
        )

        // EnterpriseLogin
        eventBus.register(
            event: V3NativeStep.enterpriseLogin.rawValue,
            handler: AdditionalInfoEventBusHandler<V3EnterpriseInfo>(handleWork: { args in
                let vc = self.loginService.createEnterpriseLoginVC(enterpriseInfo: args.additional, context: args.context)
                vc.closeAllStartPoint = true
                self.showVC(vc, vcHandler: args.vcHandler, animated: true)
                args.successHandler()
            })
        )

        eventBus.register(event: V3NativeStep.qrCodeLogin.rawValue, handler: AdditionalInfoEventBusHandler<String>(handleWork: { (args) in
            let vc = QRCodeLoginViewController(vm: QRLoginViewModel(token: args.additional, registEnable: false, context: args.context))
            self.showVC(vc, vcHandler: args.vcHandler)
            args.successHandler()
        }))

        eventBus.register(
            event: V3NativeStep.simpleWeb.rawValue,
            handler: AdditionalInfoEventBusHandler<V3SimpleWebInfo>(handleWork: { (args) in
                guard let from = PassportNavigator.topMostVC else {
                    Self.logger.errorWithAssertion("no main scene for V3NativeStep.simpleWeb")
                    return
                }
                self.loginService.dependency.openURL(args.additional.url, from: from)
                args.successHandler()
            })
        )
    }

    func getRecoverAccountSourceType(additionalInfo: Codable?) -> RecoverAccountSourceType {
        var from: RecoverAccountSourceType?
        if let additionalInfoMap = additionalInfo as? [String: Any],
            let fromInString = additionalInfoMap["from"] as? String {
            from = RecoverAccountSourceType(rawValue: fromInString)
        }
        return from ?? .unknown
    }

    private func logVerifyCodeSteps(_ info: V4VerifyInfo) {
        var options = [String]()
        if info.verifyCode != nil {
            options.append("verify_code")
        }
        if info.verifyPwd != nil {
            options.append("verify_pwd")
        }
        if info.verifyOtp != nil {
            options.append("verify_otp")
        }
        if info.verifyCodeSpare != nil {
            options.append("verify_code_spare")
        }
        if info.forgetVerifyCode != nil {
            options.append("verify_forget_code")
        }
        if info.verifyMo != nil {
            options.append("verify_mo")
        }
        if info.verifyFido != nil {
            options.append("verify_fido")
        }
        

        Self.logger.info("n_page_verify_code_steps", additionalData: ["options": options.joined(separator: ",")], method: .local)
    }


    class VerificationCompleteStepHandler {

        private let eventArgs: ServerInfoHandleArgs<VerificationCompletedInfo>
        private let userResolver = PassportUserScope.getCurrentUserResolver() // user:current

        private let currentNavigation: UINavigationController?

        init(eventArgs: ServerInfoHandleArgs<VerificationCompletedInfo>,
             currentNavigation: UINavigationController?) {
            self.eventArgs = eventArgs
            self.currentNavigation = currentNavigation
        }

        func handle() {
            if let wrapper = eventArgs.additional as? VerifyTokenCompletionWrapper, let key = eventArgs.serverInfo.verifyTokenKey {
                wrapper.completion?(.success(key))
            } else if eventArgs.serverInfo.scope != nil, let token = eventArgs.serverInfo.mfaToken, let code = eventArgs.serverInfo.mfaCode {
                handleMFAVerification(token: token, code: code)
            } else {
                PassportEventRegistry.logger.error("n_action_verification_completed_step_error")
                eventArgs.errorHandler(EventBusError.internalError(.clientError("n_action_verification_completed_step_error")))
            }
        }

        private func handleMFAVerification(token: String, code: String) {
            guard let vcs = currentNavigation?.viewControllers,
                  let index = vcs.firstIndex(where: { $0.closeAllStartPoint }) else {
                PassportEventRegistry.logger.errorWithAssertion("close all failed no found start point")
                eventArgs.errorHandler(EventBusError.internalError(.clientError("close all failed no found start point")))
                return
            }
            do {
                let mfaService = try userResolver.resolve(assert: InternalMFANewService.self)
                guard let onSuccess = mfaService.onSuccess, let onError = mfaService.onError else {
                    PassportEventRegistry.logger.error("n_action_verification_error_no_callback")
                    return
                }
                if let navVC = currentNavigation, index == 0 {
                    PassportEventRegistry.logger.info("close all dismiss navigation controller")
                    processMFAService(token: token, code: code, mfaService: mfaService, isNotifyVCNeedCallback: true, onSuccess: onSuccess, onError: onError)
                    navVC.dismiss(animated: true, completion: nil)
                    eventArgs.successHandler()
                    return
                }

                let popToVC = vcs[index - 1]
                PassportEventRegistry.logger.info("close all back to \(type(of: popToVC))")
                processMFAService(token: token, code: code, mfaService: mfaService, isNotifyVCNeedCallback: false, onSuccess: onSuccess, onError: onError)
                currentNavigation?.popToViewController(popToVC, animated: true)
                eventArgs.successHandler()

            } catch {
                PassportEventRegistry.logger.error("n_action_verification_completed_step_userResolver_error")
                eventArgs.errorHandler(EventBusError.internalError(.clientError("n_action_verification_completed_step_userResolver_error")))
            }
        }

        private func processMFAService(token: String, code: String, mfaService: InternalMFANewService, isNotifyVCNeedCallback: Bool, onSuccess: ((String) -> Void), onError: ((NewMFAServiceError) -> Void)) {
            switch (token.isEmpty, code.isEmpty) {
                case (false, true): //First Party
                mfaService.setLoginNaviMFAResult(loginNaviMFAResult: .token(token), needSendMFAResultcWhenDissmiss: isNotifyVCNeedCallback)
                if !isNotifyVCNeedCallback {
                    onSuccess(token)
                }
                case (true, false): // Third Party
                mfaService.setLoginNaviMFAResult(loginNaviMFAResult: .code(code), needSendMFAResultcWhenDissmiss: isNotifyVCNeedCallback)
                if !isNotifyVCNeedCallback {
                    onSuccess(code)
                }
                default:
                    PassportEventRegistry.logger.error("n_action_verification_completed_step_error")
                    eventArgs.errorHandler(EventBusError.internalError(.clientError("n_action_verification_completed_step_error")))
                    if !isNotifyVCNeedCallback {
                        onError(NewMFAServiceError.otherError(errorMessage: "n_action_verification_completed_step_error"))
                    }
            }
        }
    }
}

extension UIViewController {
    /// 标记流程起点 用于关闭流程时候返回
    func setCloseAllStartPointIfHas(additional: Codable?) {
        if let info = additional as? [String: Any],
        ((info[CommonConst.closeAllStartPointKey] as? Bool) == true) || (info[CommonConst.closeAllStartPointKey] as? String) == "true" {
            self.closeAllStartPoint = true
        }
    }
}
