//
//  PassportTokenManager.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/12.
//

import Foundation
import LKCommonsLogging
import LarkContainer

class PassportTokenManager {

    static let logger = Logger.plog(PassportTokenManager.self, category: "SuiteLogin.PassportTokenManager")

    @Provider private var dependency: PassportDependency // user:checked (global-resolve)

    private var tokenMap: [String: String] = [:]

    var passportToken: String? {
        get {
            get(key: CommonConst.passportToken)
        }
        set {
            set(key: CommonConst.passportToken, value: newValue ?? "")
        }
    }

    var pwdToken: String? {
        get {
            get(key: CommonConst.passportPWDToken)
        }
        set {
            set(key: CommonConst.passportPWDToken, value: newValue ?? "")
        }
    }

    var verifyToken: String? {
        get {
            get(key: CommonConst.verifyToken)
        }
        set {
            set(key: CommonConst.verifyToken, value: newValue ?? "")
        }
    }

    var flowKey: String? {
        get {
            get(key: CommonConst.flowKey)
        }
        set {
            set(key: CommonConst.flowKey, value: newValue ?? "")
        }
    }

    var proxyUnit: String? {
        get {
            get(key: CommonConst.proxyUnit)
        }
        set {
            set(key: CommonConst.proxyUnit, value: newValue ?? "")
        }
    }

    var authFlowKey: String? {
        get {
            get(key: CommonConst.authFlowKey)
        }
        set {
            set(key: CommonConst.authFlowKey, value: newValue ?? "")
        }
    }

    func cleanToken() {
        Self.logger.info("clear passport token", method: .local)
        passportToken = nil
    }

    func updateTokenIfHas(_ map: [String: String]) {
        let keys = [
            CommonConst.passportToken,
            CommonConst.passportPWDToken,
            CommonConst.verifyToken,
            CommonConst.flowKey,
            CommonConst.proxyUnit,
            CommonConst.authFlowKey
        ]
        
        for key in keys {
            if let value = map[key] {
                tokenMap[key] = value
                dependency.setValue(value: value, forKey: key)
            }
        }
    }

}

extension PassportTokenManager {
    func get(key: String) -> String? {
        let globalStoreToken = dependency.value(forKey: key, defaultValue: "")
        let mapValue = tokenMap[key]
        if globalStoreToken.isEmpty {
            PassportTokenManager.logger.info("get \(key) from passport storage: \(mapValue?.desensitized())", method: .local)
            return mapValue
        } else {
            PassportTokenManager.logger.info("get \(key) from global storage: \(globalStoreToken.desensitized())", method: .local)
            return globalStoreToken
        }
    }

    func set(key: String, value: String) {
        PassportTokenManager.logger.info("set", additionalData: [
            "key": key,
            "value": value.desensitized()
        ], method: .local)
        tokenMap[key] = value
        dependency.setValue(value: value, forKey: key)
    }
}
