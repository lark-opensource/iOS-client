//
//  AccountService+UG.swift
//  LarkAccountInterface
//
//  Created by bytedance on 2022/2/15.
//

import Foundation

/// 提供给UG 相关的接口
public protocol AccountServiceUG {

    /// 获取是否开启了ug的注册
    func getABTestValueForUGRegist(onResult: @escaping (Bool) -> Void)

    /// 通过TCC获取是否开启Global注册，隐藏立即注册按钮
    func getTCCValueForGlobalRegist(onResult: @escaping (Bool) -> Void)

    /// 注册 passport 状态机
    /// stepName: 事件名
    /// 执行回调: stepInfo为跟服务端约定的结构
    func registPassportEventBus(stepName: String,
                                callback: @escaping (_ stepInfo: [String: Any]) -> Void) 

    /// 往 passport 状态机 push 事件.
    func dispatchNext(stepInfo: [String: Any], success: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void)

    //joinByCode特化处理
    func joinByCode(code: String, stepInfo: [String: Any], success: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void)

    /// 打印日志
    func log(_ msg: String)

    func getLang() -> [String: String]

    func enterGlobalRegistEnterProbe()

    func fallbackProbe(by reason: String, in scene: String)

    func globalRegistTimeoutNum() -> Int

    func enableLarkGlobalOffline() -> Bool

    func passportOfflineConfig() -> PassportOfflineConfig

    func subscribePassportOfflineConfig(handler: @escaping (PassportOfflineConfig) -> Void)

    func finishGlobalRegistProbe(enableOffline: Bool, duration: Int)

}

public struct PassportOfflineConfig: Codable {
    public var needOffline: Bool

    public var offlineConfig: [OfflineConfig]

    enum CodingKeys: String, CodingKey {
        case needOffline = "need_offline"
        case offlineConfig = "offline_config"
    }

    public static var defaultConfig: PassportOfflineConfig = {
        let defaultConfig = OfflineConfig(accessKey: "", channels: [], prefixes: [])
        return PassportOfflineConfig(needOffline: false, offlineConfig: [defaultConfig])
    }()
}

public struct OfflineConfig : Codable {
    public var accessKey: String
    public var channels: [String]
    public var prefixes: [String]

    enum CodingKeys: String, CodingKey {
        case accessKey = "accessKey"
        case channels = "channels"
        case prefixes = "prefixes"
    }
}
