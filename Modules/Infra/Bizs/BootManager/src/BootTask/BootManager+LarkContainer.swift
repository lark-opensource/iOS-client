//
//  BootManager+LarkContainer.swift
//  BootManager
//
//  Created by SolaWing on 2022/8/15.
//

import Foundation
import LarkContainer

extension BootContext {
    func getUserResolver(compatible: Bool = false, resolver: Resolver = Container.shared) throws -> UserResolver {
        return try resolver.getUserResolver(userID: currentUserID, compatibleMode: compatible)
    }
}

/// 用户态BootTask基类，应该使用具体的子类
/// userID应该使用userResolver上固定不变的(BootContext上的环境可能改变)
open class UserBootTask: BootTask, UserResolverWrapper {
    /// 覆盖可以指定是否对userResolver启用兼容模式, 比如可以用FG控制
    open class var compatibleMode: Bool { false }
    public let userResolver: UserResolver
    public let context: BootContext
    public init(context: BootContext, resolver: UserResolver) throws {
        self.context = context
        self.userResolver = resolver
    }
    public required convenience init(context: BootContext) throws {
        let compatibleMode = Self.compatibleMode
        try self.init(context: context, resolver: Container.shared.getUserResolver(
            userID: context.currentUserID, compatibleMode: compatibleMode))
    }
    required public convenience init() {
        fatalError("init() has not been implemented")
    }
    open override func execute(_ context: BootContext) {
        do {
            try execute()
        } catch {
            NewBootManager.logger.warn("\(self.identify) run with error:", error: error)
        }
    }
    // 子类可以换成override这个方法, 统一处理用户错误.
    // context和resolver可以从自身实例上获取
    open func execute() throws {
        fatalError("should override by subclass")
    }
}

/// 用户空间的同步task
open class UserFlowBootTask: UserBootTask {
    internal override func _run() { runFlow() }
}

/**
 用户空间的
 1 .首屏Tab对应的数据预加载
 2. 非首屏情况下会被丢弃
 业务要在ViewDidLoad里面拉数据
 */
open class UserFirstTabPreloadBootTask: UserFlowBootTask {
    open override var scheduler: Scheduler { return .concurrent }
    override var isFirstTabPreLoad: Bool { return true }
}

/// 用户空间的异步任务，默认需要手动调用`end()`才继续后续任务
open class UserAsyncBootTask: UserBootTask, Flowable, AsyncBootTaskStrategy {
    public var waiteResponse: Bool { return true }
    public override var forbiddenPreload: Bool { return true }
    internal override func _run() { runAsync() }
}

// 用户空间的 同步checkout分支流程, 如果要异步checkout，使用UserAsyncBootTask
open class UserBranchBootTask: UserBootTask, Flowable {
    internal override func _run() { runBranch() }
}
