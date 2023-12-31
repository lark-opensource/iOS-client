//
//  V4SetPwdViewModel.swift
//  LarkAccount
//
//  Created by dengbo on 2021/6/7.
//

import Foundation
import RxSwift
import LarkPerf
import Homeric
import UniverseDesignToast
import EENavigator

protocol SetPwdAPIProtocol {
    func setPwd(
        serverInfo: ServerInfo,
        password: String,
        rsaInfo: RSAInfo?,
        sourceType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
}

class V4SetPwdViewModel: V4SetPwdVM {

    var password: String = ""

    private let setPwdInfo: V4SetPwdInfo

    private let api: SetPwdAPIProtocol
    private lazy var isLogin: Bool = {
        return api as? LoginAPI != nil
    }()

    let switchUserSub: PublishSubject<SwitchUserStatus>?

    init(
        step: String,
        setPwdInfo: V4SetPwdInfo,
        api: SetPwdAPIProtocol,
        context: UniContextProtocol,
        switchUserSub: PublishSubject<SwitchUserStatus>? = nil
    ) {
        self.setPwdInfo = setPwdInfo
        self.api = api
        self.switchUserSub = switchUserSub
        super.init(step: step, stepInfo: setPwdInfo, context: context)
    }

    override func clickClose() {
        V3ViewModel.logger.info("send cancel")
        switchUserSub?.onNext(.cancel)
        switchUserSub?.onCompleted()
    }
}

extension V4SetPwdViewModel {
    var title: String {
        setPwdInfo.title ?? ""
    }

    var subtitle: String {
        setPwdInfo.subtitle ?? ""
    }

    var pageName: String? {
        Homeric.LOGIN_PAGE_ENTER_RESET_PWD
    }

    var placeHolder: String {
        setPwdInfo.pwdPlaceholder?.placeholder ?? I18N.Lark_Passport_EnterNewPSHintPC
    }

    var confirmPlaceholder: String {
        setPwdInfo.confirmPwdPlaceholder?.placeholder ?? I18N.Lark_Passport_ReEnterNewPSHintPC
    }

    var doubleConfirm: Bool { true }

    var nextTitle: String {
        let placeholder = isLogin ? I18N.Lark_Login_V3_NextStep : I18N.Lark_Login_V3_Done
        return setPwdInfo.nextButton?.text ?? placeholder
    }

    var canSkip: Bool {
        setPwdInfo.skipButton?.text != nil
    }

    var canBack: Bool {
        return !(setPwdInfo.disableBack ?? false)
    }

    var skipTips: String {
        setPwdInfo.skipButton?.text ?? ""
    }
    
    var pwdErrorToast: String {
        setPwdInfo.errText ?? ""
    }

    var flowType: String? {
        setPwdInfo.flowType
    }

    func setPwd() -> Observable<Void> {
        SuiteLoginTracker.track(Homeric.PASSWORD_RESET_NEXT)
        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.resetPWD.rawValue,
            MultiSceneMonitor.Const.result.rawValue: "success"
        ]
        return api
            .setPwd(
                serverInfo: setPwdInfo,
                password: password,
                rsaInfo: setPwdInfo.rsaInfo,
                sourceType: setPwdInfo.sourceType,
                sceneInfo: sceneInfo,
                context: context
            )
            .post(context: context)
            .do(afterNext: { [weak self] (_) in
                guard let self = self else { return }
                if !self.isLogin {
                    if let mainSceneWindow = PassportNavigator.keyWindow {
                        UDToast.showTips(with: I18N.Lark_Login_ReminderAfterResetPassword, on: mainSceneWindow)
                    } else {
                        Self.logger.errorWithAssertion("no main scene for setPwd")
                    }
                    self.service.eventRegistry.currentNavigation()?.popToRootViewController(animated: true)
                }
            })
    }

    func skipSetPwd() -> Observable<Void> {
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let self = self else { return Disposables.create() }
            self.service.v4EnterApp(serverInfo: self.setPwdInfo, userId: nil, success: {
                observer.onNext(())
                observer.onCompleted()
            }, error: { (error) in
                observer.onError(error)
            }, context: self.context)

            return Disposables.create()
        }
    }
    
    var strengthDescription: String {
        return setPwdInfo.pwdCheck.pwdLevelMsg
    }
    
    func isValidPassword(_ pwd: String) -> Bool {
        if case .invalid = checkPassword(pwd) {
            return false
        }
        
        return true
    }
    
    func checkPassword(_ pwd: String) -> PasswordStrength {
        let validPasswordPattern = setPwdInfo.pwdCheck.regExpCommon
        let regMap = setPwdInfo.pwdCheck.regExpMap
        if pwd.range(of: validPasswordPattern, options: .regularExpression) != nil {
            // 密码符合要求，检测从强到弱匹配强度
            if setPwdInfo.pwdCheck.pwdStrong.contains(where: { $0.match(pwd, regMap: regMap) }) {
                return .strong(setPwdInfo.pwdCheck.pwdStrong.first?.msg ?? "")
            } else if setPwdInfo.pwdCheck.pwdMiddle.contains(where: { $0.match(pwd, regMap: regMap) }) {
                return .middle(setPwdInfo.pwdCheck.pwdMiddle.first?.msg ?? "")
            } else {
                return .weak(setPwdInfo.pwdCheck.pwdWeak.first?.msg ?? "")
            }
        } else {
            // 密码不符合要求，按顺序匹配错误
            if let condition = setPwdInfo.pwdCheck.pwdErr.first(where: { $0.match(pwd, regMap: regMap) }) {
                return .invalid(condition.msg)
            } else {
                assertionFailure("Failed to match password strength")
                return .invalid("")
            }
        }
    }
}
