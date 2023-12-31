//
//  SettingDatasource.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/7/8.
//

/// SettingService 主要功能是向setting数据源获取数据，并解除依赖
import Foundation
import RustPB
import LarkEnv
import LarkContainer

protocol SettingDatasource: AnyObject {
    func refetchSingleSetting(with id: String, and key: String)
    func fetchSetting(resolver: UserResolver)
    func fetchCommonSetting(envV2: Basic_V1_InitSDKRequest.EnvV2)
}
