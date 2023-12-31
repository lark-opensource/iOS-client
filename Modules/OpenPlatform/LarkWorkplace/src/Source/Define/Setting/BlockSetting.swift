//
//  BlockSetting.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/4/12.
//

import Foundation
import LarkSetting

/// Block 重试机制配置项
///
/// 配置地址:
/// * Feishu(https://cloud.bytedance.net/appSettings-v2/detail/config/155673/detail/basic)
/// * Lark(https://cloud.bytedance.net/appSettings-v2/detail/config/165476/detail/basic)
struct BlockRetryConfig: SettingDefaultDecodable{
    static let settingKey = UserSettingKey.make(userKeyLiteral: "workplace_block_retry_config")
    static let defaultValue = BlockRetryConfig(
        silentRetryTimes: 3,
        delayTimeStep: 500,
        loadingTimeout: 10_000,
        applyAll: true,
        availableApps: [],
        activeRetryEnable: true
    )

    /// 静默重试次数
    let silentRetryTimes: Int

    /// 每次静默重试失败后，再次重试的延迟时间增量，首次默认延迟时间为 0（单位 ms）
    let delayTimeStep: Int

    /// loading 超时时间（单位 ms）
    let loadingTimeout: Int

    /// 是否全部应用可用，false 时仅 availableApps 白名单内应用生效
    let applyAll: Bool

    /// 可用应用 appId 列表
    let availableApps: [String]

    /// 是否开启主动重试
    let activeRetryEnable: Bool
}

/// 小组件更新机制优化配置
/// 配置地址：
/// 飞书：https://cloud.bytedance.net/appSettings-v2/detail/config/165448/detail/basic
/// Lark：https://cloud.bytedance.net/appSettings-v2/detail/config/174134/detail/basic
struct BlockCheckUpdateConfig: SettingDefaultDecodable{
    static let settingKey = UserSettingKey.make(userKeyLiteral: "block_check_update_config")
    static let defaultValue = BlockCheckUpdateConfig(
        blockCheckUpdateEnable: false,
        blockCheckUpdateBlackList: []
    )

    /// 是否需要在页面show/hide时检查更新
    let blockCheckUpdateEnable: Bool

    /// 不需要检查更新的 appId 列表
    let blockCheckUpdateBlackList: [String]
}
