//
//  QRLoginConfirmDangerHandler.swift
//  LarkAccount
//
//  Created by au on 2023/5/29.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import UniverseDesignDialog

// 高风险下限制登录
final class QRLoginConfirmDangerHandler: QRLoginConfirmHandlerProtocol {

    private static let logger = Logger.log(QRLoginConfirmDangerHandler.self, category: "LarkAccount")

    private let _userResolver: UserResolver?
    private var userResolver: UserResolver {
        return _userResolver ?? PassportUserScope.getCurrentUserResolver() // user:current
    }

    init(resolver: UserResolver?) {
        self._userResolver = resolver
    }

    func handle(info: QRCodeLoginConfirmInfo,
                context: UniContextProtocol,
                payload: Codable?,
                success: @escaping EventBusSuccessHandler,
                failure: @escaping EventBusErrorHandler) {
        guard let topVC = PassportNavigator.getUserScopeTopMostVC(userResolver: userResolver) else {
            Self.logger.error("n_action_qr_login_confirm_danger: no top most vc")
            success()
            return
        }
        guard let title = info.suiteInfo.title, let content = info.suiteInfo.tips else {
            Self.logger.error("n_action_qr_login_confirm_danger: no title or tips")
            success()
            return
        }
        guard let authPayload = payload as? AuthorizationRiskPayload,
              let authType = authPayload.getAuthType() else {
            Self.logger.error("n_action_qr_login_confirm_danger: no payload or type")
            success()
            return
        }

        let viewModel = SSOBaseViewModel(resolver: userResolver, info: authType)

        trackViewLoad(info)
        Self.logger.info("n_action_qr_login_confirm_danger: handle")

        let alert = UDDialog()
        alert.setTitle(text: title)
        alert.setContent(text: content)

        if let baseVC = topVC as? BaseViewController {
            baseVC.stopLoading()
        }

        if let buttonList = info.buttonList {
            buttonList.enumerated().forEach { (index, button) in
                if index == 0 {
                    alert.addPrimaryButton(text: button.text, numberOfLines: 0, dismissCompletion: {
                        self.trackClick(info)
                        viewModel.closeWork(authorizationPageType: nil)
                        self.dismissAuthPage()
                        success()
                    })
                } else {
                    alert.addSecondaryButton(text: button.text, numberOfLines: 0, dismissCompletion: {
                        viewModel.closeWork(authorizationPageType: nil)
                        self.dismissAuthPage()
                        success()
                    })
                }
            }
        }

        topVC.present(alert, animated: true, completion: nil)
    }

    private func dismissAuthPage() {
        guard let vc = PassportNavigator.getUserScopeTopMostVC(userResolver: userResolver) as? AuthorizationBaseViewController else { return }
        vc.dismiss(animated: true)
    }

    private func trackViewLoad(_ info: QRCodeLoginConfirmInfo) {
        // 扫码或免密
        let key = (info.qrSource == "qr_code" || info.qrSource == "qr_scan") ? "passport_qr_login_risk_restrict_view" : "passport_disposable_login_risk_restrict_view"
        SuiteLoginTracker.track(key)
    }

    private func trackClick(_ info: QRCodeLoginConfirmInfo) {
        let key = (info.qrSource == "qr_code" || info.qrSource == "qr_scan") ? "passport_qr_login_risk_restrict_click" : "passport_disposable_login_risk_restrict_click"
        let click = "got"
        let target = "none"
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: "", click: click, target: target)
        SuiteLoginTracker.track(key, params: params)
    }
}
