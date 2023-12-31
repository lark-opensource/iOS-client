//
//  PassportWebAuthnServiceBrowserImpl.swift
//  LarkAccount
//
//  Created by ZhaoKejie on 2023/6/8.
//

import Foundation
import LarkContainer
import LarkLocalizations
import UniverseDesignTheme
import UniverseDesignToast
import LKCommonsLogging
import ECOProbeMeta
import AuthenticationServices

@available(iOS 14.0, *)
class PassportWebAuthServiceBrowserImpl: PassportWebAuthServiceBaseImpl, ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        PassportNavigator.keyWindow ?? ASPresentationAnchor()
    }

    private static let logger = Logger.plog(PassportWebAuthServiceBrowserImpl.self, category: "PassportWebAuthServiceBrowserImpl")

    var session: ASWebAuthenticationSession?

    let scheme: String = "larkfido2"

    /// 认证流程展示的window
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        PassportNavigator.keyWindow ?? ASPresentationAnchor()
    }

    // MARK: - Init方法
    convenience init(actionType: ActionType,
                     context: UniContextProtocol,
                     addtionalParams: [String: Any],
                     callback: @escaping ((Bool, [String: Any]) -> Void),
                     usePackageDomain: Bool = false,
                     errorHandler: ((Error) -> Void)? = nil) {
        self.init(actionType: actionType, context: context, addtionalParams: addtionalParams)
        if actionType == .register {
            self.addtionalParams["attestation_preference"] = attestationPreference
            self.addtionalParams["authenticator_criteria"] = authenticatorCriteria
        }
        self.callback = callback
        self.errorHandler = errorHandler
        self.usePackageDomain = usePackageDomain
    }

    // MARK: - 对于不同iOS/Safari版本的一些兼容性参数
    // https://developer.apple.com/documentation/safari-release-notes/safari-14_1-release-notes

    /// 在浏览器中是否需要用户的交互才能唤起认证
    private let isNeedInteraction: Bool = {
        if #available(iOS 15.6, *) {
            return false
        } else {
            return true
        }
    }()

    /// 表明依赖方是否需要证明
    private let attestationPreference: String? = {
        if #available(iOS 14.5, *) {
            return nil
        } else {
            return "none"
        }
    }()

    /// 是否需要验证用户本人
    private let authenticatorCriteria: [String: Any]? = {
        if #available(iOS 14.5, *){
            return nil
        } else {
            return ["user_verification": "discouraged"]
        }
    }()


    override func requestAuthenticator(params: [String: Any]) {
        // 准备打开认证浏览器的地址
        let domainKey = actionType == .auth ? "authn_domain" : "registration_domain"
        guard var urlStr = params[domainKey] as? String else {
            self.end(endReason: .stepError, stage: "requestAuthenticator")
            Self.logger.error("n_action_webAuthn_browserImpl", body: "domain_error")
            return
        }

        urlStr.append("/\(CommonConst.v4APIPathPrefix)/\(APPID.fidoPage.apiIdentify())")

        if var url = URL(string: urlStr),
           let stepData = try? params.asData() {

            // 需要判断服务端是否下发https的scheme前缀，否则需要手动加上
            if !(["http", "https"].contains(url.scheme?.lowercased())) {
                var urlNew = URLComponents(string: urlStr)
                urlNew?.scheme = "https"
                if let urlNew = urlNew?.url {
                    url = urlNew
                }
            }

            // 准备打开验证浏览器需要的参数
            let p = PassportWebAuthServiceBrowserImpl.convertByte(data: stepData)
            let action = String(self.actionType.rawValue)
            let theme = UDThemeManager.getRealUserInterfaceStyle() == .dark ? "dark": "light"
            let currentLang = LanguageManager.currentLanguage.rawValue
            var urlParams: [String: String]
            urlParams = ["action": action,
                         "lang": currentLang,
                         "theme": theme,
                         "p": p,
                         "needInteraction": self.isNeedInteraction.stringValue]
            if let beginLogID = beginLogID {
                urlParams["logid"] = beginLogID
            }
            url = url.append(parameters: urlParams)

            // 注册的authenticationsession定义
            self.session = ASWebAuthenticationSession(url: url, callbackURLScheme: self.scheme, completionHandler: { [weak self] callbackUrl, error in
                guard let self = self else { return }
                // 回调block的定义
                // 打开内置浏览器认证失败、或者用户手动关闭等
                if let error = error {
                    self.end(endReason: .userCancel, stage: "requestAuthenticator")
                    Self.logger.error("n_action_webAuthn_browserImpl", body: "browser_error",  error: error)
                    return
                }

                // 正常收到回调消息，处理由浏览器返回的回调
                if let p = callbackUrl?.queryParameters["p"],
                   let action = callbackUrl?.queryParameters["action"] {

                    // action == 2 表示认证过程失败, 透传前端的错误
                    if action == "2" {
                        let errMsg = callbackUrl?.queryParameters["error"]
                        self.end(endReason: .browserError(errMsg), stage: "requestAuthenticator")
                        return
                    }

                    //解析base64数据结果, 并进入finish流程
                    if let paramsData = PassportWebAuthServiceBrowserImpl.convertBase64URL(base64: p),
                       let paramsDict = try? JSONSerialization.jsonObject(with: paramsData, options: .mutableContainers) as? [String: Any] {
                        self.processFinish(params: paramsDict)

                    } else {
                        //base64数据解析失败
                        self.end(endReason: .otherError, stage: "requestAuthenticator")
                        Self.logger.error("n_action_webAuthn_browserImpl", body: "base64_decode_error")
                    }

                } else {
                    //浏览器callback数据反序列化失败
                    self.end(endReason: .otherError, stage: "requestAuthenticator")
                    Self.logger.error("n_action_webAuthn_browserImpl", body: "browser_callback_error")
                }

            })
            // 开始执行内置浏览器验证Session
            if let session = session {
                // 设置内置浏览器与Safari浏览器中的隐私数据隔离
                session.prefersEphemeralWebBrowserSession = true
                // 设置内置浏览器展示的window
                session.presentationContextProvider = self
                session.start()
            } else {
                Self.logger.error("n_action_webAuthn_browserImpl", body: "session_error")
                self.end(endReason: .otherError, stage: "requestAuthenticator")
            }
        }
    }

}
