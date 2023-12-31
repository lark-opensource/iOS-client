//
//  IDPSDKService.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/4/9.
//

import Foundation
import AuthenticationServices
#if GOOGLE_SIGN_IN
import GoogleSignIn
#endif
import RoundedHUD
import LarkPerf
import LarkContainer
import EENavigator
import LKCommonsLogging
import UniverseDesignToast

enum GoogleClientID: String {
    case develop = "183836606264-1k3359v9srpjc45oq18ltcnipjgbclos.apps.googleusercontent.com"
    case release = "183836606264-a7trbpa3pb095e4fplepcls6ga1d0oiv.apps.googleusercontent.com"
}

class IDPSDKService: NSObject {
    static let logger = Logger.plog(IDPSDKService.self, category: "LarkAccount.IDPSDKService")

    private weak var viewController: UIViewController? {
        didSet {
            self.updateViewController(viewController: self.viewController)
        }
    }

    var hud: RoundedHUD?

    lazy var api: IdpAPI = {
        return IdpAPI()
    }()

    var loginService: V3LoginService

    private var extraInfo: [String: Any]?
    private var success: V3IDPLoginSuccess = nil
    private var error: V3IDPLoginError = nil

    @Provider var envManager: EnvironmentInterface

    init(loginService: V3LoginService) {
        self.loginService = loginService

        super.init()
        self.setup()
    }

    private func updateViewController(viewController: UIViewController?) {
#if GOOGLE_SIGN_IN
        GIDSignIn.sharedInstance()?.presentingViewController = viewController
#else
        assertionFailure()
#endif
    }
    
    private func setup() {
#if GOOGLE_SIGN_IN
        if [.release, .preRelease].contains(envManager.env.type) {
            GIDSignIn.sharedInstance().clientID = GoogleClientID.release.rawValue
        } else {
            GIDSignIn.sharedInstance().clientID = GoogleClientID.develop.rawValue
        }
        GIDSignIn.sharedInstance().delegate = self
#else
        assertionFailure()
#endif
    }

    @available(iOS 13.0, *)
    func signInForAppleID(from: UIViewController, extraInfo: [String: Any]?, success: V3IDPLoginSuccess = nil, error: V3IDPLoginError = nil) {
        self.viewController = from
        self.extraInfo = extraInfo
        self.success = success
        self.error = error

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func signInForGoogle(from: UIViewController, extraInfo: [String: Any]?, success: V3IDPLoginSuccess = nil, error: V3IDPLoginError = nil) {
#if GOOGLE_SIGN_IN
        self.viewController = from
        self.extraInfo = extraInfo
        self.success = success
        self.error = error

        GIDSignIn.sharedInstance()?.signIn()
#else
        assertionFailure()
#endif
    }

    func cleanup() {
        self.extraInfo = nil
        self.success = nil
        self.error = nil
    }
}

#if GOOGLE_SIGN_IN
extension IDPSDKService: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            self.error?(V3LoginError.clientError("\(error)"))
            self.cleanup()
            return
        }

        guard let idToken = user.authentication.idToken else { return }
        let profile: [String: Any] = [
            "name": [
                "firstName": user.profile.givenName,
                "lastName": user.profile.familyName
            ],
            "email": user.profile.email ?? ""
        ]
        let profileString = profile.jsonString()

        var params: [String: Any] = [
            CommonConst.authenticationChannel: LoginCredentialIdpChannel.google.rawValue
        ]
        if !profileString.isEmpty {
            params["profile"] = profileString
        }
        if let extraInfo = extraInfo {
            params = params.merging(extraInfo) { (_, new) in new }
        }

        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.idpVerifyResult.rawValue,
            MultiSceneMonitor.Const.type.rawValue: "sdk_result",
            MultiSceneMonitor.Const.result.rawValue: "success"
        ]

        let udToast = PassportLoadingService.showLoading()

        PassportMonitor.flush(PassportMonitorMetaLogin.startIdpLoginVerify,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.channel: ProbeConst.idpGoogle],
                              context: UniContext(.login))
        ProbeDurationHelper.startDuration(ProbeDurationHelper.loginIdpVerifyFlow)

        self.api.uploadIdpToken(token: idToken, extraInfo: params, sceneInfo: sceneInfo, success: { [weak self] (step, stepInfo) in
            self?.success?(.stepData(step: step, stepInfo: stepInfo))
            self?.cleanup()
            udToast?.remove()
            let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpVerifyFlow)
            PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginVerifyResult,
                                    eventName: ProbeConst.monitorEventName,
                                    categoryValueMap: [ProbeConst.channel: ProbeConst.idpGoogle, ProbeConst.duration: duration],
                                    context: UniContext(.login))
            .setResultTypeSuccess()
            .flush()
        }) { [weak self] (error) in
            self?.error?(error)
            self?.cleanup()
            udToast?.remove()
            let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpVerifyFlow)
            PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginVerifyResult,
                                    eventName: ProbeConst.monitorEventName,
                                    categoryValueMap: [ProbeConst.channel: ProbeConst.idpGoogle, ProbeConst.duration: duration],
                                    context: UniContext(.login))
            .setResultTypeFail()
            .setPassportErrorParams(error: error)
            .flush()
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        if let vc = self.viewController {
            RoundedHUD.showTips(with: BundleI18n.suiteLogin.Lark_Login_V3_ThirdParty_Call_failure, on: vc.view)
        } else {
            self.error?(V3LoginError.clientError("no valid vc after sign in with google"))
        }
    }
}
#endif

@available(iOS 13.0, *)
extension IDPSDKService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            self.error?(V3LoginError.clientError("no appleIDCredential after sign in with apple"))
            self.cleanup()
            return
        }
        guard let idTokenData = appleIDCredential.identityToken else {
            self.error?(V3LoginError.clientError("no idTokenData after sign in with apple"))
            self.cleanup()
            return
        }
        let idToken = String(data: idTokenData, encoding: .utf8) ?? ""
        let appleUserId = appleIDCredential.user
        let appleUserIdKey = "passport_idp_person_info" + appleUserId

        var profileString: String?

        if let fullName: PersonNameComponents = appleIDCredential.fullName,
            let email = appleIDCredential.email {
            let profile: [String: Any] = [
                "name": [
                    "firstName": fullName.givenName,
                    "lastName": fullName.familyName
                ],
                "email": email
            ]
            profileString = profile.jsonString()
            if let profileString = profileString {
                PassportStore.shared.setIDPUserProfile(profile: profileString, key: appleUserId)
            }
        }

        if profileString == nil {
            if let profile = PassportStore.shared.getIDPUserProfile(key: appleUserId) {
                profileString = profile
            } else if let profile = UserDefaults.standard.string(forKey: appleUserIdKey) {
                profileString = profile
                PassportStore.shared.setIDPUserProfile(profile: profile, key: appleUserId)
            }
        }

        var params: [String: Any] = [
            CommonConst.authenticationChannel: LoginCredentialIdpChannel.apple_id.rawValue
        ]
        if let profileString = profileString, !profileString.isEmpty {
            params["profile"] = profileString
        }
        if let extraInfo = extraInfo {
            params = params.merging(extraInfo) { (_, new) in new }
        }

        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.idpVerifyResult.rawValue,
            MultiSceneMonitor.Const.type.rawValue: "sdk_result",
            MultiSceneMonitor.Const.result.rawValue: "success"
        ]
        PassportMonitor.flush(PassportMonitorMetaLogin.startIdpLoginVerify,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.channel: ProbeConst.idpApple],
                              context: UniContext(.login))
        ProbeDurationHelper.startDuration(ProbeDurationHelper.loginIdpVerifyFlow)
        self.api.uploadIdpToken(token: idToken, extraInfo: params, sceneInfo: sceneInfo, success: { (step, stepInfo) in
            self.success?(.stepData(step: step, stepInfo: stepInfo))
            self.cleanup()
            let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpVerifyFlow)
            PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginVerifyResult,
                                    eventName: ProbeConst.monitorEventName,
                                    categoryValueMap: [ProbeConst.channel: ProbeConst.idpApple, ProbeConst.duration: duration],
                                    context: UniContext(.login))
            .setResultTypeSuccess()
            .flush()
        }) { (error) in
            self.error?(error)
            self.cleanup()
            let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpVerifyFlow)
            PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginVerifyResult,
                                    eventName: ProbeConst.monitorEventName,
                                    categoryValueMap: [ProbeConst.channel: ProbeConst.idpApple, ProbeConst.duration: duration],
                                    context: UniContext(.login))
            .setResultTypeFail()
            .setPassportErrorParams(error: error)
            .flush()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error?(V3LoginError.clientError("\(error)"))
        self.cleanup()
    }
}

@available(iOS 13.0, *)
extension IDPSDKService: ASAuthorizationControllerPresentationContextProviding {
    // swiftlint:disable ForceUnwrapping
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let viewController = self.viewController else {
            if let rootWindow = PassportNavigator.keyWindow {
                return rootWindow
            }
            Self.logger.errorWithAssertion("no main scene for presentationAnchor")
            return UIApplication.shared.windows.first!
        }
        return viewController.view.window!
    }
    // swiftlint:enable ForceUnwrapping
}
