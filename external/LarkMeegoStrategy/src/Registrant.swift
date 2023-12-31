//
//  Registrant.swift
//  LarkMeegoStrategy
//
//  Created by shizhengyu on 2023/4/5.
//

import Foundation
import LarkMeegoStorage
import RxSwift

public enum ExecutorType: String {
    /// 预请求
    case preRequest
    /// 引擎预热
    case enginePreload
}

public struct ExecutorContext {
    public let url: URL
    public let larkScene: LarkScene
    public let meegoScene: MeegoScene
    public let strategy: StrategyConfig

    public init(url: URL, larkScene: LarkScene, meegoScene: MeegoScene, strategy: StrategyConfig) {
        self.url = url
        self.larkScene = larkScene
        self.meegoScene = meegoScene
        self.strategy = strategy
    }
}

public protocol Executor: Equatable {
    /// 执行者类型
    var type: ExecutorType { get }

    /// Settings 上配置的作用场景
    var scope: MeegoScene { get }

    /// 触发的任务
    func execute(with context: ExecutorContext)
}

public extension Executor {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.scope.rawValue == rhs.scope.rawValue && lhs.type.rawValue == rhs.type.rawValue
    }
}
