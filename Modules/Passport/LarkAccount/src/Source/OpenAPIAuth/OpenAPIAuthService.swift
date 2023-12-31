//
//  OpenAPIAuthService.swift
//  LarkAccount
//
//  Created by au on 2023/6/6.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import LarkUIKit
import LKCommonsLogging
import RxSwift
import UniverseDesignActionPanel
import UniverseDesignToast

final class OpenAPIAuthService {

    private let openAPIAuthAPI: OpenAPIAuthAPI

    private static let logger = Logger.log(OpenAPIAuthService.self, category: "LarkAccount")

    private let disposeBag = DisposeBag()

    private var completion: ((LarkAccountInterface.OpenAPIAuthResult) -> Void)?

    private var latestParams: OpenAPIAuthParams?

    private var latestErrorResponse: V3.SimpleResponse?
    private var latestError: Error?

    private let userResolver: UserResolver

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.openAPIAuthAPI = try resolver.resolve(assert: OpenAPIAuthAPI.self)
    }

    /// 入口方法
    func performAuthInfoRequest(params: OpenAPIAuthParams, completion: @escaping ((LarkAccountInterface.OpenAPIAuthResult) -> Void)) {
        self.completion = completion
        self.latestParams = params
        Self.logger.info("n_action_open_api_service", body: "perform request enter. params: \(params.logDescription)")
        fetchAuthInfoInner(params: params)
    }

    private func fetchAuthInfoInner(params: OpenAPIAuthParams) {
        openAPIAuthAPI.getAuthInfoInner(params: params)
            .subscribe { [weak self] response in
                guard let self = self else { return }
                Self.logger.info("n_action_open_api_service", body: "response from auth info inner")

                guard let info = Self.decode(OpenAPIAuthGetAuthInfo.self, from: response) else {
                    self.handleFailureCompletion(.unknown)
                    return
                }

                if info.autoConfirm {
                    // 静默回调
                    Self.logger.info("n_action_open_api_service", body: "auth info auto confirm")
                    self.handleSuccessCompletion(.getAuthInfo(info))
                } else {
                    Self.logger.info("n_action_open_api_service", body: "present auth sheet")
                    SuiteLoginUtil.runOnMain {
                        // 非静默回调，展示用户确认弹窗
                        self.presentAuthSheet(info)
                    }
                }
            } onError: { [weak self] error in
                guard let self = self else { return }
                self.handleFailureCompletion(.serverError(error))
            }
            .disposed(by: disposeBag)
    }

    private func handleSuccessCompletion(_ scenario: SuccessScenario) {
        let payload: OpenAPIAuthPayload
        switch scenario {
        case .getAuthInfo(let authInfo):
            payload = OpenAPIAuthPayload(code: authInfo.code ?? "", message: nil, isAutoConfirm: authInfo.autoConfirm, state: authInfo.state, extra: authInfo.extra)
        case .confirm(let confirmInfo):
            payload = OpenAPIAuthPayload(code: confirmInfo.code, message: nil, isAutoConfirm: confirmInfo.autoConfirm, state: confirmInfo.state, extra: confirmInfo.extra)
        }
        Self.logger.info("n_action_open_api_service", body: "result_succ: auto: \(payload.isAutoConfirm) \(payload.code.desensitized())")
        showToast(isSucceeded: true, userDenied: false)
        completion?(.success(payload))
    }

    // 错误码定义见 https://bytedance.feishu.cn/docx/VoYod5ghAoauhbx9RsFcErxDnZb
    private func handleFailureCompletion(_ scenario: FailureScenario) {
        let errorInfo: OpenAPIAuthErrorInfo
        switch scenario {
        case .serverError(let error):
            let (code, message) = getErrorCodeAndMessage(error: error)
            errorInfo = OpenAPIAuthErrorInfo(code: code, message: message)
        case .clientError(let e):
            errorInfo = OpenAPIAuthErrorInfo(code: 20050, message: e.localizedDescription)
        case .userDenied:
            errorInfo = OpenAPIAuthErrorInfo(code: 20047, message: I18N.Lark_Passport_ThirdPartyAppAuthorization_Toast_AuthorizationRejected)
        case .unknown:
            errorInfo = OpenAPIAuthErrorInfo(code: 20050, message: I18N.Lark_Passport_ThirdPartyAppAuthorization_Toast_FailedToAuthorize)
        }
        Self.logger.error("n_action_open_api_service", body: "result_failure: \(errorInfo.code) \(errorInfo.message)")
        showToast(isSucceeded: false, userDenied: errorInfo.code == 20047)
        completion?(.failure(.error(errorInfo)))
    }

    private func getErrorCodeAndMessage(error: Error) -> (Int, String) {
        let errorCode: Int
        let errorMessage: String
        if let loginError = error as? V3LoginError {
            if case .badServerCode(let info) = loginError {
                errorCode = Int(info.rawCode)
                errorMessage = info.message
            } else {
                errorCode = loginError.errorCode
                errorMessage = loginError.localizedDescription
            }
        } else {
            errorCode = 20050
            errorMessage = I18N.Lark_Passport_ThirdPartyAppAuthorization_Toast_FailedToAuthorize
        }
        return (errorCode, errorMessage)
    }

    private enum SuccessScenario {
        case getAuthInfo(OpenAPIAuthGetAuthInfo)
        case confirm(OpenAPIAuthConfirmInfo)
    }

    private enum FailureScenario {
        case serverError(Error)
        case clientError(Error)
        case userDenied
        case unknown
    }

}

// 授权页面
extension OpenAPIAuthService {
    private func presentAuthSheet(_ info: OpenAPIAuthGetAuthInfo) {
        guard let topMost = PassportNavigator.getUserScopeTopMostVC(userResolver: userResolver) else { return }
        Self.logger.info("n_action_open_api_service", body: "auth sheet")
        let sheet = OpenAPIAuthInfoViewController(userResolver: self.userResolver, authInfo: info, allowAction: {
            // 用户确认授权
            self.allowAuth()
        }, denyAction: {
            // 用户手动拒绝授权
            self.denyAuth()
        })

        if Display.pad {
            sheet.modalPresentationStyle = .formSheet
            if #available(iOS 13.0, *) {
                sheet.isModalInPresentation = true
            }
            topMost.present(sheet, animated: true)
        } else {
            let displayHeight = min(OpenAPIAuthInfoViewController.calculateAuthSheetHeight(authInfo: info), UIScreen.main.bounds.height * 0.8)
            let config = UDActionPanelUIConfig(originY: UIScreen.main.bounds.height - displayHeight, canBeDragged: false, disablePanGestureViews: {
                if let view = sheet.view {
                    return [view]
                }
                return []
            })
            let panel = UDActionPanel(customViewController: sheet, config: config)
            Self.logger.info("n_action_guide_dialog_action_panel_show")
            topMost.present(panel, animated: true) {
                panel.setTapSwitch(isEnable: false)
            }
        }
    }

    private func allowAuth() {
        showLoading()
        guard let appID = latestParams?.appID else {
            Self.logger.error("n_action_open_api_service", body: "cannot find appid")
            handleFailureCompletion(.unknown)
            return
        }
        latestError = nil
        Self.logger.info("n_action_open_api_service", body: "allow auth")
        openAPIAuthAPI.confirmInner(appID: appID)
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
            .subscribe { [weak self] response in
                guard let self = self else { return }
                Self.logger.info("n_action_open_api_service", body: "response from confirm inner")
                self.removeLoading()

                guard let info = Self.decode(OpenAPIAuthConfirmInfo.self, from: response) else {
                    self.handleFailureCompletion(.unknown)
                    return
                }
                self.handleSuccessCompletion(.confirm(info))

            } onError: { [weak self] error in
                guard let self = self else { return }
                self.removeLoading()
                self.latestError = error
                let (code, message) = self.getErrorCodeAndMessage(error: error)
                var logID: String? = nil
                if let loginError = error as? V3LoginError {
                    if case .badServerCode(let info) = loginError {
                        logID = info.logID
                    }
                }
                self.presentErrorSheet(code: "\(code)", message: message, logID: logID)
            }
            .disposed(by: disposeBag)
    }

    private func denyAuth() {
        handleFailureCompletion(.userDenied)
    }
}

// 错误页面
extension OpenAPIAuthService {
    private func presentErrorSheet(code: String, message: String, logID: String?) {
        guard let topMost = PassportNavigator.getUserScopeTopMostVC(userResolver: userResolver) else { return }
        Self.logger.info("n_action_open_api_service", body: "present error sheet")
        let sheet = OpenAPIAuthErrorViewController(code: code, message: message, logID: logID, retryAction: {
            self.retryAuth()
        }, cancelAction: {
            // 回调错误
            self.cancelAuth()
        })

        if Display.pad {
            sheet.modalPresentationStyle = .formSheet
            if #available(iOS 13.0, *) {
                sheet.isModalInPresentation = true
            }
            topMost.present(sheet, animated: true)
        } else {
            let config = UDActionPanelUIConfig(originY: UIScreen.main.bounds.height - OpenAPIAuthErrorViewController.calculateErrorSheetHeight(code: code, message: message, logID: logID),
                                               canBeDragged: false,
                                               disablePanGestureViews: {
                if let view = sheet.view {
                    return [view]
                }
                return []
            })
            let panel = UDActionPanel(customViewController: sheet, config: config)
            Self.logger.info("n_action_guide_dialog_action_panel_show")
            topMost.present(panel, animated: true) {
                panel.setTapSwitch(isEnable: false)
            }
        }
    }

    private func cancelAuth() {
        Self.logger.info("n_action_open_api_service", body: "cancel auth")
        if let serverError = latestError {
            handleFailureCompletion(.serverError(serverError))
        } else {
            handleFailureCompletion(.unknown)
        }
    }

    private func retryAuth() {
        Self.logger.info("n_action_open_api_service", body: "retry auth")
        guard let params = latestParams else {
            Self.logger.warn("n_action_open_api_service", body: "latest params nil")
            handleFailureCompletion(.unknown)
            return
        }
        self.fetchAuthInfoInner(params: params)
    }
}

extension OpenAPIAuthService {
    private func showLoading() {
        SuiteLoginUtil.runOnMain {
            guard let topMost = PassportNavigator.getUserScopeTopMostVC(userResolver: self.userResolver) else { return }
            UDToast.showDefaultLoading(on: topMost.view)
        }
    }

    private func removeLoading() {
        SuiteLoginUtil.runOnMain {
            guard let topMost = PassportNavigator.getUserScopeTopMostVC(userResolver: self.userResolver) else { return }
            UDToast.removeToast(on: topMost.view)
        }
    }

    private func showToast(isSucceeded: Bool, userDenied: Bool) {
        SuiteLoginUtil.runOnMain {
            guard let topMost = PassportNavigator.getUserScopeTopMostVC(userResolver: self.userResolver) else { return }
            let config: UDToastConfig
            if isSucceeded {
                // 授权成功
                config = UDToastConfig(toastType: .success, text: I18N.Lark_Passport_ThirdPartyAppAuthorization_Toast_Authorized, operation: nil)
            } else {
                // 授权失败，你已拒绝授权 / 授权失败
                config = userDenied ?
                UDToastConfig(toastType: .error, text: I18N.Lark_Passport_ThirdPartyAppAuthorization_Toast_AuthorizationRejected, operation: nil) :
                UDToastConfig(toastType: .error, text: I18N.Lark_Passport_ThirdPartyAppAuthorization_Toast_FailedToAuthorize, operation: nil)
            }
            UDToast.showToast(with: config, on: topMost.view)
        }
    }
}

extension OpenAPIAuthService {
    private static func decode<T>(_ type: T.Type, from response: V3.SimpleResponse) -> T? where T: Decodable {
        guard let rawData = response.data else { return nil }
        do {
            let data = try JSONSerialization.data(withJSONObject: rawData)
            let info = try JSONDecoder().decode(T.self, from: data)
            return info
        } catch let error {
            Self.logger.error("n_action_open_api_service", body: "decode failed \(type), error: \(error)")
            return nil
        }
    }
}
