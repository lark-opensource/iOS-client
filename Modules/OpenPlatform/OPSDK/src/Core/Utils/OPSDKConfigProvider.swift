//
//  OPSDKConfigProvider.swift
//  OPSDK
//
//  Created by 尹清正 on 2021/2/18.
//

import Foundation
import OPFoundation

/// OPSDK中需要依赖外部的一些配置能力，在这里进行生命，由外部进行主动注入
@objcMembers public final class OPSDKConfigProvider: NSObject {
    
    /// 是否开启新版调试功能的统一判断
    @objc public static var isOPDebugAvailableBlock: (()->Bool)?
    static var isOPDebugAvailable: Bool {
        isOPDebugAvailableBlock?() ?? false
    }

    /// 获取下发的远端配置
    public static var configProvider: ((String) -> [AnyHashable: Any]?)?

    /// 容器错误恢复配置字典
    static var recoveryConfig: [AnyHashable: Any]? {
        let appearanceConfig: [AnyHashable: Any]? = configProvider?("appearanceConfig")
        return appearanceConfig.parseValue(key: "recovery")
    }

    /// 获取本地存储对象(主要是统一实现)
    public static var kvStorageProvider: ((OPAppType) -> TMAKVStorage?)?

    /// 获取新产品化止血处理对象
    public static var silenceUpdater: ((OPAppType) -> OPPackageSilenceUpdateProtocol?)?
}

/// 从字典中取指定类型数据的便捷方法
fileprivate extension Swift.Optional where Wrapped == Dictionary<AnyHashable, Any> {

    func parseValue<Result>(key: AnyHashable, defaultValue: Result) -> Result {
        return (self?[key] as? Result) ?? defaultValue
    }

    func parseValue<Result>(key: AnyHashable) -> Result? {
        return (self?[key] as? Result)
    }

}
