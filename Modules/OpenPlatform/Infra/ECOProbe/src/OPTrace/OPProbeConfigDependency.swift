//
//  OPProbeConfigDependency.swift
//  ECOProbe
//
//  Created by qsc on 2021/3/31.
//

import Foundation

/// OPProbeConfigDependency: ECOProbe 模块使用的 FG\Config 能力由此提供
///
/// 默认情况下不能发起 FG / Config 的实际调用，必须在检测到 afterLoginStage 后才允许发起相关调用
/// > - 因 Probe 模块可能会在登录前被使用，此时 FG、Config 相关会依赖 Account
/// > - 若  Account 创建过程中依赖了 Probe，则会发生循环依赖会死锁，引起 app Crash
public protocol OPProbeConfigDependency: NSObjectProtocol {

    /// 添加登录后的状态标记，进入 afterLoginStage 后，才允许发起 FG/Config 相关的调用
    var isAfterLoginStage: Bool {get set}

    /// 获取 FG，实际调用应当在 isAfterLoginStage 后才被允许，在此之前请返回默认值
    func getFeatureGatingBoolValue(for key: String) -> Bool
    
    func getFeatureGatingBoolValueFastly(for key: String) -> Bool

    /// 获取 mina/settings 配置，实际调用应当在 isAfterLoginStage 后才被允许，在此之前请返回默认值
    func readMinaConfig(for key: String) -> [String: Any]
    
    /// 获取实时Setting
    func getRealTimeSetting(for key: String) -> [String: Any]?
}

