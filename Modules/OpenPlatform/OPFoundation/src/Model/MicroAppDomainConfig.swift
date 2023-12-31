//
//  DomainConfig.swift
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/9/27.
//

import Foundation
import RustPB
import LarkAppConfig
import LarkContainer

public typealias DomainSettings = RustPB.Basic_V1_DomainSettings

@objcMembers
public final class MicroAppDomainConfig: NSObject {
    public let openMinaDomain: String   // 老的域名集合，建议不再新增接口（staging: mina-staging.bytedance.net）
    public let configDomain: String
    public let pstatpDomain: String
    public let vodDomain: String
    public let snssdkDomain: String
    public let referDomain: String
    public let appLinkDomain: String
    public let openDomain: String   // 新的标准 open 域名集，与 openMinaDomain 的区别在于 staging 环境的域名不同 （staging: open.feishu-staging.cn）
    public let openAppInterface: String
    public let openPkm: String   //包管理相关域名key，包管理相关接口的域名建议都转移到这个Key下

    public init(settings: [InitSettingKey: [String]]) {
        self.openMinaDomain = settings[.openAppFeed]?.first ?? ""   // 历史遗留问题，这个早起各种环境域名未完全对齐，有点混乱，后续新加接口建议使用 标准open
        self.configDomain = settings[.mpConfig]?.first ?? ""
        self.pstatpDomain = settings[.ttCdn]?.first ?? ""
        self.vodDomain = settings[.vod]?.first ?? ""
        self.snssdkDomain = settings[.mpTt]?.first ?? ""
        self.referDomain = settings[.mpRefer]?.first ?? ""
        self.appLinkDomain = settings[.mpApplink]?.first ?? ""
        self.openDomain = settings[.open]?.first ?? ""
        self.openAppInterface = settings[.openAppInterface]?.first ?? ""
        self.openPkm = settings[.openPkm]?.first ?? ""
    }
    
    public static func getDomainWithoutLogin() -> MicroAppDomainConfig {
        let appConfiguration = Injected<AppConfiguration>().wrappedValue
        return MicroAppDomainConfig(settings: appConfiguration.settings)
    }
}
