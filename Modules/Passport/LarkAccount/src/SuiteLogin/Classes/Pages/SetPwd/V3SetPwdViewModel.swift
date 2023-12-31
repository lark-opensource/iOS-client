//
//  V3SetPwdViewModel.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/12/6.
//

import Foundation
import RxSwift
import LarkPerf
import Homeric
import UniverseDesignToast
import EENavigator

protocol V3SetPwdAPIProtocol {
    func v3SetPwd(
        password: String,
        rsaInfo: RSAInfo?,
        sourceType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
}

class V3SetPwdViewModel: SetPwdViewModel {

    var password: String = ""

    private let setPwdInfo: V3SetPwdInfo

    private let api: V3SetPwdAPIProtocol
    private lazy var isLogin: Bool = {
        return api as? LoginAPI != nil
    }()

    let switchUserSub: PublishSubject<SwitchUserStatus>?

    init(
        step: String,
        setPwdInfo: V3SetPwdInfo,
        api: V3SetPwdAPIProtocol,
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

extension V3SetPwdViewModel {
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
        I18N.Lark_Passport_EnterNewPSHintPC
    }

    var doubleConfirm: Bool { true }

    var nextTitle: String {
        isLogin ? I18N.Lark_Login_V3_NextStep : I18N.Lark_Login_V3_Done
    }

    func setPwd() -> Observable<Void> {
        SuiteLoginTracker.track(Homeric.PASSWORD_RESET_NEXT)
        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.resetPWD.rawValue,
            MultiSceneMonitor.Const.result.rawValue: "success"
        ]
        return api
            .v3SetPwd(
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
}
