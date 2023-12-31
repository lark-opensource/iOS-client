//
//  BioAuthService.swift
//  AppReciableSDK
//
//  Created by Yiming Qu on 2021/3/11.
//

import Foundation
import LarkContainer
import RxSwift
import LKCommonsLogging
import Homeric
import UniverseDesignToast
import EENavigator

struct BioAuthSourceType {
    /// 帐号找回
    static let recoverAccount: Int = 0
    /// 绑定
    static let bind: Int = 12
    /// 删除
    static let delete: Int = 13
    /// 登录
    static let login: Int = 14
    /// 帐号找回，登录前
    static let accountRecoverBeforeLogin: Int = 15
    /// 帐号找回，登录后
    static let accountRecoverAfterLogin: Int = 16
    /// 重置密码，登录前
    static let resetPassword: Int = 17
}

struct BioAuthFaceInfo: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?
    
    let ticket: String?
    let identityNumber: String?
    let identityName: String?
    let sdkScene: String?
    let aid: String?
}

class BioAuthService {

    @Provider private var bioAuthAPI: BioAuthAPI // user:checked (global-resolve)

    @Provider private var dependency: PassportDependency // user:checked (global-resolve)

    @Provider private var loginService: V3LoginService

    @Provider private var passportAPI: LoginAPI
    
    private lazy var store = PassportStore.shared

    private static let logger = Logger.plog(BioAuthService.self, category: "SuiteLogin.BioAuthService")

    private let disposeBag = DisposeBag()

    let bioAuthStatusChangeSubject: PublishSubject<Void> = .init()
    
    /// 进行人脸认证
    /// 新模型流程
    func doBioAuthVerify(
        info: BioAuthFaceInfo,
        context: UniContextProtocol,
        success: @escaping EventBusSuccessHandler,
        error: @escaping EventBusErrorHandler
    ) {
        guard let ticket = info.ticket else {
            Self.logger.error("n_action_bioauth_verify", body: "no ticket")
            error(EventBusError.invalidParams)
            return
        }
        
        let verifyCallback: ([AnyHashable: Any]?, Error?) -> Void = { [weak self] _, err in
            guard let `self` = self else { return }
            
            if let err = err {
                Self.logger.error("n_action_bioauth_verify_fail", body: "error code: \((err as NSError).code)", error: err)
                if let nsError = err as NSError?, nsError.code < 0 {
                    /// 对于来自 SDK 本地的错误(错误码为负数)，直接展示错误信息，不执行后面的流程
                    /// SDK 服务端错误（错误码为正数）时，继续后面的流程（风控需要），以 passport API 给出的错误为准
                    let errorMessage = err.localizedDescription
                    if let window = PassportNavigator.keyWindow, !errorMessage.isEmpty {
                        UDToast.showFailure(with: errorMessage, on: window)
                    }
                    error(EventBusError.internalError(.badLocalData(err.localizedDescription)))
                    return
                }
            }
            
            Self.logger.info("n_action_bioauth_verify_req_start")
            
            self.bioAuthAPI.bioAuthVerify(serverInfo: info, context: context)
                .delay(.milliseconds(300), scheduler: MainScheduler.instance) // 因为回调在人脸页面消失前执行，延迟300ms确保弹框能正常展示
                .post(context: context)
                .subscribe(onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    Self.logger.info("n_action_bioauth_verify_req_succ")
                    
                    self.bioAuthStatusChangeSubject.onNext(())
                    success()
                }, onError: { [weak self] err in
                    guard let `self` = self else { return }
                    Self.logger.error("n_action_bioauth_verify_req_fail", error: err)
                    
                    self.bioAuthStatusChangeSubject.onNext(())
                    if let e = err as? V3LoginError {
                        switch e {
                        case let .badServerCode(loginErrorInfo):
                            if let window = PassportNavigator.keyWindow {
                                UDToast.showFailure(with: loginErrorInfo.message, on: window)
                            }
                        default:
                            break
                        }
                    } else {
                        Self.logger.error("uknown error", error: err)
                        error(EventBusError.invalidParams)
                    }
                })
                .disposed(by: self.disposeBag)
        }

        if let identityName = info.identityName, let identityNumber = info.identityNumber {
            Self.logger.info("n_action_bioauth_verify_start", body: "auth with id")
            
            var appId: String?
            var scene: String?

            let realNameFlowTypePrefix = "real_name"
            if let flowType = info.flowType, flowType.starts(with: realNameFlowTypePrefix) {
                appId = loginService.config.realNameAppId(for: store.configEnv)
                scene = loginService.config.realNameScene(for: store.configEnv)
            } else {
                appId = loginService.config.recoverAppId(for: store.configEnv)
                scene = loginService.config.recoverScene(for: store.configEnv)
            }

            if let sdkScene = info.sdkScene, !sdkScene.isEmpty {
                scene = sdkScene
            }
            //如果后台下发了 appID， 用后台的
            if let aid = info.aid, !aid.isEmpty{
                appId = aid
            }
            
            guard let appId = appId, let scene = scene else {
                Self.logger.error("n_action_bioauth_verify", body: "Invalid params, appId: \(appId), scene: \(scene)")
                return
            }
            
            Self.logger.info("n_action_bioauth_verify_start", additionalData: [
                "appId": String(describing: appId),
                "scene": scene
            ])
            
            dependency.doFaceLiveness(appId: appId, ticket: ticket, scene: scene, identityName: identityName, identityCode: identityNumber, presentToShow: false, callback: verifyCallback)
        } else {
            Self.logger.info("n_action_bioauth_verify_start", body: "auth without id")
            
            guard let appIdFromConfig = loginService.config.bioAuthAppId(for: store.configEnv) else {
                Self.logger.error("n_action_bioauth_verify", body: "no app id")
                return
            }
            guard var scene = loginService.config.bioAuthScene(for: store.configEnv) else {
                Self.logger.error("n_action_bioauth_verify", body: "no scene")
                return
            }

            if let sdkScene = info.sdkScene, !sdkScene.isEmpty {
                scene = sdkScene
            }

            var verifyFaceAppId = appIdFromConfig
            //如果后台下发了 appID， 用后台的
            if let appIdFromServer = info.aid, !appIdFromServer.isEmpty {
                verifyFaceAppId = appIdFromServer
            }

            Self.logger.info("n_action_bioauth_verify_start", additionalData: [
                "appId": String(describing: verifyFaceAppId),
                "scene": scene
            ])
            let mode = "0"
            dependency.doFaceLiveness(appId: verifyFaceAppId, ticket: ticket, scene: scene, mode: mode, callback: verifyCallback)
        }
        
    }

    /// 进行人脸认证
    /// 老模型流程，不要更改
    func doBioAuthVerifyFace(
        info: V3RecoverAccountFaceInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol,
        success: @escaping EventBusSuccessHandler,
        error: @escaping EventBusErrorHandler
    ) {
        guard let ticket = info.ticket else {
            Self.logger.error("no ticket")
            error(EventBusError.invalidParams)
            return
        }
        guard let sourceType = info.sourceType else {
            Self.logger.error("no sourceType")
            return error(EventBusError.invalidParams)
        }
        let mode: String
        if sourceType == BioAuthSourceType.bind {
            mode = "0"
        } else {
            mode = "1"
        }
        guard let verifyFaceAppId = loginService.config.bioAuthAppId(for: store.configEnv) else {
            Self.logger.error("no app id")
            return
        }
        guard let verifyFaceScene = loginService.config.bioAuthScene(for: store.configEnv) else {
            Self.logger.error("no scene")
            return
        }
        Self.logger.info("start bio auth verify face", additionalData: [
            "appId": String(describing: verifyFaceAppId),
            "scene": verifyFaceScene
        ])
        dependency
            .doFaceLiveness(
                appId: verifyFaceAppId,
                ticket: ticket,
                scene: verifyFaceScene,
                mode: mode,
                callback: { [weak self] (_, err) in
                    guard let self = self else { return }
                    if let errmsg = err?.localizedDescription {
                        SuiteLoginTracker.track(Homeric.PASSPORT_FACEVERIFICATION_RESULT, params: [
                            CommonConst.sourceType: info.sourceType ?? 0,
                            TrackConst.result: TrackConst.fail
                        ])
                        Self.logger.info("fail to verify face:\(errmsg)")
                        if let window = PassportNavigator.keyWindow {
                            UDToast.showFailure(with: errmsg, on: window)
                        }
                        return
                    }
                    SuiteLoginTracker.track(Homeric.PASSPORT_FACEVERIFICATION_RESULT, params: [
                        CommonConst.sourceType: info.sourceType ?? 0,
                        TrackConst.result: TrackConst.success
                    ])

                    Self.logger.info("success in verifying face")
                    self.bioAuthAPI.bioAuthVerifyFace(
                        sourceType: sourceType,
                        context: context
                    ).post([
                        "from": from.rawValue
                    ], context: context)
                    .subscribe(onNext: { [weak self] _ in
                        guard let `self` = self else { return }
                        
                        self.bioAuthStatusChangeSubject.onNext(())
                        success()
                    }, onError: { [weak self] err in
                        guard let `self` = self else { return }
                        
                        self.bioAuthStatusChangeSubject.onNext(())
                        if let e = err as? EventBusError {
                            error(e)
                        } else {
                            Self.logger.error("uknown error", error: err)
                            error(EventBusError.invalidParams)
                        }
                    })
                    .disposed(by: self.disposeBag)
                })
    }

    /// 进行帐号找回
    func doRecoverAccountVerifyFace(
        info: V3RecoverAccountFaceInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol,
        success: @escaping EventBusSuccessHandler,
        error: @escaping EventBusErrorHandler
    ) {
        guard let ticket = info.ticket else {
            Self.logger.error("no ticket")
            error(EventBusError.invalidParams)
            return
        }
        guard let name = info.name else {
            Self.logger.error("no name")
            error(EventBusError.invalidParams)
            return
        }
        guard let identityNumber = info.identityNumber else {
            Self.logger.error("no identity number")
            error(EventBusError.invalidParams)
            return
        }
        guard let verifyFaceAppId = loginService.config.recoverAppId(for: store.configEnv) else {
            Self.logger.error("no app id")
            return
        }
        guard let verifyFaceScene = loginService.config.recoverScene(for: store.configEnv) else {
            Self.logger.error("no scene")
            return
        }
        Self.logger.info("start recover account verify face", additionalData: [
            "appId": String(describing: verifyFaceAppId),
            "scene": verifyFaceScene
        ])
        dependency
            .doFaceLiveness(
                appId: verifyFaceAppId,
                ticket: ticket,
                scene: verifyFaceScene,
                identityName: name,
                identityCode: identityNumber,
                presentToShow: false) { [weak self] (_, err) in
                guard let self = self else { return }
                if let errmsg = err?.localizedDescription {
                    Self.logger.info("fail to verify face:\(errmsg)")
//                    error(EventBusError.internalError(V3LoginError.toastError(errmsg)))
                    if let window = PassportNavigator.keyWindow {
                        UDToast.showFailure(with: errmsg, on: window)
                    }
                    SuiteLoginTracker.track(Homeric.FACE_VERIFICATION_RESULT, params: [
                        "from": from.rawValue,
                        "result": "fail"
                    ])
                } else {
                    Self.logger.info("success in verifying face")
                    SuiteLoginTracker.track(Homeric.FACE_VERIFICATION_RESULT, params: [
                        "from": from.rawValue,
                        "result": "success"
                    ])
                    success()
                    self.passportAPI
                        .notifyFaceVerifySuccsss(sceneInfo: nil, context: context)
                        .post([
                            "from": from.rawValue
                        ], context: context)
                        .subscribe()
                        .disposed(by: self.disposeBag)
                }
            }
    }
}
