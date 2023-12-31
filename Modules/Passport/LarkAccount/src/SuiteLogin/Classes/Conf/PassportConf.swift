//
//  SuiteLoginConfiguration.swift
//  SuiteLogin
//
//  Created by quyiming on 2019/11/25.
//

import Foundation
import LarkLocalizations
import LKCommonsLogging
import RxSwift
import LarkReleaseConfig
import LarkAccountInterface
import LarkSensitivityControl

struct V3ConfigEnv {
    static let lark: String = "lark"
    static let feishu: String = "feishu"
}

struct Unit {
    static let NC: String = "eu_nc"
    static let EA: String = "eu_ea"
}

class PassportConf: PassportConfProtocol {

    // MARK: Public
    /// 应用ID， 默认 `.lark`
    var appID: Int = LarkAppID.lark

    var groupId: String = {
        if ReleaseConfig.groupId.isEmpty {
            V3LoginService.logger.warn("groupId is empty")
            return "com.bytedance.ee.passport"
        } else {
            return ReleaseConfig.groupId
        }
    }()

    /// staging featureID
    var stagingFeatureId: String? {
        get {
            return UserDefaults.standard.string(forKey: CommonConst.featureIdKey)
        }
        set {
            // set nil 和 set 空 都是删除 featureId
            if let value = newValue, !value.isEmpty {
                UserDefaults.standard.set(newValue, forKey: CommonConst.featureIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: CommonConst.featureIdKey)
            }
        }
    }

    var appsFlyerUID: String?

    var privacyPolicyUrlProvider: (() -> String)?

    var serviceTermUrlProvider: (() -> String)?

    var userDeletionAgreementUrlProvider: (() -> String)?

    /// 登录host url， 默认为 "https://internal-api-lark-api.feishu.cn"
    var apiUrlProvider: (() -> String)?

    /// 登录获取deviceId的域名
    var deviceIdUrlProvider: (() -> String)?

    var oneKeyLoginConfig: [OneKeyLoginConfig]?

    var registerPageSubtitleProvider: (() -> String)?

    var nameTextFieldPlaceholderProvider: (() -> String)?

    var appIcon: UIImage?

    var h5ReplaceFeatureList: [H5ReplaceFeature] = H5ReplaceFeature.allCases

    var featureSwitch: FeatureSwitchProtocol = AccountFeatureSwitchDefault()

    var appConfig: AppConfigProtocol = AppConfigDefault()

    // MARK: Private

    static let logger = Logger.plog(PassportConf.self, category: "SuiteLogin.Config")

    static let shared: PassportConf = PassportConf()

    private init() {}

    var serverInfoProvider: ServerInfoProvider = ServerInfoProvider()

    /// 设备类型 iOS为4
    static let terminalType: Int = 4
    /// 设备名称， 默认 `UIDevice.current.name`
    static let deviceName: String = {
        do{
            return try DeviceInfoEntry.getDeviceName(forToken: Token("LARK-PSDA-passport_http_header_device_name"), device: UIDevice.current)
        } catch {
            //业务方应该在此实现兜底逻辑
            return UIDevice.current.lu.modelName()
        }
    }()
    /// 设备操作系统信息， 默认 `"\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"`
    static let deviceOS: String = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    /// 设备 model， 默认 ` UIDevice.current.model`
    static let deviceModel: String = UIDevice.current.lu.modelName()

}
