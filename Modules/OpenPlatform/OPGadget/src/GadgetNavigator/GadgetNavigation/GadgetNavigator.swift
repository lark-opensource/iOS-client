//
//  GadgetNavigator.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/19.
//

import LKCommonsLogging
import UIKit
import TTMicroApp

/// 负责处理小程序的路由
public final class GadgetNavigator {

    /// 日志
    static let logger = Logger.oplog(GadgetNavigator.self, category: "OPGadget")

    /// 路由任务队列
    private let navigationTaskQueue = GadgetNavigationQueue()

    public static let shared = GadgetNavigator()

    private init() { }
    /// Pop操作
    /// - Parameters:
    ///   - viewController: 需要Pop的viewController
    ///   - complete: 路由的回调
    /// - Note: ⚠️必须在主线程调用，否则会直接路由失败⚠️
    public func pop(viewController: UIViewController & GadgetNavigationProtocol, animated: Bool, complete: ((OPError?) -> ())? = nil) {
        /// 检查是否在主线程
        guard Thread.isMainThread else {
            let errMsg = "GadgetNavigator pop in other thread: \(Thread.current.name ?? "unknown name")"
            let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException, message: errMsg)
            assertionFailure(error.description)
            complete?(error)
            return
        }
        let task = GadgetPopNavigationTask(viewController: viewController, animated: animated, success: {
            complete?(nil)
        }, failure: {
            /// 如果错误是OPError则返回
            if let error = $0 as? OPError {
                complete?(error)
            } else {
                /// 否则将错误转换为OPError
                let error = $0.newOPError(monitorCode: GDMonitorCode.gadgetNavigationException)
                complete?(error)
            }
        })
        self.navigationTaskQueue.addTask(for: task)
    }

    /// Push操作
    /// - Parameters:
    ///   - viewController: 需要Push的viewController
    ///   - window: 需要在哪个Window中显示
    ///   - animated: 是否动画
    ///   - complete: 路由的回调
    /// - Note: ⚠️必须在主线程调用，否则会直接路由失败⚠️
    public func push(viewController: UIViewController & GadgetNavigationProtocol, from window: UIWindow, animated: Bool, complete: ((OPError?) -> ())? = nil) {
        /// 检查是否在主线程
        guard Thread.isMainThread else {
            let errMsg = "GadgetNavigator push in other thread: \(Thread.current.name ?? "unknown name")"
            let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException, message: errMsg)
            assertionFailure(error.description)
            complete?(error)
            return
        }
        let task = GadgetPushNavigationTask(viewController: viewController, fromWindow: window, animated: animated, success: {
            complete?(nil)
        }, failure: {
            /// 如果错误是OPError则返回
            if let error = $0 as? OPError {
                complete?(error)
            } else {
                /// 否则将错误转换为OPError
                let error = $0.newOPError(monitorCode: GDMonitorCode.gadgetNavigationException)
                complete?(error)
            }
        })
        self.navigationTaskQueue.addTask(for: task)
    }

    /// 取消当前所有未开始的路由操作
    /// - Note: ⚠️必须在主线程调用，否则会直接操作失败⚠️
    public func cancelAllOperations() {
        /// 检查是否在主线程
        guard Thread.isMainThread else {
            let errMsg = "GadgetNavigator cancelAllOperations in other thread: \(Thread.current.name ?? "unknown name")"
            Self.logger.warn(errMsg)
            assertionFailure(errMsg)
            return
        }
        self.navigationTaskQueue.cancelAllTasks()
    }
}
