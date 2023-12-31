//
//  AutoLoginServiceImpl.swift
//  LarkAccount
//
//  Created by Bytedance on 2022/12/6.
//

import Foundation

#if DEBUG || BETA || ALPHA
import RxSwift
import RxCocoa
import LarkPerf
import EENavigator
import LarkContainer
import LKCommonsLogging
import UniverseDesignToast
import LarkAccountInterface

/// QA、单测需求：自动登录能力
class AutoLoginServiceImpl: AutoLoginService {
    private let logger = Logger.log(AutoLoginServiceImpl.self, category: "AutoLoginService")
    /// 登陆、验证密码
    @Provider private var loginApi: LoginAPI
    /// 选择租户
    @Provider private var loginService: V3LoginService

    func autoLogin(account: String, password: String, userId: String?, onSuccess: @escaping () -> Void) {
        if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
            UDToast.showTips(with: "开始自动登陆", on: windowView)
        }
        self.logger.info("begin autoLogin by applink")
        let loginContext = UniContext(.applink)

        // 登陆
        if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
            UDToast.showTips(with: "登陆\(account)...", on: windowView)
        }
        self.logger.info("begin loginType +86\(account)")
        self.loginApi.loginType(serverInfo: LarkAccount.PlaceholderServerInfo(), contact: "+86\(account)", credentialType: 1, action: 1, sceneInfo: nil, forceLocal: false, context: loginContext).post(context: loginContext).subscribe { [weak self] step in
            self?.logger.info("success loginType")
            if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                UDToast.showTips(with: "登陆成功", on: windowView)
            }
        } onError: { [weak self] error in
            self?.logger.info("error loginType \(error)")
            if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                UDToast.showTips(with: "登陆失败\(error)", on: windowView)
            }
        }

        // 验证密码
        LoginPassportEventBus.shared.removeHandler(for: PassportStep.verifyIdentity.rawValue)
        LoginPassportEventBus.shared.register(step: .verifyIdentity, handler: ServerInfoEventBusHandler<V4VerifyInfo>(handleWork: { [weak self] args in
            if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                UDToast.showTips(with: "验证密码\(password)...", on: windowView)
            }
            self?.logger.info("begin verify \(password)")
            self?.loginApi.verify(serverInfo: args.serverInfo, flowType: args.serverInfo.verifyPwd?.flowType, password: password, rsaInfo: args.serverInfo.verifyPwd?.rsaInfo, contactType: nil, sceneInfo: nil, context: loginContext).post(context: loginContext).subscribe { [weak self] step in
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                    UDToast.showTips(with: "验证密码成功", on: windowView)
                }
                self?.logger.info("success verify")
                args.successHandler()
            } onError: { [weak self] error in
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                    UDToast.showTips(with: "验证密码失败\(error)", on: windowView)
                }
                self?.logger.info("error verify \(error)")
                args.errorHandler(EventBusError.internalError(V3LoginError.server(error)))
            }
        }))

        // 选择租户（Option），如果只有一个租户，则不会执行此回调
        LoginPassportEventBus.shared.removeHandler(for: PassportStep.userList.rawValue)
        LoginPassportEventBus.shared.register(step: .userList, handler: ServerInfoEventBusHandler<V4SelectUserInfo>(handleWork: { [weak self] args in
            if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                UDToast.showTips(with: "选择租户\(userId)...", on: windowView)
            }
            self?.logger.info("begin v4EnterApp \(userId)")
            self?.loginService.v4EnterApp(serverInfo: args.serverInfo, userId: userId, success: { [weak self] in
                self?.logger.info("success v4EnterApp")
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                    UDToast.showTips(with: "选择租户成功", on: windowView)
                }
                args.successHandler()
            }, error: { [weak self] error in
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                    UDToast.showTips(with: "选择租户失败\(error)", on: windowView)
                }
                self?.logger.info("error v4EnterApp \(error)")
                args.errorHandler(EventBusError.internalError(V3LoginError.server(error)))
            }, context: loginContext)
        }))

        // 进入Feed页
        LoginPassportEventBus.shared.removeHandler(for: PassportStep.enterApp.rawValue)
        LoginPassportEventBus.shared.register(step: .enterApp, handler: ServerInfoEventBusHandler<V4EnterAppInfo>(handleWork: { [weak self] args in
            // 触发.userList的success回调
            if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                UDToast.showTips(with: "进入Feed...", on: windowView)
            }
            self?.logger.info("begin enterAppDidCall")
            self?.loginService.enterAppDidCall(enterAppInfo: args.serverInfo, sceneInfo: [:], success: { [weak self] in
                self?.logger.info("success enterAppDidCall")
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                    UDToast.showTips(with: "进入Feed成功", on: windowView)
                }
                args.successHandler()
                onSuccess()
            }, error: { [weak self] error in
                self?.logger.info("error enterAppDidCall \(error)")
                if let windowView = Navigator.shared.mainSceneWindow?.rootViewController?.view { // user:checked (debug)
                    UDToast.showTips(with: "进入Feed失败\(error)", on: windowView)
                }
                args.errorHandler(EventBusError.internalError(error))
            }, context: args.context)
        }))
    }
}
#endif
