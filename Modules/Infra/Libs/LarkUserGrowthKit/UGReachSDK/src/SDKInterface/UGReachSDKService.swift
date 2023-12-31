//
//  UGReachSDK.swift
//  UGReachSDK
//
//  Created by shizhengyu on 2021/3/15.
//

import Foundation
import UGRCoreIntegration
import UGContainer

public typealias UGAsyncBizContextProvider = UGRCoreIntegration.AsyncBizContextProvider
public typealias UGSyncBizContextProvider = UGRCoreIntegration.SyncBizContextProvider
public typealias UGUserActionRuleContext = UGRCoreIntegration.UserActionRuleContext

public protocol UGReachSDKService {

    /// 获取指定的触达点位（首次获取内部会自动完成点位注册操作）
    /// - Parameters:
    ///   - reachPointId: 触达点位的id
    ///   - bizContextProvider: rp维度的业务上下文获取者（内置了`UGSyncBizContextProvider`、`UGAsyncBizContextProvider`分别针对同步和异步场景使用）
    func obtainReachPoint<T: ReachPoint>(
        reachPointId: String,
        bizContextProvider: BizContextProvider?
    ) -> T?

    /// 回收指定的触达点位
    /// - Parameters:
    ///   - reachPointId: 触达点位的id
    ///   - reachPointType: 触达点位的类型
    func recycleReachPoint(reachPointId: String, reachPointType: String)

    /// 启动触达配置
    /// 内部会拉取：
    /// 1. 一些 SDK 内部配置
    /// 2. 本地规则和触达场景的映射信息
    /// 注意：初始化内部会自动执行一次，这里如果业务需要强制更新内部配置或本地规则映射则可以在用户生命周期内显式调用
    func setup()

    /// 注册曝光场景/触达点位时额外业务上下文的获取方法
    /// 主要用于：
    /// 1. 通过 tryExpose 方法主动曝光一个场景时
    /// 2. 收到 push 后自动发起曝光时
    /// - Parameters:
    ///    - reachPointId: 触达点位的id
    ///    - bizContextProvider: 业务上下文提供者（内置了`UGSyncBizContextProvider`、`UGAsyncBizContextProvider`分别针对同步和异步场景使用）
    func register(
        with reachPointId: String,
        bizContextProvider: BizContextProvider
    )

    /// 清除曝光场景/触达点位时注入的额外业务上下文
    ///  - Parameters:
    ///    - reachPointId: 触达点位的id
    func clearBizContext(with reachPointId: String)

    /// 尝试曝光指定的触达点位，展示对应的触达物料
    /// - Parameters:
    ///    - scenarioId: 触达场景的id
    ///    - localRuleContext: 曝光所依赖的本地规则上下文，没有则传 nil
    ///    - bizContextProvider: 场景维度的业务上下文获取者（内置了`UGSyncBizContextProvider`、`UGAsyncBizContextProvider`分别针对同步和异步场景使用）
    func tryExpose(
        by scenarioId: String,
        actionRuleContext: UGUserActionRuleContext?,
        bizContextProvider: BizContextProvider?
    )

    /// 尝试曝光指定的触达点位，展示对应的触达物料
    /// 【适用于仅拉取个别 reachPoint 且无本地规则的场景】
    /// - Parameters:
    ///    - scenarioId: 触达场景的id
    ///    - specifiedReachPointIds: 指定需要曝光的 reachPointIds
    func tryExpose(
        by scenarioId: String,
        specifiedReachPointIds: [String]
    )
}
