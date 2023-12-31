//
//  IDPModel.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/1/13.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface

class IDPConfigModel {
    static let logger = Logger.plog(IDPConfigModel.self, category: "SuiteLogin.IDPConfigModel")

    private var authConfigKey: String = genKey("com.bytedance.ee.idp.auth")
    private var internalConfigKey: String = genKey("com.bytedance.ee.idp.internal")
    private var externalConfigKey: String = genKey("com.bytedance.ee.idp.external")

    let userDefaults: UserDefaults
    let store = PassportStore.shared

    init() {
        if let ud = UserDefaults(suiteName: "com.bytedance.ee.idp") {
            userDefaults = ud
        } else {
            userDefaults = UserDefaults.standard
            IDPConfigModel.logger.error("UserDefaults init with suiteName failed.")
        }
    }

    var authConfig: IDPAuthConfigModel? {
        get {
            return store.idpAuthConfig
        }
        set {
            store.idpAuthConfig = newValue
        }
    }

    var internalConfig: IDPInternalModel? {
        get {
            return store.idpInternalConfig
        }
        set {
            store.idpInternalConfig = newValue
        }
    }

    var internalConfigDict: [String: Any]?

    var externalConfig: [String: Any]? {
        get {
            guard let resultString = store.idpExternalConfig ?? userDefaults.string(forKey: self.externalConfigKey) else {
                IDPConfigModel.logger.warn("get external string from userDefaults nil")
                return nil
            }

            guard let resultData = resultString.data(using: .utf8) else {
                IDPConfigModel.logger.info("get external data from string nil")
                return nil
            }

            do {
                let result = try JSONSerialization.jsonObject(with: resultData, options: []) as? [String: Any]
                IDPConfigModel.logger.info("get external success")
                return result
            } catch {
                IDPConfigModel.logger.error("decode data to external error: \(error)")
                return nil
            }
        }
        set {
            guard let nValue = newValue else {
                IDPConfigModel.logger.warn("external store nil")
                userDefaults.set(nil, forKey: self.externalConfigKey)
                return
            }

            do {
                let resultData = try JSONSerialization.data(withJSONObject: nValue, options: [])
                let resultString = String(data: resultData, encoding: .utf8) ?? ""
                store.idpExternalConfig = resultString
                IDPConfigModel.logger.warn("store external success")
            } catch {
                IDPConfigModel.logger.error("encode external to data error: \(error)")
            }
        }
    }

    func removeAll() {
        IDPConfigModel.logger.info("remove all idp storage")
        
        store.idpAuthConfig = nil
        store.idpInternalConfig = nil
        store.idpExternalConfig = nil
    }

    var userAgent: String? {
        if let ua = internalConfigDict?["user_agent"] as? String, !ua.isEmpty {
            IDPConfigModel.logger.info("use UA: \(ua)")
            return ua
        } else {
            return nil
        }
    }
}

extension IDPConfigModel: PassportStoreMigratable {
    private func getAuthConfig() -> IDPAuthConfigModel? {
        guard let data = userDefaults.data(forKey: self.authConfigKey) else {
            IDPConfigModel.logger.warn("get auth config from userDefaults nil")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let conf = try decoder.decode(IDPAuthConfigModel.self, from: data)
            IDPConfigModel.logger.info("get auth config data success")
            return conf
        } catch {
            IDPConfigModel.logger.error("decode data to IDPAuthConfigModel error: \(error)")
            return nil
        }
        
    }
    
    private func getIDPInternalConfig() -> IDPInternalModel? {
        guard let data = userDefaults.data(forKey: self.internalConfigKey) else {
            IDPConfigModel.logger.warn("get internal from userDefaults nil")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let conf = try decoder.decode(IDPInternalModel.self, from: data)
            IDPConfigModel.logger.info("get internal data success")
            return conf
        } catch {
            IDPConfigModel.logger.error("decode data to IDPInternalModel error: \(error)")
            return nil
        }
    }
    
    func startMigration() -> Bool {

        store.idpAuthConfig = getAuthConfig()
        store.idpInternalConfig = getIDPInternalConfig()
        store.idpExternalConfig = userDefaults.string(forKey: externalConfigKey)
        
        for key in [self.authConfigKey, self.internalConfigKey, self.externalConfigKey] {
            userDefaults.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        return true
    }
}

struct IDPInternalModel: Codable {
    let logout: IDPFeatureSettingActionModel?
}

enum IDPFeatureSettingActionType: Int, Codable {
    case on = 0
    case off
    case modify
    case other
}

struct IDPFeatureSettingActionModel: Codable {
    let type: IDPFeatureSettingActionType
    let url: String?
}

struct IDPDefaultSettingModel: Codable {
    let defaultIdpType: String
    let idpTypes: [String]?

    enum CodingKeys: String, CodingKey {
        case defaultIdpType = "default_idp_type"
        case idpTypes = "idp_types"
    }
}

struct IDPAuthConfigModel: Codable {
    let url: String
    let securityId: String?
    let openMethod: String?
    let landURL: String?

    enum CodingKeys: String, CodingKey {
        case url
        case securityId = "security_id"
        case openMethod = "open_with"
        case landURL = "land_url"
    }
}

struct IDPLoginCallBackResponse: Codable {
    let code: Int
    let message: String?
    let securityId: String
    let state: String

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case securityId = "security_id"
        case state
    }
}

struct IDPLoginJSBResponse: Codable {
    let code: Int
    let message: String?
    let state: String
    let extraIdentity: ExtraIdentity?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case state
        case extraIdentity = "extra"
    }
}
