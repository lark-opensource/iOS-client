//
//  DomainConfig.swift
//  SKInfra
//
//  Created by huangzhikai on 2023/4/13.
//  从DomainConfig+base迁移

import Foundation
import LarkAccountInterface
import SKFoundation
import LarkContainer

public struct DomainConfig {
    public struct EnvInfo {
        //包维度
        public let package: String
        public let isFeishuPackage: Bool
        //租户品牌维度
        public let brand: TenantBrand
        public let isFeishuBrand: Bool
        //用户数据维度
        public let geo: String
        public let isChinaMainland: Bool
        public init(package: String, isFeishuPackage: Bool, brand: TenantBrand, isFeishuBrand: Bool, geo: String, isChinaMainland: Bool) {
            self.package = package
            self.isFeishuPackage = isFeishuPackage
            self.brand = brand
            self.isFeishuBrand = isFeishuBrand
            self.geo = geo
            self.isChinaMainland = isChinaMainland
        }
    }
    
    /// 环境信息
    public private(set) static var envInfo: DomainConfig.EnvInfo = {
        //默认值
        return DomainConfig.EnvInfo(package: "", isFeishuPackage: true, brand: .feishu, isFeishuBrand: true, geo: "", isChinaMainland: true)
    }()

    public static func updateEnvInfo(_ envInfo: DomainConfig.EnvInfo) {
        self.envInfo = envInfo
    }
}
