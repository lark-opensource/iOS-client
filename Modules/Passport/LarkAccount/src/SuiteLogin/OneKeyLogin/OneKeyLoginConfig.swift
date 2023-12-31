//
//  OneKeyLoginConfig.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/11.
//

import Foundation
import LarkAccountInterface
import LarkFoundation
import LarkReleaseConfig
import LarkSetting
import LKCommonsLogging

extension OneKeyLoginService {
    var carrierName: String {
        switch self {
        case .mobile: return I18N.Lark_Login_mobileOperatorChinaMobile
        case .unicom: return I18N.Lark_Login_mobileOperatorChinaUnicom
        case .telecom: return I18N.Lark_Login_mobileOperatorChinaTelecom
        }
    }

    func config() -> OneKeyLoginConfig {
        switch self {
        case .mobile: return .mobile
        case .telecom: return .telecom
        case .unicom: return .unicom
        }
    }
}

extension OneKeyLoginService {
    var trackName: String {
        return "china_" + rawValue
    }
}

// Original Config Info: https://bytedance.feishu.cn/sheets/shtcnJc70L3U5M2BUuTgSyGJ3yd#t9zvzp
extension OneKeyLoginConfig {

    static func getOneKeySettingConfig() -> OneKeyLoginCompatibleConfig? {
        guard let configs = try? SettingManager.shared.setting(with: [OneKeyLoginCompatibleConfig].self, key: UserSettingKey.make(userKeyLiteral: "passport_onekey_login_compatible")) else { // user:checked
            OneKeyLogin.logger.error("n_action_one_key_login: setting decoding error")
            return nil
        }
        guard let config = configs.first(where: { $0.aid == LarkReleaseConfig.ReleaseConfig.appId }) else {
            OneKeyLogin.logger.error("n_action_one_key_login: setting config filter error")
            return nil
        }
        return config
    }

    static func getOneKeyPayload(_ config: OneKeyLoginCompatibleConfig, for carrier: String) -> OneKeyLoginCompatiblePayload? {
        guard let payload = config.onekeyConfig.first(where: { $0.carrier == carrier }) else {
            OneKeyLogin.logger.error("n_action_one_key_login: setting carrier error")
            return nil
        }
        OneKeyLogin.logger.info("n_action_one_key_login: get config for \(carrier)")
        return payload
    }
    
    static var mobile: OneKeyLoginConfig {
        guard let config = getOneKeySettingConfig(), let payload = getOneKeyPayload(config, for: "cm") else {
            let appID = Bundle.main.infoDictionary?["MOBILE_APPID"] as? String ?? ""
            let appKey = Bundle.main.infoDictionary?["MOBILE_APPKEY"] as? String ?? ""
            return OneKeyLoginConfig(service: .mobile, appId: appID, appKey: appKey)
        }
        return OneKeyLoginConfig(service: .mobile, appId: payload.appId, appKey: payload.appKey)
    }

    static var unicom: OneKeyLoginConfig {
        guard let config = getOneKeySettingConfig(), let payload = getOneKeyPayload(config, for: "cu") else {
            let appID = Bundle.main.infoDictionary?["UNICOM_APPID"] as? String ?? ""
            let appKey = Bundle.main.infoDictionary?["UNICOM_APPKEY"] as? String ?? ""
            return OneKeyLoginConfig(service: .unicom, appId: appID, appKey: appKey)
        }
        return OneKeyLoginConfig(service: .unicom, appId: payload.appId, appKey: payload.appKey)
    }

    static var telecom: OneKeyLoginConfig {
        guard let config = getOneKeySettingConfig(), let payload = getOneKeyPayload(config, for: "ct") else {
            let appID = Bundle.main.infoDictionary?["TELECOM_APPID"] as? String ?? ""
            let appKey = Bundle.main.infoDictionary?["TELECOM_APPKEY"] as? String ?? ""
            return OneKeyLoginConfig(service: .telecom, appId: appID, appKey: appKey)
        }
        return OneKeyLoginConfig(service: .telecom, appId: payload.appId, appKey: payload.appKey)
    }
}

struct OneKeyLoginPayload: Decodable {
    let appId: String
    let appKey: String
}

/// 从 setting 拉取的一键登录配置
struct OneKeyLoginSettingConfig: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "passport_onekey_login")
    
    let mobile: OneKeyLoginPayload
    let unicom: OneKeyLoginPayload
    let telecom: OneKeyLoginPayload
    
    enum CodingKeys: String, CodingKey {
        case mobile = "cm"
        case unicom = "cu"
        case telecom = "ct"
    }
}

struct OneKeyLoginCompatibleConfig: Decodable {
    let aid: String
    let onekeyConfig: [OneKeyLoginCompatiblePayload]
}

struct OneKeyLoginCompatiblePayload: Decodable {
    let appId: String
    let appKey: String
    let carrier: String
}
