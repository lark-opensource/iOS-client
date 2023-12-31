//
//  DisposableLoginManager.swift
//  LarkAccount
//
//  Created by tangyunfei.tyf on 2021/2/8.
//

import Foundation
import Homeric
import RxSwift
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface
import LarkReleaseConfig

class DisposableLoginManager {
    static let logger = Logger.plog(DisposableLoginManager.self, category: "LarkAccount.DisposableLoginManager")

    let loginService: V3LoginService
    let userManager: UserManager
    let disposableLoginConfigAPI: DisposableLoginConfigAPI

    private let _userResolver: UserResolver?
    private var userResolver: UserResolver {
        return _userResolver ?? PassportUserScope.getCurrentUserResolver() // user:current
    }

    init(resolver: UserResolver?) throws {
        self._userResolver = resolver
        let r: UserResolver = resolver ?? PassportUserScope.getCurrentUserResolver() // user:current
        loginService = try r.resolve(assert: V3LoginService.self)
        userManager = try r.resolve(assert: UserManager.self)
        disposableLoginConfigAPI = try r.resolve(assert: DisposableLoginConfigAPI.self)
    }

    private let disposeBag = DisposeBag()

    func generateDisposableLoginToken(identifier: String, completion: @escaping (Result<DisposableLoginInfo, DisposableLoginError>) -> Void) {
        guard let user = userManager.getUser(userID: userResolver.userID),
              let unit = user.user.unit else {
            Self.logger.error("disposable token generation failed: unlogin, isLoggedIn: \(self.loginService.store.isLoggedIn), currentUser: \(String(describing: userManager.getUser(userID: userResolver.userID)?.description))")
            completion(.failure(DisposableLoginError.unLogin))
            return
        }

        let sessionKey = user.suiteSessionKey
        let deviceLoginId = self.loginService.deviceService.deviceLoginId
        let deviceId = self.loginService.deviceService.deviceId
        let timestamp = Int(exactly: floor(Date().timeIntervalSince1970)) ?? 0
        let userId = user.userID

        Self.logger.info("disposable token params, deviceLoginId: \(deviceLoginId), deviceId: \(deviceId), unit: \(unit), timestamp: \(timestamp), userId: \(userId)")

        guard !deviceLoginId.isEmpty,
              !deviceId.isEmpty,
              !unit.isEmpty else {
            Self.logger.error("disposable token params invalid, deviceLoginId: \(deviceLoginId), deviceId: \(deviceId), unit: \(unit)")
            completion(.failure(DisposableLoginError.paramsInvalid))
            return
        }

        self.disposableLoginConfigAPI.getDisposableLoginConfig()
            .subscribe(onNext: { [weak self] (config: [Int: String]) in
                guard let self = self else { return }
                Self.logger.info("get config success")
                let token = self.generateToken(userId: userId, deviceId: deviceId, timestamp: timestamp, sessionKey: sessionKey ?? "")
                if let realToken = token {
                    let tokenItem = DisposableLoginItem(
                        key: "disposable_login_token",
                        value: realToken
                    )

                    let userIdItem = DisposableLoginItem(
                        key: "user_id",
                        value: userId
                    )

                    let deviceLoginIdItem = DisposableLoginItem(
                        key: "device_login_id",
                        value: deviceLoginId
                    )

                    let timestampItem = DisposableLoginItem(
                        key: "timestamp",
                        value: timestamp
                    )
                    
                    let unitItem = DisposableLoginItem(
                        key: "unit", value: "\(unit)"
                    )
                    
                    // 支持授权免登 Lark Design-Web和PC免登-2021.05.10
                    let authAutoLoginItem = DisposableLoginItem(
                        key: "pwd_less_login_auth",
                        value: "1"
                    )
                    
                    let versionItem = DisposableLoginItem(
                        key: "version", value: "v3"
                    )
                    
                    let tenantBrandItem = DisposableLoginItem(key: "tenant_brand", value: "\(user.user.tenant.brand)")
                    
                    let pkgBrandItem = DisposableLoginItem(
                        key: "pkg_brand", value: ReleaseConfig.isLark ? "lark" : "feishu"
                    )
                    
                    completion(.success(DisposableLoginInfo(
                        token: tokenItem,
                        userId: userIdItem,
                        deviceLoginId: deviceLoginIdItem,
                        timestamp: timestampItem,
                        authAutoLogin: authAutoLoginItem,
                        unitItem: unitItem,
                        versionItem: versionItem,
                        tenantBrandItem: tenantBrandItem,
                        pkgBrandItem: pkgBrandItem
                    )))
                    
                } else {
                    Self.logger.error("disposable token generation failed: tokenGenerationError")
                    completion(.failure(DisposableLoginError.tokenGenerationError))
                }
            }, onError: { (error) in
                Self.logger.error("disposable token generation failed: fetchConfigError \(error)")
                completion(.failure(DisposableLoginError.fetchConfigError(error)))
            }).disposed(by: disposeBag)
    }

    func generateToken(userId: String, deviceId: String, timestamp: Int, sessionKey: String) -> String? {
        let disposableLoginInfo: [String: String] = [
            "timestamp": "\(timestamp)",
            "device_id": deviceId,
            "user_id": userId
        ]

        var parts: [String] = []
        for (k, v) in disposableLoginInfo.sorted(by: {$0.0 < $1.0}) {
            let currentPart = "\(String(describing: k))=\(String(describing: v))"
            parts.append(currentPart)
        }
        let disposableLoginInfoInString = parts.joined(separator: "&")
        let beforeTokenGenerationTime = Date()
        let token = PassportCrypto.sha256.hash(message: disposableLoginInfoInString, salt: sessionKey)
        let timeIntervalInMilliseconds = Date().timeIntervalSince(beforeTokenGenerationTime) * 1000
        SuiteLoginTracker.track(Homeric.SIGN_TOKEN_SHA256_TIME, params: [
            "time": timeIntervalInMilliseconds,
            "result": "success"
        ])
        Self.logger.info("disposable token generation time is \(timeIntervalInMilliseconds)")

        return token
    }

    func validAppIdForIdentifier(identifier: String, config: [Int: String]) -> Int? {
        guard !config.isEmpty else {
            Self.logger.error("config is empty")
            return nil
        }

        for (appId, regexString) in config {
            do {
                let regex = try NSRegularExpression(pattern: regexString, options: .caseInsensitive)
                let identifierForRegex = identifier as NSString
                if regex.firstMatch(in: identifier, range: NSRange(location: 0, length: identifierForRegex.length)) != nil {
                    return appId
                } else {
                    Self.logger.info("no match for identifier: \(identifier) with regexString: \(regexString)")
                    continue
                }
            } catch {
                Self.logger.error("throwed an error: \(error.localizedDescription) when matching identifier: \(identifier) with regexString: \(regexString)")
                continue
            }
        }

        return nil
    }
}
