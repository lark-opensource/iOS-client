//
//  DomainSettingManager+update.swift
//  LarkSetting
//
//  Created by 王元洵 on 2021/9/23.
//

import Foundation
import RustPB
import LarkEnv

// swiftlint:disable no_space_in_method_call

public extension DomainSettingManager {
    /// 使用Rust数据更新域名配置，会同步更新内存缓存和磁盘缓存
    ///
    /// - Parameters:
    ///   - domain: Rust中的域名结构
    ///   - env: 域名对应的环境
    func update(domains: RustPB.Basic_V1_DomainSettings, envType: Env.TypeEnum, unit: String, brand: String) {
        update(
            domain: Self.toDomainSettings(domains: domains),
            envString: Env.settingDescription(type: envType, unit: unit, brand: brand)
        )
    }
}
