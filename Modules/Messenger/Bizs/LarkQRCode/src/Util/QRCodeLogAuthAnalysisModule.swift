//
//  QRCodeLogAuthAnalysisModule.swift
//  LarkCore
//
//  Created by zc09v on 2018/10/11.
//

import UIKit
import Foundation
import RxSwift
import EENavigator
import LKCommonsLogging
import LarkUIKit
import UniverseDesignToast
import LarkAccount
import LarkAccountInterface
import LarkContainer
import QRCode
import LarkSetting

final class QRCodeLogAuthAnalysisModule: QRCodeAnalysis, UserResolverWrapper {
    static let logger = Logger.log(QRCodeLogAuthAnalysisModule.self, category: "Module.QRCode")
    static let passortLogger = Logger.plog(QRCodeLogAuthAnalysisModule.self, category: "Module.QRCode")
    private let disposeBag: DisposeBag = DisposeBag()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    @ScopedProvider private var authorizationService: PassportAuthorizationService?
    @ScopedProvider private var passportUserService: PassportUserService?

    private var isHandlingQrCodeRequest = false

    func handle(code: String, status: QRCodeAnalysisCallBack, from: QRCodeFromType, fromVC: UIViewController) -> Bool {
        Self.passortLogger.info("n_action_qrpassport_start")

        guard let dict = toDict(string: code) as? [String: Any] else {
            Self.passortLogger.error("n_action_qrpassport_json_parse_error")
            return false
        }

        if let qrLoginInfo = dict["qrlogin"] as? [String: String],
            let token = qrLoginInfo["token"] {
            self.handleLogin(token: token, status: status, from: fromVC)
            return true
        }

        if let qrPassportInfo = dict["qrpassport"] as? [String: String] {
            self.handleRealnameVerification(params: qrPassportInfo, status: status, from: fromVC)
            return true
        }
        Self.passortLogger.passportInfo("n_action_qrpassport_is_handle", body: "false")

        return false
    }

    private func handleLogin(token: String, status: QRCodeAnalysisCallBack, from: UIViewController) {
        let qrCodeThrottleFeatureGatting = userResolver.fg.dynamicFeatureGatingValue(with: "lark.passport.qrcode")
        Self.logger.info("lark.passport.qrcode: \(qrCodeThrottleFeatureGatting)")
        if isHandlingQrCodeRequest && qrCodeThrottleFeatureGatting {
            Self.logger.warn("There are currently requests being processed.")

            return
        }
        guard let authorizationService else {
            return
        }
        (from as? ScanCodeViewController)?.stopScanning()
        let topMostFrom = WindowTopMostFrom(vc: from)
        let hud = UDToast.showLoading(with: BundleI18n.LarkQRCode.Lark_Legacy_QrCodeLoading,
                                         on: from.view.window ?? from.view,
                                         disableUserInteraction: true)
        let navigator = userResolver.navigator
        isHandlingQrCodeRequest = true
        authorizationService.checkAuth(info: .qrCode(token)) { (result) in
            // The checkAuth api is not store the result callback so the self capturing logic is safe.
            self.isHandlingQrCodeRequest = false
            switch result {
            case .success(let vc):
                status?(.preFinish, {
                    hud.remove()
                    if let vc = vc {
                        if Display.pad {
                            vc.modalPresentationStyle = .formSheet
                        } else {
                            vc.modalPresentationStyle = .fullScreen
                        }
                        navigator.present(vc, from: topMostFrom)
                    }
                })
            case .failure(let error):
                hud.remove()
                QRCodeLogAuthAnalysisModule.logger.error("QRCode.checkTokenForLogin失败", error: error)
                status?(.fail(errorInfo: error.localizedDescription), nil)
            }
        }
    }

    private func handleRealnameVerification(params: [String: Any], status: QRCodeAnalysisCallBack, from: UIViewController) {
        if let token = params["token"], let type = params["type"] {
            Self.passortLogger.passportInfo("n_action_qrpassport_is_handle", body: "true")
        } else {
            Self.passortLogger.passportInfo("n_action_qrpassport_is_handle", body: "false")
        }

        let topMostFrom = WindowTopMostFrom(vc: from)
        let hud = UDToast.showLoading(with: BundleI18n.LarkQRCode.Lark_Legacy_QrCodeLoading,
                                         on: from.view.window ?? from.view,
                                         disableUserInteraction: true)
        passportUserService?.startRealNameVerificationFromQRCode(params: params) { errorMessage in
            if let toast = errorMessage, !toast.isEmpty {
                hud.remove()
                status?(.fail(errorInfo: toast), nil)
            } else {
                status?(.preFinish, { hud.remove() })
            }
        }
    }
}

private func toDict(string: String) -> [AnyHashable: Any]? {
    if let data = string.data(using: .utf8) {
        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return dict
            }
        } catch {
            return nil
        }
    }
    return nil
}
