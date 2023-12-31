//
//  MFAService.swift
//  LarkAccount
//
//  Created by bytedance on 2022/4/17.
//

import Foundation
import RxSwift
import LarkContainer
import LKCommonsLogging
import LarkAccountInterface
import UniverseDesignToast
import LarkUIKit
import UIKit

// 旧版本 MFA 服务，安全合规使用，未来将迁移至 MFANewServiceImpl
class MFAService: AccountServiceMFA { // user:current

    static let logger = Logger.plog(MFAService.self, category: "SuiteLogin.MFAService")

    internal var dismissCallback: (() -> Void)?

    private let disposeBag = DisposeBag()

    private let mfaAPI: MFALegacyAPI

    init(resolver: UserResolver?) throws {
        if let r = resolver {
            mfaAPI = try r.resolve(assert: MFALegacyAPI.self)
        } else {
            mfaAPI = try Container.shared.resolve(assert: MFALegacyAPI.self) // user:checked (global-resolve)
        }
    }

    func checkMFAStatus(token: String, scope: String, unit: String?, onResult: @escaping (MFATokenStatus) -> Void, onError: @escaping (Error) -> Void) {
        
        mfaAPI.checkMFAStatus(token: token, scope: scope, unit: unit).subscribe(onNext: {resp in
            if let dataInfo = resp.dataInfo {
                onResult(dataInfo.stepInfo.status)
            } else {
                onError(V3LoginError.badResponse("no step data"))
            }
        }, onError: { error in
            onError(error)
        }).disposed(by: disposeBag)
    }

    func startMFA(token: String, scope: String, unit: String?, from: UIViewController, onSuccess: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        //show loading
        UDToast.showDefaultLoading(on: from.view)

        mfaAPI.startMFA(token: token, scope: scope, unit: unit, context: UniContextCreator.create(.external)).subscribe(onNext: { nextStep in
            LoginPassportEventBus.shared.post(
                event: nextStep.stepData.nextStep,
                context: V3RawLoginContext(
                    stepInfo: nextStep.stepData.stepInfo,
                    additionalInfo: CommonConst.closeAllParam,
                    vcHandler: { [weak self] viewController in
                        if let viewController = viewController {
                            Self.logger.error("n_action_mfa", body: "present vc \(viewController)")
                            let navigation = LoginNaviController(rootViewController: viewController)
                            navigation.dismissCallback = self?.dismissCallback
                            viewController.closeAllStartPoint = true
                            navigation.modalPresentationStyle = Display.pad ? .pageSheet : .fullScreen
                            from.present(navigation, animated: true, completion: nil)
                        } else {
                            Self.logger.error("n_action_mfa", body: "no vc to present")
                            onError(V3LoginError.clientError("no vc to present"))
                        }
                    },
                    context: UniContextCreator.create(.external)
                ),
                success: { onSuccess() }, error: { error in  onError(error) })

        }, onError: { error in
            onError(error)
        }, onCompleted: {
            UDToast.removeToast(on: from.view)
        }).disposed(by: disposeBag)

    }
}

enum NewMFAResult {
    case token(String?)
    case code(String?)
    case none
}

class MFANewServiceImpl: InternalMFANewService {

    var dismissCallback: (() -> Void)?

    private let userResolver: UserResolver
    private let mfaAPI: MFAAPI
    private let loginService: V3LoginService

    static let logger = Logger.plog(MFANewServiceImpl.self, category: "SuiteLogin.MFANewServiceImpl")
    private let disposeBag = DisposeBag()
    var isDoingActionStub : Bool = false
    var onSuccess: ((String) -> Void)?
    var onError: ((NewMFAServiceError) -> Void)?
    var loginNaviMFAResult: NewMFAResult = .none
    var isNotifyVCAppeared: Bool = false
    var needSendMFAResultcWhenDissmiss: Bool = true

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.mfaAPI = try userResolver.resolve(assert: MFAAPI.self)
        self.loginService = try userResolver.resolve(assert: V3LoginService.self)
    }

    func setLoginNaviMFAResult(loginNaviMFAResult: NewMFAResult, needSendMFAResultcWhenDissmiss: Bool) {
        self.loginNaviMFAResult = loginNaviMFAResult
        self.needSendMFAResultcWhenDissmiss = needSendMFAResultcWhenDissmiss
    }

    func checkNewMFAStatus(token: String, scope: String, onResult: @escaping (MFATokenNewStatus) -> Void, onError: @escaping (NewMFAServiceError) -> Void) {

        mfaAPI.checkNewMFAStatus(token: token, scope: scope).subscribe(onNext: {resp in
            if let dataInfo = resp.dataInfo {
                onResult(dataInfo.tokenStatus)
            } else {
                onError(NewMFAServiceError.noStepData)
                Self.logger.error("n_action_mfa_check_status_failed", body: "no step data")
            }
        }, onError: { error in
            onError(NewMFAServiceError.otherError(errorMessage: error.localizedDescription))
            Self.logger.error("n_action_mfa_check_status_failed", body: error.localizedDescription)
        }).disposed(by: disposeBag)
    }


    func startNewMFA(scope: String, from: UIViewController, onSuccess: @escaping (String) -> Void, onError: @escaping (NewMFAServiceError) -> Void) {
        // 如果已经在流程中了...忽略
        guard !isDoingActionStub else {
            Self.logger.info("n_action_mfa_failed", additionalData:["reason":"processing"])
            return
        }
        //设置为处理中
        isDoingActionStub = true
        let hud = UDToast.showDefaultLoading(on: from.view)
        self.onSuccess = onSuccess
        self.onError = onError
        self.isNotifyVCAppeared = false
        self.needSendMFAResultcWhenDissmiss = true
        self.loginNaviMFAResult = .none
        let navigation = LoginNaviController()
        let notifyVC = NewMFANotificationViewController()
        mfaAPI.startNewMFA(scope: scope, context: UniContextCreator.create(.external)).subscribe(onNext: { nextStep in
            LoginPassportEventBus.shared.post(
                event: nextStep.stepData.nextStep,
                context: V3RawLoginContext(
                    stepInfo: nextStep.stepData.stepInfo,
                    additionalInfo: CommonConst.closeAllParam,
                    vcHandler: { [weak self] viewController in
                        if let viewController = viewController, let self = self {
                            notifyVC.modalPresentationStyle = Display.pad ? .pageSheet : .fullScreen
                            from.present(notifyVC, animated: false)
                            Self.logger.error("n_action_mfa", body: "present vc \(viewController)")
                            let navigation = LoginNaviController(rootViewController: viewController)
                            navigation.dismissCallback = self.dismissCallback
                            viewController.closeAllStartPoint = true
                            navigation.modalPresentationStyle = Display.pad ? .pageSheet : .fullScreen
                            notifyVC.present(navigation, animated: true, completion: {
                                self.isNotifyVCAppeared = true
                            })
                        } else {
                            Self.logger.error("n_action_mfa_failed", body: "no vc to present")
                            onError(NewMFAServiceError.noVCPresent)
                            self?.isDoingActionStub = false
                        }
                    },
                    context: UniContextCreator.create(.external)
                ),
                success: {
                    Self.logger.info("LoginPassportEventBus post success")
                }, error: { error in
                    Self.logger.info("LoginPassportEventBus post failed: \(error.localizedDescription)")
                })

        }, onError: { error in
            onError(NewMFAServiceError.otherError(errorMessage: error.localizedDescription))
            Self.logger.error("n_action_mfa_check_status_failed", body: error.localizedDescription)
            self.isDoingActionStub = false
            hud.remove()
            if let topVC = navigation.visibleViewController {
                let errorHandler = V3ErrorHandler(vc: topVC, context: UniContextCreator.create(.external), showToastOnWindow: true)
                errorHandler.handle(error)
            }
            notifyVC.dismiss(animated: false)
        }, onCompleted: {
            UDToast.removeToast(on: from.view)
            self.isDoingActionStub = false
            hud.remove()
            notifyVC.dismiss(animated: false)
        }).disposed(by: disposeBag)

    }


    func startThirdPartyNewMFA(key: String, from: UIViewController, onSuccess: @escaping (String) -> Void, onError: @escaping (NewMFAServiceError) -> Void) {
        // 如果已经在流程中了...忽略
        guard !isDoingActionStub else {
            Self.logger.info("n_action_mfa_failed", additionalData:["reason":"processing"])
            return
        }
        //设置为处理中
        isDoingActionStub = true

        let hud = UDToast.showDefaultLoading(on: from.view)
        self.onSuccess = onSuccess
        self.onError = onError
        self.isNotifyVCAppeared = false
        self.needSendMFAResultcWhenDissmiss = true
        self.loginNaviMFAResult = .none
        let navigation = LoginNaviController()
        let notifyVC = NewMFANotificationViewController()

        mfaAPI.startThirdPartyNewMFA(key: key, context: UniContextCreator.create(.external)).subscribe(onNext: { nextStep in
            LoginPassportEventBus.shared.post(
                event: nextStep.stepData.nextStep,
                context: V3RawLoginContext(
                    stepInfo: nextStep.stepData.stepInfo,
                    additionalInfo: CommonConst.closeAllParam,
                    vcHandler: { [weak self] viewController in
                        if let viewController = viewController, let self = self {
                            notifyVC.modalPresentationStyle = Display.pad ? .pageSheet : .fullScreen
                            from.present(notifyVC, animated: false)
                            Self.logger.error("n_action_mfa", body: "present vc \(viewController)")
                            let navigation = LoginNaviController(rootViewController: viewController)
                            navigation.dismissCallback = self.dismissCallback
                            viewController.closeAllStartPoint = true
                            navigation.modalPresentationStyle = Display.pad ? .pageSheet : .fullScreen
                            notifyVC.present(navigation, animated: true, completion: {
                                self.isNotifyVCAppeared = true
                            })
                        } else {
                            Self.logger.error("n_action_mfa", body: "no vc to present")
                            onError(NewMFAServiceError.noVCPresent)
                            self?.isDoingActionStub = false
                        }
                    },
                    context: UniContextCreator.create(.external)
                ),
                success: {
                    Self.logger.info("LoginPassportEventBus post success")
                }, error: { error in
                    Self.logger.info("LoginPassportEventBus post failed: \(error.localizedDescription)")
                })
        }, onError: { error in
            onError(NewMFAServiceError.otherError(errorMessage: error.localizedDescription))
            Self.logger.error("n_action_mfa_check_status_failed", body: error.localizedDescription)
            self.isDoingActionStub = false
            hud.remove()
            if let topVC = navigation.visibleViewController {
                let errorHandler = V3ErrorHandler(vc: topVC, context: UniContextCreator.create(.external), showToastOnWindow: true)
                errorHandler.handle(error)
            }
            notifyVC.dismiss(animated: false)
        }, onCompleted: {
            UDToast.removeToast(on: from.view)
            self.isDoingActionStub = false
            hud.remove()
            notifyVC.dismiss(animated: false)
        }).disposed(by: disposeBag)
    }

}

// 旧版 MFA 请求从 LoginRequest 中剥离
final class MFALegacyRequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {

    convenience init(pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix, uniContext: uniContext)
    }

    required init(pathPrefix: String, pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        super.init(pathPrefix: pathPrefix, pathSuffix: pathSuffix, uniContext: uniContext)
        self.middlewareTypes = [
            .captcha,
            .requestCommonHeader,
            .saveToken,
            .saveEnv,
            .costTimeRecord,
            .toastMessage,
            .checkSession
        ]
        self.requiredHeader = [.passportToken, .proxyUnit]
        // 端内登录逻辑中，需要在用户列表中过滤已登录的用户，需要告知后端所有 session
        self.required(.sessionKeys)
    }

    convenience init(appId: APPID, uniContext: UniContextProtocol? = nil) {
        self.init(pathSuffix: appId.apiIdentify(), uniContext: uniContext)
        self.appId = appId
    }
}

final class MFALegacyAPI: APIV3 {

    func checkMFAStatus(token: String, scope: String, unit: String?) -> Observable<V3.CommonResponse<MFACheckResponse>> {
        let req = MFARequest<V3.CommonResponse<MFACheckResponse>>(appId: .applyVerifyToken)
        var params: [String: Any] = [
            "is_query_verify_token_status": true,
            "scope_verify_token": token,
            "scope": scope
        ]
        if let targetUnit = unit {
            params["target_unit"] = targetUnit
        }
        req.body = params
        req.domain = .passportAccounts()
        req.method = .post
        req.required(.fetchDeviceId)
        return client.send(req)
    }

    func startMFA(
        token: String,
        scope: String,
        unit: String?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = MFARequest<V3.Step>(appId: .applyVerifyToken, uniContext: context)
        var params: [String: Any] = [
            "scope_verify_token": token,
            "scope": scope,
            "is_query_verify_token_status": false
        ]
        if let targetUnit = unit {
            params["target_unit"] = targetUnit
        }
        req.body = params
        req.domain = .passportAccounts()
        req.method = .post
        req.required(.fetchDeviceId)
        return client.send(req)
    }
}
