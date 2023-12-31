//
//  IDPWebErrorHandler.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/25.
//

import Foundation
import RxSwift
import Homeric

// all web view for idp on saas return alert
class IDPWebErrorHandler: V3ErrorHandler {

    public let switchUserStatusSub: PublishSubject<SwitchUserStatus>?

    init(
        vc: UIViewController,
        context: UniContextProtocol,
        contextExpiredPostEvent: Bool = V3ErrorHandler.defaultContextExpiredPostEvent,
        showToastOnWindow: Bool = V3ErrorHandler.defaultShowToastOnWindow,
        eventBus: PassportEventBusProtocol? = nil,
        switchUserStatusSub: PublishSubject<SwitchUserStatus>?
    ) {
        self.switchUserStatusSub = switchUserStatusSub
        super.init(
            vc: vc,
            context: context,
            contextExpiredPostEvent: contextExpiredPostEvent,
            showToastOnWindow: showToastOnWindow
        )
    }

    override func defaultHandleLoginError(_ logMsg: String, errorMsg: String) {
        idpHandle(
            logMsg: logMsg,
            errorMsg: errorMsg
        )
    }

    override func handleEventBus(_ error: EventBusError) {
        switch error {
        case let .internalError(loginError):
            handleLogin(loginError)
        default:
            idpHandle(
                logMsg: "V3BaseVC: hanlde EventBus \(error) error",
                errorMsg: BundleI18n.suiteLogin.Lark_Passport_BadServerData
            )
        }
    }

    override func handleCommonBizError(_ errorInfo: (V3LoginErrorInfo), confirm: (() -> Void)? = nil) -> Bool {
        idpHandle(
            logMsg: "V3BaseVC: hanlde biz error code: \(errorInfo.type.rawValue) message: \(errorInfo.message)",
            errorMsg: errorInfo.message
        )
        return true
    }

    private func idpHandle(logMsg: String, errorMsg: String) {
        V3ErrorHandler.logger.error(logMsg)
        SuiteLoginTracker.track(Homeric.IDP_NOTICE)
        V3ErrorHandler.showAlert(errorMsg, title: I18N.Lark_Login_IdP_noticetitle, confirmTitle: I18N.Lark_Login_IdP_noticeconfirm, vc: vc, confirm: {
            SuiteLoginTracker.track(Homeric.IDP_NOTICE_BUTTON)
            let vcsCount = self.vc?.navigationController?.viewControllers.count ?? 0
            if vcsCount > 1 {
                // login
                self.vc?.navigationController?.popViewController(animated: true)
            } else if vcsCount == 1, self.vc?.navigationController?.presentingViewController != nil {
                // switch user
                self.vc?.navigationController?.dismiss(animated: true, completion: nil)
                V3ErrorHandler.logger.info("send cancel")
                self.switchUserStatusSub?.onNext(.cancel)
                self.switchUserStatusSub?.onCompleted()
            }
        })
    }
}
