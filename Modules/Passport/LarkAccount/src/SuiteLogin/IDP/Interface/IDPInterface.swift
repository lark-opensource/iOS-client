//
//  IDPInterface.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2020/9/29.
//

import Foundation
import RxSwift

enum IDPServiceStep {
    case inAppWebPage(vc: UIViewController)
    case systemWebPage(url: String)
    case stepData(step: String, stepInfo: [String: Any]?)
}

protocol IDPServiceProtocol {
    func fetchConfigForIDP(
        _ body: SSOUrlReqBody
    ) -> Observable<V3.Step>

    /**
     根据 服务端配置、客户端配置决定的 support C端IdP channel
     */
    var currentSupportCIdPChannels: [LoginCredentialIdpChannel] { get }

    /**
     根据 服务端配置、客户端配置、客户端环境(版本、SDK集成情况) 最终决定的 support C端IdP channel
     */
    var resultSupportCIdPChannels: [LoginCredentialIdpChannel] { get }

    func signInWith(
        channel: LoginCredentialIdpChannel?,
        idpLoginInfo: IDPLoginInfo?,
        from: UIViewController,
        sceneInfo: [String: String],
        switchUserStatusSub: PublishSubject<SwitchUserStatus>?,
        context: UniContextProtocol
    ) -> Observable<IDPServiceStep>
}

typealias V3IDPLoginSuccess = ((IDPServiceStep) -> Void)?
typealias V3IDPLoginError = ((Error) -> Void)?

// MARK: IDPWebViewServiceProtocol
typealias IDPWebViewServiceProtocol = IDPLoginServiceProtocol & IDPBridgeServiceProtocol
protocol IDPLoginServiceProtocol: AnyObject {
    func loginPageForIDPName(
        _ idpName: String?,
        context: UniContextProtocol,
        success: V3IDPLoginSuccess,
        error: V3IDPLoginError
    ) -> UIViewController

    /// idp login vc
    /// - Parameters:
    ///   - idpLoginInfo: idp login server data contains url
    ///   - eventBus: default use login event bus
    ///   - switchUserStatusSub: sub for switch user status change
    func loginPageForIDPLoginInfo(
        _ idpLoginInfo: IDPLoginInfo,
        context: UniContextProtocol,
        passportEventBus: PassportEventBusProtocol?,
        switchUserStatusSub: PublishSubject<SwitchUserStatus>?,
        from: UIViewController,
        success: V3IDPLoginSuccess,
        error: V3IDPLoginError
    )

    func switchIDP(_ idpName: String, completion: @escaping (Bool, Error?) -> Void)

    func fetchNext(state: String,
                   successCallback: (() -> Void)?,
                   errorCallback: V3IDPLoginError)

    func fetchConfigForIDP(
        _ body: SSOUrlReqBody
    ) -> Observable<V3.Step>

    func isPageValidFor(vc: UIViewController) -> Bool
    func isSecurityIdMatch(identifier: String) -> Bool
}

protocol IDPBridgeServiceProtocol: AnyObject {
    func getIDPExternalData() -> [String: Any]
    func finishedLogin(_ args: [String: Any])
    func getIDPAuthConfigData() -> [String: Any]
}

