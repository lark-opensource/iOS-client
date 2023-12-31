//
//  EventBus+LoginRegister.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/8/28.
//

import Foundation
import LKCommonsLogging
import Homeric
import RxRelay
import RxSwift
import LarkPerf
import UniverseDesignToast
import LarkAlertController
import LarkUIKit
import EENavigator
import LarkAccountInterface
import UIKit

// MARK: LoginRegister
// MARK: interface api
extension V3LoginService {

    public func loginVC(fromGuide: Bool, context: UniContextProtocol) -> UIViewController {
        Self.logger.info("loginRegisterNavigation is used for loginVC", method: .local)
        let vc = createLoginVC(fromGuide: fromGuide, context: context)
        let navigation = LoginNaviController(rootViewController: vc)
        return navigation
    }

    public func registerVC(fromGuide: Bool, info: V3CreateTenantInfo, context: UniContextProtocol) -> UIViewController {
        Self.logger.debug("loginRegisterNavigation is used for registerVC")
        let loginVC = createLoginVC(fromGuide: false, context: context)
        /// 目的禁用掉展开动画
        /// 显示的是第二个页面（注册），第一个页面（登录）没有layout，后退会有展开的动画
        loginVC.view.layoutIfNeeded()
        let registerVC = createRegisterVC(fromGuide: fromGuide, info: info, context: context)
        let navigation = LoginNaviController()
        navigation.viewControllers = [loginVC, registerVC]
        return navigation
    }

}

// MARK: service
extension V3LoginService {
    public func createLoginVC(
        fromGuide: Bool = false,
        fromUserCenter: Bool = false,
        context: UniContextProtocol
        ) -> UIViewController {
        #if SUITELOGIN_KA
        let vc = idpWebViewService.loginPageForIDPName(nil, context: context, success: { (idpServiceStep) in
            switch idpServiceStep {
            case .stepData(let step, let stepInfo):
                LoginPassportEventBus.shared.post(
                    event: step,
                    context: V3RawLoginContext(stepInfo: stepInfo, context: context),
                    success: {},
                    error: { _ in }
                )
            default:
                break
            }
        }, error: { _ in })
        ///warning: 这里返回的vc不能是NavigationVC 否则会出现闪退问题
        ///https://bits.bytedance.net/bytebus/devops/code/detail/5607468?cr_tab=eyJpIjoxNTA1NjcsIm4iOiJNb2R1bGVzL1Bhc3Nwb3J0LyJ9&tab=changes
        return vc
        #else
        let vm = V3LoginViewModel(
            step: PassportStep.login.rawValue,
            process: .login,
            config: generateInputCredentialConfig(),
            context: context
        )
        vm.fromLaunchGuide = fromGuide
        vm.fromUserCenter = fromUserCenter
        PassportBusinessContextService.shared.triggerChange(fromUserCenter ? .innerLoginOrRegister : .outerLoginOrRegister)
        let vc = V3InputCredentialViewController(vm: vm)
        return vc
        #endif
    }

    public func createSaasLoginVC(
        fromGuide: Bool = false,
        fromUserCenter: Bool = false,
        enableQRCodeLogin: Bool = true,
        context: UniContextProtocol
        ) -> UIViewController {
        var loginConfig = generateInputCredentialConfig()
        let vm = V3LoginViewModel(
            step: PassportStep.login.rawValue,
            process: .login,
            config: generateInputCredentialConfig(),
            context: context
        )
        vm.fromLaunchGuide = fromGuide
        vm.fromUserCenter = fromUserCenter
        PassportBusinessContextService.shared.triggerChange(fromUserCenter ? .innerLoginOrRegister : .outerLoginOrRegister)
        let vc = V3InputCredentialViewController(vm: vm)
        return vc
    }

    public func createRegisterVC(
        fromGuide: Bool = false,
        info: V3CreateTenantInfo,
        inputInfo: V3InputInfo? = nil,
        simplifyLogin: Bool = false,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V3TenantCreateViewModel(step: PassportStep.prepareTenant.rawValue, createInfo: info, api: passportAPI, context: context)
        let vc = V3TenantCreateViewController(vm: vm)
        return vc
    }

    public func createRegisterViewController(
        fromGuide: Bool = false,
        personalInfo: V4PersonalInfo,
        userCenterInfo: V4UserOperationCenterInfo? = nil,
        inputInfo: V3InputInfo? = nil,
        simplifyLogin: Bool = false,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V4RegisterViewModel(
            step: PassportStep.setPersonalInfo.rawValue,
            process: .register,
            config: generateInputCredentialConfig(),
            personalInfo: personalInfo,
            userCenterInfo: userCenterInfo,
            inputInfo: inputInfo,
            simplifyLogin: simplifyLogin,
            context: context
        )

        vm.fromLaunchGuide = fromGuide
        let vc = V4RegisterInputCredentialViewController(vm: vm)
        return vc
    }

    private func generateInputCredentialConfig() -> V3InputCredentialConfig {
        var defaultConfig: V3NormalConfig
        var defaultLoginType: SuiteLoginMethod
        var defaultRegisterType: SuiteLoginMethod
        switch store.configEnv {
        case V3ConfigEnv.lark:
            defaultLoginType = .email
            defaultConfig = configInfo.larkConfig
            defaultRegisterType = .email
        case V3ConfigEnv.feishu:
            defaultLoginType = .phoneNumber
            defaultConfig = configInfo.feishuConfig
            defaultRegisterType = .phoneNumber
        default:
            defaultLoginType = .phoneNumber
            defaultConfig = configInfo.feishuConfig
            defaultRegisterType = .phoneNumber
        }
        let type = userLoginConfig?.loginType ?? defaultLoginType
        let countryCode = userLoginConfig?.regionCode ?? defaultConfig.defaultCountryCode
        let defaultRegisterRegionCode: String
        if defaultConfig.enableChangeRegionCode {
            defaultRegisterRegionCode = userLoginConfig?.regionCode ?? defaultConfig.registerRegionCode(for: store.configEnv)
        } else {
            defaultRegisterRegionCode = defaultConfig.registerRegionCode(for: store.configEnv)
        }
        let config = V3InputCredentialConfig(
            loginType: type,
            countryCode: countryCode,
            emailRegex: defaultConfig.emailRegex,
            enableMobileReg: defaultConfig.enableMobileRegister,
            enableEmailReg: defaultConfig.enableEmailRegister,
            registerType: defaultRegisterType,
            registerCountryCode: defaultRegisterRegionCode,
            enableLoginJoinType: defaultConfig.getEnableLoginJoinType(),
            enableRegisterJoinType: defaultConfig.getEnableRegisterJoinType()
        )
        return config
    }

    func createRecoverAccountCarrierVC(
        recoverAccountCarrierInfo: V3RecoverAccountCarrierInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V3RecoverAccountCarrierViewModel(
            step: PassportStep.recoverAccountCarrier.rawValue,
            api: self.passportAPI,
            recoverAccountCarrierInfo: recoverAccountCarrierInfo,
            from: from,
            context: context,
            switchUserSub: nil
        )
        let vc = V3RecoverAccountCarrierViewController(vm: vm)
        return vc
    }
    
    func createRetrieveOpThreeVC(
        recoverAccountCarrierInfo: V4RetrieveOpThreeInfo,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V4RecoverAccountCarrierViewModel(
            step: PassportStep.recoverAccountCarrier.rawValue,
            api: self.passportAPI,
            recoverAccountCarrierInfo: recoverAccountCarrierInfo,
            context: context,
            switchUserSub: nil
        )
        let vc = V4RecoverAccountCarrierViewController(vm: vm)
        return vc
    }

    func createRecoverAccountChooseVC(
        step: String,
        recoverAccountChooseInfo: V3RecoverAccountChooseInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V3RecoverAccountChooseViewModel(
            step: step,
            api: self.passportAPI,
            recoverAccountChooseInfo: recoverAccountChooseInfo,
            from: from,
            context: context,
            switchUserSub: nil
        )
        let vc = V3RecoverAccountChooseViewController(vm: vm)
        return vc
    }

    func createBioAuthVC(
        step: String,
        bioAuthInfo: V4BioAuthInfo,
        additionalInfo: Codable?,
        from: RecoverAccountSourceType,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = BioAuthViewModel(
            step: step,
            additionalInfo: additionalInfo,
            api: self.passportAPI,
            bioAuthInfo: bioAuthInfo,
            from: from,
            context: context,
            switchUserSub: nil
        )
        let vc = BioAuthViewController(vm: vm)
        return vc
    }

    func createAuthTypeVC(
        step: String,
        authTypeInfo: AuthTypeInfo,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = AuthTypeViewModel(step: step,
                                   stepInfo: authTypeInfo,
                                   context: context)
        
        let vc = AuthTypeViewController(vm: vm)
        return vc
    }

    func createRecoverAccountBankVC(
        recoverAccountBankInfo: V3RecoverAccountBankInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V3RecoverAccountBankViewModel(
            step: PassportStep.recoverAccountBank.rawValue,
            api: self.passportAPI,
            recoverAccountBankInfo: recoverAccountBankInfo,
            from: from,
            context: context
        )
        let vc = V3RecoverAccountBankViewController(vm: vm)
        return vc
    }

    func createSetInputCredentialVC(
        setInputCredentialInfo: V3SetInputCredentialInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V3SetInputCredentialViewModel(
            step: PassportStep.setInputCredential.rawValue,
            api: self.passportAPI,
            setInputCredentialInfo: setInputCredentialInfo,
            from: from,
            context: context
        )
        let vc = V3SetInputCredentialViewController(vm: vm)
        return vc
    }
    
    func createNewSetCredentialVC(
        setInputCredentialInfo: SetCredentialInfo,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = SetCredentialViewModel.init(setCredentialInfo:setInputCredentialInfo, context: context)
        let vc = SetCredentialViewController(vm: vm)
        return vc
    }

    func createVerifyVC(verifyInfo: V3VerifyInfo, context: UniContextProtocol) -> UIViewController {
        let vm = V3LoginVerifyViewModel(
            step: PassportStep.verifyIdentity.rawValue,
            api: self.passportAPI,
            verifyInfo: verifyInfo,
            context: context,
            switchUserSub: nil
        )
        let vc = V3LoginVerifyViewController(vm: vm)
        return vc
    }

    func createVerifyViewController(verifyInfo: V4VerifyInfo, verifyTokenCompletionWrapper: VerifyTokenCompletionWrapper?, context: UniContextProtocol) -> UIViewController {
        let model = V4LoginVerifyViewModel(
            step: PassportStep.verifyIdentity.rawValue,
            api: passportAPI,
            backToFeed: verifyInfo.backToFeed ?? false,
            verifyInfo: verifyInfo,
            verifyTokenCompletionWrapper: verifyTokenCompletionWrapper,
            context: context
        )
        let controller = V4LoginVerifyViewController(vm: model)
        return controller
    }

    func createTenantCreatedVC(
        _ info: V3CreateTenantInfo,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V3TenantCreateViewModel(step: PassportStep.prepareTenant.rawValue, createInfo: info, api: passportAPI, context: context)
        let vc = V3TenantCreateViewController(vm: vm)
        return vc
    }

    func createSelectUserVC(
        _ info: V4SelectUserInfo,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V3SelectUserViewModel(step: PassportStep.userList.rawValue, stepInfo: info, context: context)
        let vc = V3SelectUserViewController(vm: vm)
        return vc
    }

    func createAppPermissionVC(_ info: AppPermissionInfo, context: UniContextProtocol) -> UIViewController {
        let vm = AppPermissionViewModel(step: PassportStep.appPermission.rawValue, stepInfo: info, context: context)
        let vc = AppPermissionViewController(viewModel: vm)
        return vc
    }

    func createApplyFormVC(_ info: ApplyFormInfo, context: UniContextProtocol) -> UIViewController {
        let vm = ApplyFormViewModel(step: PassportStep.applyForm.rawValue, stepInfo: info, context: context)
        let vc = ApplyFormViewController(viewModel: vm)
        return vc
    }

    func createV3SetPwdVC(
        _ info: V3SetPwdInfo,
        api: V3SetPwdAPIProtocol,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V3SetPwdViewModel(
            step: PassportStep.setPwd.rawValue,
            setPwdInfo: info,
            api: api,
            context: context,
            switchUserSub: nil
        )
        let vc = V3SetPwdViewController(vm: vm)
        return vc
    }

    func createSetPwdVC(
        _ info: V4SetPwdInfo,
        api: SetPwdAPIProtocol,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V4SetPwdViewModel(
            step: PassportStep.setPwd.rawValue,
            setPwdInfo: info,
            api: api,
            context: context,
            switchUserSub: nil
        )
        let vc = V4SetPwdViewController(vm: vm)
        return vc
    }

    func createSetNameVC(_ info: V4SetNameInfo, context: UniContextProtocol) -> UIViewController {
        let vm = V3SetNameViewModel(step: PassportStep.setName.rawValue, setNameInfo: info, context: context)
        let vc = V3SetNameViewController(vm: vm)
        return vc
    }

    func createOperationCenter(_ info: V4UserOperationCenterInfo, context: UniContextProtocol) -> UIViewController {
        let vm = UserOperationCenterViewModel(step: PassportStep.operationCenter.rawValue, userCenterInfo: info, context: context)
        let vc = UserOperationCenterViewController(vm: vm)
        return vc
    }

    func createMagicLinkVC(info: V3MagicLinkInfo, context: UniContextProtocol) -> MagicLinkViewController {
        let vm = MagicLinkViewModel(stepInfo: info, context: context)
        return MagicLinkViewController(vm: vm)
    }
    
    func createAddEmailViewController(info: AddMailStepInfo, context: UniContextProtocol) -> UIViewController {
        let vm = AddEmailViewModel(step: PassportStep.addEmail.rawValue,
                                  addMailStepInfo: info,
                                  inputConfig: generateInputCredentialConfig(),
                                  context: context)
        return AddEmailViewController(vm: vm)
        
    }
    
    func createSetSpareCredentialViewController(info: SetSpareCredentialInfo, context: UniContextProtocol) -> UIViewController {
        let vm = SetSpareCredentialViewModel(step: PassportStep.setSpareCredential.rawValue,
                                             setSpareCredentialInfo: info,
                                             context: context)
        return SetSpareCredentialViewController(vm: vm)
    }

    func createShowPageViewController(info: ShowPageInfo, context: UniContextProtocol) -> UIViewController {
        let vm = EmptyPageViewModel(step: PassportStep.showPage.rawValue,
                                    showPageInfo: info,
                                    context: context)
        return EmptyPageViewController(vm: vm)
    }
}

// MARK: JoinTeam

typealias JoinTeamResult = (_ success: Bool) -> Void

class JoinTeamTokenUtil {
    static func getTeamCode(params: [String: String]) -> String? {
        return params[CommonConst.teamCode]
    }
}

// MARK: - interface api
extension V3LoginService {

    func loginJoinTeamCodeJoin(
        params: [String: String],
        trackPath: String?,
        context: UniContextProtocol
    ) {
        func handle(_ error: Error) {
            if let navigation = self.eventRegistry.currentNavigation() {
                V3ErrorHandler(
                    vc: navigation,
                    context: context
                ).handle(error)
            }
        }
        guard let code = JoinTeamTokenUtil.getTeamCode(params: params) else {
            handle(V3LoginError.badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData))
            V3LoginService.logger.error("loggin not get team code params: \(params)")
            return
        }
        func handleTeamCode() {
            if let navigation = self.eventRegistry.currentNavigation(),
                let loadingVC = navigation.topViewController as? BaseViewControllerLoadingProtocol {
                loadingVC.stopLoading()
            }
            httpClient.cancelAllPendingTask()
            if let window = self.eventRegistry.currentNavigation()?.view.window ?? PassportNavigator.keyWindow {
                UDToast.showDefaultLoading(on: window)
            } else {
                Self.logger.errorWithAssertion("no window for handleTeamCode")
            }

            self.doTeamCodeJoin(code: code, trackPath: trackPath, context: context)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    if let window = self.eventRegistry.currentNavigation()?.view.window ?? PassportNavigator.keyWindow {
                        UDToast.removeToast(on: window)
                    }
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    if let window = self.eventRegistry.currentNavigation()?.view.window ?? PassportNavigator.keyWindow {
                        UDToast.removeToast(on: window)
                    }
                    handle(error)
                })
                .disposed(by: self.disposeBag)
        }
        if let navigation = self.eventRegistry.currentNavigation(),
            let presentedVC = navigation.presentedViewController {
            presentedVC.dismiss(animated: true, completion: {
                handleTeamCode()
            })
        } else {
            handleTeamCode()
        }
    }

    private func doTeamCodeJoin(
        code: String,
        trackPath: String?,
        context: UniContextProtocol
    ) -> Observable<Void> {
        //Todo: xiaolin
        return .just(())
    }

    func initOfficialEmail(
        tenantId: String,
        flowType: String?,
        userCenterInfo: V4UserOperationCenterInfo,
        success: @escaping () -> Void,
        error: @escaping (EventBusError) -> Void,
        context: UniContextProtocol
    ) {
        userCenterAPI
            .initOfficialEmail(serverInfo: userCenterInfo, tenantId: tenantId, context: context)
            .post(userCenterInfo, context: context)
            .subscribe(onNext: { (_) in
                Self.logger.info("v4 initOfficialEmail success")
                success()
            }, onError: { (postError) in
                if let err = postError as? V3LoginError {
                    Self.logger.error("v4 initOfficialEmail login error: \(err)")
                    error(EventBusError.internalError(err))
                } else if let err = postError as? EventBusError {
                    Self.logger.error("v4 initOfficialEmail event bus error: \(err)")
                    error(err)
                } else {
                    Self.logger.errorWithAssertion("v4 initOfficialEmail error but not EventbusError or V3LoginError")
                    error(EventBusError.internalError(.badServerData))
                }
            }).disposed(by: self.disposeBag)
    }

    func verifyContactPoint(
        verifyScope: VerifyScope,
        contact: String?,
        contactType: Int,
        context: UniContextProtocol,
        viewControllerHandler: @escaping (Result<UIViewController, Error>) -> Void,
        completionHandler: @escaping (Result<VerifyToken, Error>) -> Void
    ) {
        let wrapper = VerifyTokenCompletionWrapper(completion: completionHandler)
        passportAPI
            .applyVerifyTokenForPublic(contact: contact, contactType: contactType, verifyScope: verifyScope, context: context)
            .post(wrapper, vcHandler: { vc in
                guard let vc = vc else {
                    viewControllerHandler(.failure(V3LoginError.badServerData))
                    return
                }
                viewControllerHandler(.success(vc))
            }, context: context)
            .subscribe(onNext: { (_) in

            }, onError: { error in
                viewControllerHandler(.failure(V3LoginError.badServerData))
            })
            .disposed(by: disposeBag)
    }

    func pushToTeamConversion(
        navigation: UINavigationController,
        trackPath: String?,
        context: UniContextProtocol,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void
    ) {
        SuiteLoginTracker.track(Homeric.CLICK_USE_BY_ORGS, params: [TrackConst.path: trackPath ?? ""])
        var trackInfo: V3LoginAdditionalInfo?
        if let path = trackPath {
            trackInfo = V3LoginAdditionalInfo(trackPath: path)
        }
        func handler(vc: UIViewController?) {
            if let vc = vc {
                let nav = LoginNaviController(rootViewController: vc)
                nav.modalPresentationStyle = .formSheet
                navigation.present(nav, animated: true, completion: nil)
            }
        }
        userCenterAPI.fetchUserCenter().post(trackInfo, vcHandler: Display.pad ? handler : nil, context: context).subscribe(onNext: { (_) in
            success()
        }, onError: { [weak self] (error) in
            if let error = error as? V3LoginError, case .badServerCode(let info) = error, info.type == .noMobileCredential {
                self?.handleNoMobileCredentialError(
                    detail: info.detail,
                    context: context
                )
                success()
            } else {
                failure(error)
            }
        }).disposed(by: disposeBag)
    }

    func loggedTeamCodeJoin(
        params: [String: String],
        navigation: UINavigationController,
        trackPath: String?,
        context: UniContextProtocol
    ) {
        func handle(_ error: Error) {
            V3ErrorHandler(
                vc: navigation,
                context: context,
                contextExpiredPostEvent: false,
                showToastOnWindow: true
            ).handle(error)
        }
        guard let code = JoinTeamTokenUtil.getTeamCode(params: params) else {
            handle(V3LoginError.badServerData)
            V3LoginService.logger.error("logged not get team code params: \(params)")
            return
        }
    }

    // join team by general QRCode scan
    func joinTeam(
        withQRUrl url: String,
        fromVC: UIViewController,
        result: @escaping JoinTeamResult,
        context: UniContextProtocol
    ) -> Bool {
        Self.logger.info("n_action_scan_try_join_team")
        guard let joinUrl = URL(string: url), isValidQRCodeJoinTeamURL(joinUrl) else {
            Self.logger.error("n_action_qrcode_join_team_invalid_url")
            return false
        }

        let errorHandler = V3ErrorHandler(
            vc: fromVC,
            context: context,
            contextExpiredPostEvent: false,
            showToastOnWindow: true
        )
        UDToast.showDefaultLoading(on: fromVC.view)
        self.confirmCode(
            url: url,
            fromVC: fromVC,
            cancel: {
                UDToast.removeToast(on: fromVC.view)
                V3LoginService.logger.info("qrcode join team canceled")
                result(false)
            }, result: { error in
                UDToast.removeToast(on: fromVC.view)
                if let err = error {
                    V3LoginService.logger.error("n_action_qrcode_join_team_error", error: err)
                    if let loginError = err as? V3LoginError {
                        errorHandler.handleLogin(loginError) {
                            result(false)
                        }
                    } else {
                        errorHandler.handle(err)
                        result(false)
                    }
                } else {
                    V3LoginService.logger.info("n_action_qrcode_join_team_success")
                    result(true)
                }
            }, context: context)
        return true
    }
}

// MARK: Credentail

extension V3LoginService {
    func credentialList(context: UniContextProtocol) -> UIViewController {
        guard let url = webUrl(for: .accountManagement) else {
            Self.logger.error("Did not fetch account management web url.")
            return UIViewController()
        }
        let vc = dependency.createWebViewController(url, customUserAgent: nil)
        return vc
    }
}

// MARK: service
extension V3LoginService {
    func createJoinTenant(
        _ info: V4JoinTenantInfo,
        additionalInfo: Codable?,
        api: JoinTeamAPIProtocol,
        useHUDLoading: Bool = false,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V3JoinTenantViewModel(
            step: PassportStep.joinTenant.rawValue,
            joinTenantInfo: info,
            api: api,
            context: context
        )
        vm.additionalInfo = additionalInfo
        let vc = V3JoinTenantViewController(vm: vm)
        vc.useHUDLoading = useHUDLoading
        return vc
    }

    func createJoinTenantCode(
        _ info: V4JoinTenantCodeInfo,
        additionalInfo: Codable?,
        api: JoinTeamAPIProtocol,
        useHUDLoading: Bool = false,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = V4JoinTenantCodeViewModel(
            step: PassportStep.joinTenantCode.rawValue,
            joinTenantCodeInfo: info,
            api: api,
            context: context
        )
        vm.additionalInfo = additionalInfo
        let vc = V3JoinTenantCodeViewController(vm: vm)
        vc.useHUDLoading = useHUDLoading
        return vc
    }

    func createJoinTenantScan(
        _ info: V4JoinTenantScanInfo,
        additionalInfo: Codable?,
        api: JoinTeamAPIProtocol,
        useHUDLoading: Bool = false,
        context: UniContextProtocol,
        externalHandler: ((String) -> Void)? = nil
    ) -> UIViewController {
        let vm = V3JoinTenantScanViewModel(
            step: PassportStep.joinTenantScan.rawValue,
            joinTenantScanInfo: info,
            api: api,
            context: context,
            externalHandler: externalHandler
        )
        vm.additionalInfo = additionalInfo
        let vc = V3JoinTenantScanViewController(vm: vm)
        vc.useHUDLoading = useHUDLoading
        return vc
    }

    func createJoinTenantReview(
        _ info: V4JoinTenantReviewInfo,
        additionalInfo: Codable?,
        api: JoinTeamAPIProtocol,
        useHUDLoading: Bool = false,
        context: UniContextProtocol
    ) -> UIViewController {
        let vm = JoinTenantReviewModel(step: PassportStep.joinTenantReview.rawValue, stepInfo: info, context: context)
        vm.additionalInfo = additionalInfo
        let vc = JoinTenantReviewViewController(vm: vm)
        vc.useHUDLoading = useHUDLoading
        return vc
    }

    func createTenantVC(_ info: V3CreateTenantInfo, additionalInfo: Codable?, context: UniContextProtocol) -> UIViewController {
        let vm = V3TenantCreateViewModel(
            step: PassportStep.prepareTenant.rawValue,
            createInfo: info,
            api: joinTeamAPI,
            context: context
        )
        vm.additionalInfo = additionalInfo
        let vc = V3TenantCreateViewController(vm: vm)
        vc.useHUDLoading = true
        return vc
    }
}

extension V3LoginService {

    func handleNoMobileCredentialError(
        detail: [String: Any],
        context: UniContextProtocol
    ) {
        let content = detail[V3.Const.noMobileCredentialMsg] as? String ?? ""
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.suiteLogin.Lark_Login_LackOfPhone)
        alert.setContent(text: content)
        alert.addCancelButton()
        alert.addPrimaryButton(text: I18N.Lark_Login_LackOfPhoneGotoAdd, dismissCompletion:  {
            self.eventRegistry.currentNavigation()?.pushViewController(
                self.credentialList(context: context),
                animated: true
            )
        })
        self.eventRegistry.currentNavigation()?.present(alert, animated: true, completion: nil)
    }

    func confirmCode(
        url: String,
        fromVC: UIViewController,
        cancel: @escaping () -> Void,
        result: @escaping (Error?) -> Void,
        context: UniContextProtocol
    ) {
        UDToast.showDefaultLoading(on: fromVC.view)
        self.joinTeamAPI
        .joinWithQRCode(TeamCodeReqBody(
            type: V4JoinTenantInfo.JoinType.scanQRCode.rawValue,
            qrUrl: url,
            flowType: "logged_join",
            context: context
        ), serverInfo: PlaceholderServerInfo())
        .post(context: context)
        .subscribe(onNext: { _ in
            UDToast.removeToast(on: fromVC.view)
            result(nil)
        }, onError: { (error) in
            UDToast.removeToast(on: fromVC.view)
            result(error)
        }).disposed(by: self.disposeBag)
    }
}

extension V3LoginService {
    func isValidQRCodeJoinTeamURL(_ url: URL) -> Bool {
        // const
        let paramJoin: String = "join"
        let validJoinValue: Int = 1
        let paramTeamName: String = "team_name"
        let validScheme: String = "https"

        func isValidParam(url: URL) -> Bool {
            if let join = url.queryParameters[paramJoin],
                let joinValue = Int(join),
                joinValue == validJoinValue,
                let teamName = url.queryParameters[paramTeamName],
                !teamName.isEmpty {
                return true
            }
            V3LoginService.logger.info("param is not valid \(url.queryParameters)")
            return false
        }

        func isValidHost(url: URL) -> Bool {
            guard let hostWhiteList = configInfo.config(for: store.configEnv).getJoinTeamHostWhitelist() else {
                V3LoginService.logger.error("no join team host whitelist found")
                return false
            }
            let hasValidHost = hostWhiteList.first { (host) -> Bool in
                return url.host?.hasSuffix(host) ?? false
            } != nil
            if !hasValidHost {
                V3LoginService.logger.error("host is not valid \(String(describing: url.host))")
            }
            return hasValidHost
        }
        if url.scheme?.lowercased() == validScheme {
            return isValidHost(url: url) && isValidParam(url: url)
        } else {
            V3LoginService.logger.error("scheme is not valid \(String(describing: url.scheme))")
            return false
        }
    }
}

// MARK: AccountManage

typealias LogoutAction = (@escaping (String?) -> Void) -> Void

extension V3LoginService {
    func accountSafety() -> UIViewController {
        guard let url = webUrl(for: .accountSecurityCenter) else {
            Self.logger.error("Did not fetch account safety web url.")
            return UIViewController()
        }
        let newUrl = WebConfig.commonParamsUrlFrom(url: url, with: [:])
        let vc = dependency.createWebViewController(newUrl, customUserAgent: nil)
        return vc
    }

    func openAccountSecurityCenter(for key: WebUrlKey, from: UIViewController) {
        // 首次进入时，设置accountSecurityStartVC
        // 再次进入时，
        //      如果accountSecurityStartVC在当前导航栈，先pop再打开账号安全中心页；
        //      否则，更新accountSecurityStartVC再打开账号安全中心页
        guard let navi = from.navigationController else {
            Self.logger.errorWithAssertion("from vc doesn't have navigation")
            return
        }
        if let vc = self.accountSecurityStartVC,
           navi.viewControllers.contains(vc) {
            navi.popToViewController(vc, animated: false)
        } else {
            self.accountSecurityStartVC = from
        }

        if let topVC = navi.topViewController {
            Self.logger.info("topVC is: \(type(of: topVC))")
            if !self.openWebUrl(for: key, from: topVC) {
                Self.logger.info("cannot open h5 security center")
            }
        }
    }

    func createEnterpriseLoginVC(
        enterpriseInfo: V3EnterpriseInfo,
        context: UniContextProtocol
    ) -> V3EnterpriseLoginViewController {
        let vm = V3EnterpriseLoginViewModel(
            step: V3NativeStep.enterpriseLogin.rawValue,
            enterpriseInfo: enterpriseInfo,
            defaultDomain: configInfo.config().defaultHostDomain(for: store.configEnv),
            ssoDomains: configInfo.config().getSSODomains(),
            supportedSSODomains: configInfo.config().getSupportedSSODomainList(for: store.configEnv),
            ssoHelpUrl: configInfo.config().ssoHelpUrl,
            context: context
        )
        let vc = V3EnterpriseLoginViewController(vm: vm)
        vc.useHUDLoading = enterpriseInfo.isAddCredential
        return vc
    }

    func registerActionForPostStepLogout(_ logout: @escaping LogoutAction) {
        // 避免多次注册
        self.eventRegistry.eventBus.removeHandler(for: V3NativeStep.logout.rawValue)

        self.eventRegistry.eventBus.register(
                event: V3NativeStep.logout.rawValue,
                handler: CommonEventBusHandler(handleWork: { args in
                    logout({ err in
                        if let e = err {
                            args.errorHandler(EventBusError.internalError(V3LoginError.clientError(e)))
                        } else {
                            args.successHandler()
                        }
                    })
                })
        )
    }
}
