//
//  ReachCoreService.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/8.
//

import Foundation
import RxSwift
import UGRule

/// 用户动作规则上下文
public struct UserActionRuleContext {
    /// 本地规则 key
    public let ruleActionKey: String
    /// 本地规则 value，仅有内容匹配时需要传入
    public let ruleActionValue: String?
    /// 对应的 SDK 元规则，不由业务决定
    public let metaRule: String

    public init(
        ruleActionKey: String,
        ruleActionValue: String? = nil,
        metaRule: String
    ) {
        self.ruleActionKey = ruleActionKey
        self.ruleActionValue = ruleActionValue
        self.metaRule = metaRule
    }
}

public protocol BizContextProvider {
    var scenarioId: String { get }
    var contextProvider: () -> Observable<[String: String]> { get }
}

/// 适用于异步获取的业务上下文提供者
public struct AsyncBizContextProvider: BizContextProvider {
    public let scenarioId: String
    public let contextProvider: () -> Observable<[String: String]>

    public init(scenarioId: String, contextProvider: @escaping () -> Observable<[String: String]>) {
        self.scenarioId = scenarioId
        self.contextProvider = contextProvider
    }
}

/// 适用于同步获取的业务上下文提供者
public struct SyncBizContextProvider: BizContextProvider {
    public let scenarioId: String
    public let contextBlock: () -> [String: String]

    public var contextProvider: () -> Observable<[String: String]> {
        return {
            return .just(contextBlock())
        }
    }

    public init(scenarioId: String, contextBlock: @escaping () -> [String: String]) {
        self.scenarioId = scenarioId
        self.contextBlock = contextBlock
    }
}

/// 向统一接入层公开的核心接口
/// 参见 https://bytedance.feishu.cn/docs/doccnixGcY0B7hlGm3EGCDentJf
public protocol ReachCoreService: AnyObject {
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
    ///    - bizContextProvider: rp维度的业务上下文获取者（内置了`SyncBizContextProvider`、`AsyncBizContextProvider`分别针对同步和异步场景使用）
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
    ///    - bizContextProvider: 场景维度的业务上下文获取者（内置了`SyncBizContextProvider`、`AsyncBizContextProvider`分别针对同步和异步场景使用）
    func tryExpose(
        by scenarioId: String,
        actionRuleContext: UserActionRuleContext?,
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

    /// 尝试重放一个触达点位的曝光数据，将暂存区的物料数据发送到对应的触达点位
    /// - Parameters:
    ///    - reachPointId: 触达点位的id
    func tryReplay(with reachPointId: String)

    /// 读取当前场景或全局是否存在互斥的触达点位
    /// - Parameters:
    ///    - scenarioId: 触达场景的id
    func isAnyExclusiveReachPoint(only scenarioId: String?) -> Bool
}
