//
//  BootTaskProtocol.swift
//  BootManager
//
//  Created by sniperj on 2021/4/20.
//

import Foundation
import BootManagerConfig

//MARK: 同步任务
open class FlowBootTask: BootTask {
    internal override func _run() { runFlow() }
}

//MARK: 异步任务
public protocol AsyncBootTaskStrategy: BootTask {
    var waiteResponse: Bool { get }
}
extension AsyncBootTaskStrategy {
    /// 异步任务完成，主动调用
    public func end() {
        DispatchQueue.main.mainAsyncIfNeeded {
            guard self.waiteResponse, self.state == .await else { return }
            self.state = .end
            self.contiune()
        }
    }

    internal func runAsync() {
        self.state = .start
        self.state = .await
        self.scheduleTask()

        // 异步任务，不等Response
        if self.waiteResponse == false {
            self.state = .end
        }
    }
}

/// 异步任务，默认需要手动调用`end()`才继续后续任务
open class AsyncBootTask: BootTask, Flowable, AsyncBootTaskStrategy {
    open var waiteResponse: Bool { return true }
    public override var forbiddenPreload: Bool { return true }
    internal override func _run() { runAsync() }
}


// MARK: 分支任务
public protocol Flowable: BootTask {
    // 业务方调用，切换分支
    func flowCheckout(_ flow: FlowType)
}

public extension Flowable {
    /// 业务方调用，切换分支
    /// - Parameter stage: 目标Stage
    func flowCheckout(_ flow: FlowType) {
        DispatchQueue.main.mainAsyncIfNeeded {
            // Task开始后才能checkout
            guard self.state == .start || self.state == .await else { return }
            self.state = .checkout
            self.flow?.launcher?.executeFlow(with: flow)
        }
    }
}

// 同步checkout分支, 如果要异步checkout，使用AsyncBootTask
open class BranchBootTask: BootTask, Flowable {
    public override var forbiddenPreload: Bool { return true }
    internal override func _run() { runBranch() }
}
