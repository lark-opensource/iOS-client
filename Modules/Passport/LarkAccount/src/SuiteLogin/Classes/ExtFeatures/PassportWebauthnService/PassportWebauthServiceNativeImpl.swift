//
//  PassportWebauthServiceNativeImpl.swift
//  LarkAccount
//
//  Created by ZhaoKejie on 2023/6/8.
//

import Foundation
import LocalAuthentication
import LarkContainer
import UniverseDesignTheme
import UniverseDesignToast
import LKCommonsLogging
import ECOProbeMeta
import AuthenticationServices

// TODO: 几个参数的转化，timeout、transport等

@available(iOS 16.0, *)
class PassportWebauthServiceNativeImpl: PassportWebAuthServiceBaseImpl, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private static let logger = Logger.log(PassportWebauthServiceNativeImpl.self, category: "PassportWebauthServiceNativeImpl")

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        PassportNavigator.keyWindow ?? ASPresentationAnchor()
    }

    override func requestAuthenticator(params: [String : Any]) {

        let webauthnRequests: [ASAuthorizationRequest]
        switch actionType {
        case .auth:
            webauthnRequests = createAuthRequest(params: params)
        case .register:
            webauthnRequests = createRegisterRequest(params: params)
        }

        if webauthnRequests.isEmpty {
            end(endReason: .otherError, stage: "requestAuthenticator")
            return
        }
        let authController = ASAuthorizationController(authorizationRequests: webauthnRequests)
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()

    }

    func createRegisterRequest(params: [String: Any]) -> [ASAuthorizationRequest] {
        // 依赖方信息
        guard let rpEntity = params["relying_party_entity"] as? [String: Any],
              let rpID = rpEntity["id"] as? String else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty rpID")
            return []
        }

        // 用户信息
        guard let userEntity = params["user_entity"] as? [String: Any],
              let userID = Self.convertBase64URL(base64: userEntity["id"] as? String),
              let userName = userEntity["name"] as? String,
              let userDisplayName = userEntity["display_name"] as? String else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty userInfo")
            return []
        }

        // 挑战码
        guard let challengeData = Self.convertBase64URL(base64: params["challenge"] as? String) else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty challenge")
            return []
        }

        // excludedCredentials
        guard let excludeCredentials = params["credential_exclude_list"] as? [[String: Any]] else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty excluded credentials")
            return []
        }

        guard let authenticatorSelection = params["authenticator_selection"] as? [String: Any],
              let residentKey = authenticatorSelection["resident_key"] as? String,
              let userVerification = authenticatorSelection["user_verification"] as? String else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty authenticatorSelection")
            return []
        }
        let attachment = authenticatorSelection["attachment"] as? String ?? "none"

        guard let attestationPreference = params["attestation_preference"] as? String else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty authenticatorSelection")
            return []
        }

        // TODO: 注意extensions字段是否要处理，目前Apple缺少相关API，且与服务端沟通暂不需要，后续关注Apple是否会更新，或者自己实现部分能力

        // 创建平台认证器的请求
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        let platformRequest = platformProvider.createCredentialRegistrationRequest(challenge: challengeData, name: userName, userID: userID)
        platformRequest.displayName = userDisplayName
        platformRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: userVerification)

        // 创建物理密钥认证器请求
        let securityKeyProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        let securityKeyRequest = securityKeyProvider.createCredentialRegistrationRequest(challenge: challengeData, displayName: userDisplayName, name: userName, userID: userID)
        securityKeyRequest.attestationPreference = .direct
        securityKeyRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: userVerification)
        securityKeyRequest.credentialParameters = [ASAuthorizationPublicKeyCredentialParameters(algorithm: .ES256)]
        var exCredentailsIDs: [ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor] = []
        excludeCredentials.forEach { credentials in
            if let credentialID = Self.convertBase64URL(base64: credentials["id"] as? String) {
                exCredentailsIDs.append(ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(credentialID: credentialID, transports: [.usb, .bluetooth, .nfc]))
            }
        }
        securityKeyRequest.excludedCredentials = exCredentailsIDs
        securityKeyRequest.residentKeyPreference = ASAuthorizationPublicKeyCredentialResidentKeyPreference(rawValue: residentKey)

        switch attachment {
        case "platform":
            return [platformRequest]
        case "cross-platform":
            return [securityKeyRequest]
        default:
            return [platformRequest, securityKeyRequest]
        }
    }

    func createAuthRequest(params: [String: Any]) -> [ASAuthorizationRequest] {
        // 依赖方信息
        guard let rpID = params["rp_id"] as? String else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty rpID")
            return []
        }

        // 挑战码
        guard let challengeData = Self.convertBase64URL(base64: params["challenge"] as? String) else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty challenge")
            return []
        }

        // excludedCredentials
        guard let allowedCredentials = params["allowed_credentials"] as? [[String: Any]] else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty excluded credentials")
            return []
        }

        guard let userVerification = params["user_verification"] as? String else {
            Self.logger.error("n_action_webauthn_nativeImpl", body: "empty userVerification")
            return []
        }


        // TODO: 注意extensions timeout字段是否要处理

        // 创建平台认证器的请求
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        let platformRequest = platformProvider.createCredentialAssertionRequest(challenge: challengeData)
        platformRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(userVerification)
        var allowPlatformCredentailsIDs: [ASAuthorizationPlatformPublicKeyCredentialDescriptor] = []
        allowedCredentials.forEach { credentials in
            if let credentialID = Self.convertBase64URL(base64: credentials["id"] as? String) {
                allowPlatformCredentailsIDs.append(ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: credentialID))
            }

        }
        platformRequest.allowedCredentials = allowPlatformCredentailsIDs


        // 创建物理密钥认证器请求
        let securityKeyProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        let securityKeyRequest = securityKeyProvider.createCredentialAssertionRequest(challenge: challengeData)
        var allowedSecurityCredentials: [ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor] = []
        securityKeyRequest.allowedCredentials = allowedSecurityCredentials
        securityKeyRequest.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(userVerification)
        allowedCredentials.forEach { credentials in
            if let credentialID = Self.convertBase64URL(base64: credentials["id"] as? String) {
                allowedSecurityCredentials.append(ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(credentialID: credentialID, transports: [.bluetooth, .nfc, .usb]))
            }
        }
        securityKeyRequest.allowedCredentials = allowedSecurityCredentials

        return [platformRequest, securityKeyRequest]
    }
}

// MARK: - 接受系统回调的代理方法
@available(iOS 16.0, *)
extension PassportWebauthServiceNativeImpl: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPublicKeyCredentialRegistration {

            let extensions: [String: Any] = [:]
            var transports: [String] = []
            if credential is ASAuthorizationPlatformPublicKeyCredentialRegistration {
                transports += ["internal"]
            } else if credential is ASAuthorizationSecurityKeyPublicKeyCredentialRegistration {
                transports += ["usb"]
            }
            var credentialCreationData: [String: Any] = ["id": Self.convertByte(data: credential.credentialID),
                                                   "raw_id": Self.convertByte(data: credential.credentialID),
                                                   "type": "public-key",
                                                   "extensions": extensions,
                                                   "transports": transports] as [String : Any]

            let attestationResponse: [String: Any] = ["client_data_json": Self.convertByte(data: credential.rawClientDataJSON),
                                                      "attestation_object": Self.convertByte(data: credential.rawAttestationObject)]

            credentialCreationData["attestation_response"] = attestationResponse

            let finishParams = ["credential_creation_data": credentialCreationData,
                                "verify_type": "ios_passkey"] as [String : Any]

            processFinish(params: finishParams)

        } else if let credential = authorization.credential as? ASAuthorizationPublicKeyCredentialAssertion {
            let extensions: [String: Any] = [:]
            var credentialAssertionResponse = ["id": Self.convertByte(data: credential.credentialID),
                                               "raw_id": Self.convertByte(data: credential.credentialID),
                                               "type": "public-key",
                                               "extensions": extensions] as [String : Any]

            let response = ["authenticator_data": Self.convertByte(data: credential.rawAuthenticatorData),
                            "client_data_json": Self.convertByte(data: credential.rawClientDataJSON),
                            "signature": Self.convertByte(data: credential.signature),
                            "user_handle": Self.convertByte(data: credential.userID)] as [String : Any]
            credentialAssertionResponse["response"] = response
            let finishParams = ["credential_assertion_response": credentialAssertionResponse,
                                "verify_type": "ios_passkey"] as [String : Any]

            processFinish(params: finishParams)
        } else {
            end(endReason: .otherError, stage: "didCompleteWithAuthorization")
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError: Error) {
      // Handle the error.
        end(endReason: .otherError, stage: "didCompleteWithError")
        Self.logger.error("n_action_webauthn_nativeImpl",error: didCompleteWithError)
    }

}
