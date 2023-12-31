//
//  PassportUserServiceImpl.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/6/28.
//

import LarkAccountInterface
import LarkContainer
import LarkEnv
import LKCommonsLogging
import RxSwift
import UniverseDesignToast

class PassportUserServiceImpl {
    static let logger = Logger.plog(PassportUserServiceImpl.self, category: "LarkAccount.PassportUserServiceImpl")

    let resolver: UserResolver

    let loginService: V3LoginService
    let userManager: UserManager
    let envManager: EnvironmentInterface
    let disposableLoginManager: DisposableLoginManager
    let passportService: PassportService
    let openAPIAuthSerivce: OpenAPIAuthService
    let unregisterService: UnregisterService
    let realNameVerifyAPI: RealnameVerifyAPI

    let disposeBag = DisposeBag()

    let userInfo: V4UserInfo

    init(resolver: UserResolver) throws {
        self.resolver = resolver

        loginService = try resolver.resolve(assert: V3LoginService.self)
        userManager = try resolver.resolve(assert: UserManager.self)
        envManager = try resolver.resolve(assert: EnvironmentInterface.self)
        disposableLoginManager = try resolver.resolve(assert: DisposableLoginManager.self)
        passportService = try resolver.resolve(assert: PassportService.self)
        openAPIAuthSerivce = try resolver.resolve(assert: OpenAPIAuthService.self)
        unregisterService = try resolver.resolve(assert: UnregisterService.self)
        realNameVerifyAPI = try resolver.resolve(assert: RealnameVerifyAPI.self)

        if let userInfo = userManager.getUser(userID: resolver.userID) {
            self.userInfo = userInfo
        } else {
            Self.logger.error("n_action_user_service_user_not_found", body: "user with uid: \(resolver.userID) not found; compatible mode enabled: \(resolver.compatibleMode)", method: .local)

            if resolver.compatibleMode {
                self.userInfo = userManager.foregroundUser ?? UserManager.placeholderUser // user:current
            } else {
                throw V3LoginError.badLocalData("User not found")
            }
        }
    }
}

extension PassportUserServiceImpl: PassportUserService {

    var state: Observable<PassportUserState> {
        return passportService.state
            .compactMap({ [weak self] state in
                guard let self = self else { return nil }

                guard let user = state.user, self.user.userID == user.userID else {
                    return nil
                }

                let newState = PassportUserState(user: self.user, loginState: state.loginState, action: state.action)
                Self.logger.info("n_action_user_service_state_did_change", body: "\(newState.description)")
                return newState
            })
    }

    var user: User {
        // 尽量使用最新的 userInfo 内容，保证头像之类的数据更新
        if let u = userManager.getUser(userID: resolver.userID) {
            return u.makeUser()
        }
        return userInfo.makeUser()
    }

    var userTenant: Tenant {
        return user.tenant
    }

    var userTenantBrand: TenantBrand {
        return envManager.tenantBrand
    }

    var userTenantGeo: String? {
        return user.tenant.tenantGeo
    }

    var isFeishuBrand: Bool {
        return userTenantBrand == .feishu
    }

    var userUnit: String {
        if let unit = user.userUnit {
            return unit
        }

        return envManager.env.unit
    }

    var userGeo: String {
        return user.geo
    }

    var isChinaMainlandGeo: Bool {
        return EnvManager.validateCountryCodeIsChinaMainland(userGeo)
    }

    /// 外部获取 suiteSessionKeyWithDomains 的唯一接口
    var sessionKeyWithDomains: [String: [String : String]]? {

        guard let sessionKeyWithDomains = userInfo.suiteSessionKeyWithDomains else {
            Self.logger.warn("n_action_interface_extension_sessionKeyWithDomains", body: "domainsWithSession is nil")
            return nil
        }

        var domainsWithSession = ""
        for (domain, value) in sessionKeyWithDomains {
            domainsWithSession.append(contentsOf: " \(domain) : \(value["value"]?.desensitized() ?? "null"), ")
        }
        Self.logger.info("n_action_interface_extension_sessionKeyWithDomains", body: "content: \(domainsWithSession)")

        return sessionKeyWithDomains
    }

    func checkUnRegisterStatus(scope: UnregisterScope?) -> Observable<CheckUnRegisterStatusModel> {
        return Observable.create({ [weak self] (ob) -> Disposable in
            guard let self = self else { return Disposables.create() }

            self.unregisterService.checkUnRegisterStatus(scope: scope?.rawValue, success: { (_,stepInfo) in
                do {
                    let dict = stepInfo ?? [:]
                    let data = try JSONSerialization.data(withJSONObject: dict, options: .init())
                    let model = try JSONDecoder().decode(CheckUnRegisterStatusModel.self, from: data)
                    ob.onNext(model)
                    ob.onCompleted()
                } catch {
                    Self.logger.error(
                        "can not decode json dic to info \(CheckUnRegisterStatusModel.self) error: \(error)"
                    )
                    ob.onError(error)
                }
            }, error: { (error) in
                ob.onError(error)
            })
            return Disposables.create()
        })
    }

    func pushToTeamConversion(
        fromNavigation nav: UINavigationController,
        trackPath: String?
    ) {
        guard let loadingVC = PassportNavigator.getUserScopeTopMostVC(userResolver: resolver) else {
            Self.logger.errorWithAssertion("no loading vc for recoverAccountAppLink")
            return
        }
        guard let window = PassportNavigator.getUserScopeKeyWindow(userResolver: resolver) else {
            Self.logger.errorWithAssertion("no loading vc for mainSceneWindow")
            return
        }
        let context = UniContextCreator.create(.operationCenter)
        PassportBusinessContextService.shared.triggerChange(.joinTeam)
        UDToast.showDefaultLoading(on: window)
        let errorHandler = V3ErrorHandler(vc: loadingVC, context: UniContextCreator.create(.operationCenter), showToastOnWindow: true)
        loginService.pushToTeamConversion(
            navigation: nav,
            trackPath: trackPath,
            context: context,
            success: {
                UDToast.removeToast(on: window)
            }, failure: { error in
                errorHandler.handle(error)
            })
    }

    func joinTeam(withQRUrl url: String, fromVC: UIViewController, result: @escaping (Bool) -> Void) -> Bool {
        let context = UniContextCreator.create(.operationCenter)
        PassportBusinessContextService.shared.triggerChange(.joinTeam)
        return loginService.joinTeam(withQRUrl: url, fromVC: fromVC, result: result, context: context)
    }

    func getCurrentSecurityPwdStatus() -> Observable<(Bool, Bool)> {
        return Observable<(Bool, Bool)>.create({ (observer) -> Disposable in
            self.loginService.getCurrentSecurityPwdStatus(callback: { (isOpen, error) in
                if error != nil {
                    observer.onNext((isOpen, false))
                    observer.onCompleted()
                } else {
                    observer.onNext((isOpen, true))
                    observer.onCompleted()
                }
            })
            return Disposables.create()
        })
    }

    func pushSecurityPwdSettingViewController(from: UIViewController) {
        loginService.openAccountSecurityCenter(for: .securityPasswordSetting, from: from)
    }

    func getSecurityStatus(appId: String, result: @escaping SecurityResult) {
        loginService.getSecurityStatus(appId: appId, result: result, context: UniContextCreator.create(.unknown))
    }

    func getAccountPhoneNumbers() -> Observable<[LarkAccountInterface.PhoneNumber]> {
        let loginService = self.loginService
        return Observable<[LarkAccountInterface.PhoneNumber]>.create { (observer) -> Disposable in
            loginService.getAccountPhoneNumbers { (res) in
                switch res {
                case .failure(let error):
                    observer.onError(error)
                case .success(let phoneNumbers):
                    observer.onNext(phoneNumbers
                        .map({ LarkAccountInterface.PhoneNumber($0.contryCode, $0.phoneNumber) }))
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    func verifyContactPoint(
        scope: VerifyScope,
        contact: String,
        contactType: ContactType,
        viewControllerHandler: @escaping (Result<UIViewController, Error>) -> Void,
        completionHandler: @escaping (Result<VerifyToken, Error>) -> Void
    ) {
        loginService.verifyContactPoint(verifyScope: scope, contact: contact, contactType: contactType.rawValue, context: UniContextCreator.create(.unknown), viewControllerHandler: viewControllerHandler, completionHandler: completionHandler)
    }

    func generateDisposableLoginToken(identifier: String, completion: @escaping (Result<DisposableLoginInfo, DisposableLoginError>) -> Void) {
        Self.logger.info("received generateDisposableLoginToken call, identifier: \(identifier)")
        self.disposableLoginManager.generateDisposableLoginToken(identifier: identifier, completion: completion)
    }

    func startRealNameVerificationFromQRCode(params: [String : Any], completion: ((String?) -> Void)?) {
        Self.logger.info("n_action_general_qr_scan_req")
        realNameVerifyAPI.startVerificationFromQRCode(params: params).subscribe { step in
            Self.logger.info("n_action_general_qr_scan_succ", body: "nextStep:\(step.stepData.nextStep)")
            completion?(nil)
            LoginPassportEventBus.shared.post(event: step.stepData.nextStep, context: V3RawLoginContext(stepInfo: step.stepData.stepInfo, additionalInfo: CommonConst.closeAllParam, context: nil), success: { }, error: { _ in })
        } onError: { error in
            Self.logger.error("n_action_general_qr_scan_err")
            completion?(error.localizedDescription)
        }
    }

    func requestOpenAPIAuth(params: LarkAccountInterface.OpenAPIAuthParams, completion: @escaping ((LarkAccountInterface.OpenAPIAuthResult) -> Void)) {
        openAPIAuthSerivce.performAuthInfoRequest(params: params, completion: completion)
    }

}
