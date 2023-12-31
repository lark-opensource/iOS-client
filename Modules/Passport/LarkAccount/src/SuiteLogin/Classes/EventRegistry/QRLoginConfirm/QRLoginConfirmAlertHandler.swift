//
//  QRLoginConfirmAlertHandler.swift
//  LarkAccount
//
//  Created by au on 2023/5/29.
//

import LarkUIKit
import LKCommonsLogging
import UIKit
import LarkAccountInterface
import LarkContainer

// 中风险下二次验证
// 这里的 alert 是指风险等级为 alert（和 danger 相对应），并不代表页面呈现是 alert controller
// 页面表现上是一个全屏弹窗 / form sheet（iPad）
final class QRLoginConfirmAlertHandler: QRLoginConfirmHandlerProtocol {

    private static let logger = Logger.log(QRLoginConfirmAlertHandler.self, category: "LarkAccount")

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
            Self.logger.error("n_action_qr_login_confirm_alert: no_vc")
            success()
            return
        }
        guard let authPayload = payload as? AuthorizationRiskPayload,
              let authType = authPayload.getAuthType() else {
            Self.logger.error("n_action_qr_login_confirm_alert: no payload or type")
            success()
            return
        }

        Self.logger.info("n_action_qr_login_confirm_alert: handle")
        let vm = AuthorizationRiskReminderViewModel(resolver: userResolver, authType: authType, stepInfo: info, isMultiLogin: authPayload.isMultiLogin)
        let vc = AuthorizationRiskReminderViewController(vm: vm)
        if Display.pad {
            vc.modalPresentationStyle = .formSheet
            if #available(iOS 13.0, *) {
                vc.isModalInPresentation = true
            }
        } else {
            vc.modalPresentationStyle = .fullScreen
        }
        
        topVC.present(vc, animated: true)
        success()
    }
}

struct AuthorizationRiskPayload: Codable {
    enum Source: Codable {
        case qrCode
        case url
        case sdk
        case autoLogin
    }

    let source: Source
    let token: String
    let schema: String?

    let isMultiLogin: Bool

    init(authType: SSOAuthType, isMultiLogin: Bool) {
        var t = ""
        var s: String? = nil
        let source: AuthorizationRiskPayload.Source
        switch authType {
        case .qrCode(let token):
            t = token
            s = nil
            source = .qrCode
        case .url(_, _, _):
            source = .url
        case .sdk(_, _, _):
            source = .sdk
        case .authAutoLogin(let token, _, let schema):
            t = token
            s = schema
            source = .autoLogin
        }
        self.source = source
        self.token = t
        self.schema = s
        self.isMultiLogin = isMultiLogin
    }

    func getAuthType() -> SSOAuthType? {
        switch source {
        case .qrCode:
            return SSOAuthType.qrCode(token)
        case .autoLogin:
            return SSOAuthType.authAutoLogin(token, "", schema ?? "")
        case .url:
            return nil
        case .sdk:
            return nil
        }
    }
}
