//
//  GadgetNavigationTask.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/19.
//

import Foundation
import LKCommonsLogging
import TTMicroApp

/// 是Push和Pop路由任务的封装
protocol GadgetNavigationTask: AnyObject {
    /// 执行任务
    /// - Parameter complete: 任务执行完的回调
    /// - Note: ⚠️注意`complete`必须在主线程执行，否则有可能引发线程访问冲突，导致crash⚠️
    ///         ⚠️任务的`execute`方法一定会在主线程执行⚠️
    func execute(complete: @escaping () -> ())

    /// 任务的唯一标识符，一般为UUID
    var taskID: String { get }

    /// 任务的名称
    var taskName: String { get }

    /// 任务是否被设置为强制无动画
    var forceNoneAnimated: Bool {set get}
}

/// 负责处理Push路由
final class GadgetPushNavigationTask: GadgetNavigationTask {
    /// 日志
    private static let logger = Logger.oplog(GadgetPushNavigationTask.self, category: "OPGadget")

    /// 需要路由的VC
    private var viewController: UIViewController & GadgetNavigationProtocol
    /// 需要在哪个Window显示
    private weak var fromWindow: UIWindow?
    /// 是否动画
    private var animated: Bool = true
    /// 路由成功的回调
    private var success: () -> ()
    /// 路由失败的回调
    private var failure: (Error) -> ()
    /// 导航处理器
    private let processor = GadgetNavigatorProcessor()

    var forceNoneAnimated: Bool

    var taskID: String

    var taskName: String {
        "GadgetPushNavigationTask"
    }
    /// 初始化任务
    /// - Parameters:
    ///   - viewController: 需要路由的VC
    ///   - fromWindow: 从哪个window显示
    ///   - animated: 是否动画
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    init(viewController: UIViewController & GadgetNavigationProtocol,
         fromWindow: UIWindow?,
         animated: Bool = true,
         success: @escaping () -> (),
         failure: @escaping (Error) -> ()) {
        self.viewController = viewController
        self.fromWindow = fromWindow
        self.animated = animated
        self.success = success
        self.failure = failure
        self.taskID = UUID().uuidString
        self.forceNoneAnimated = false
    }

    func execute(complete: @escaping () -> ()) {
        /// 由于是弱引用，因此执行任务时，需要确保对象存在
        guard let fromWindow = fromWindow else {
            let error = OPError.error(monitorCode: GDMonitorCode.gadgetNavigationException,
                                      message: "push task don't find fromWindow")
            failure(error)
            complete()
            return
        }
        /// 检查是否动画
        let animated = self.forceNoneAnimated ? false : self.animated
        let success = self.success
        let failure = self.failure
        processor.push(viewController: viewController, from: fromWindow, animated: animated, success: {
            [weak self] in
            success()
            complete()
        }, failure: {
            [weak self] in
            failure($0)
            complete()
        })
    }
    
    public func comparePushingVC(task:GadgetPushNavigationTask) -> Bool {
        return viewController === task.viewController
    }
}

/// 负责处理Pop路由
final class GadgetPopNavigationTask: GadgetNavigationTask {
    /// 日志
    private static let logger = Logger.oplog(GadgetPopNavigationTask.self, category: "OPGadget")

    /// 需要路由的VC
    private var viewController: UIViewController & GadgetNavigationProtocol
    /// 是否动画
    private var animated: Bool = true
    /// 路由成功的回调
    private var success: () -> ()
    /// 路由失败的回调
    private var failure: (Error) -> ()
    /// 导航处理器
    private let processor = GadgetNavigatorProcessor()

    var forceNoneAnimated: Bool

    var taskID: String

    var taskName: String {
        "GadgetPopNavigationTask"
    }

    /// 初始化任务
    /// - Parameters:
    ///   - viewController: 需要路由的VC
    ///   - success: 路由成功的回调
    ///   - failure: 路由失败的回调
    init(viewController: UIViewController & GadgetNavigationProtocol,
         animated: Bool = true,
         success: @escaping () -> (),
         failure: @escaping (Error) -> ()) {
        self.viewController = viewController
        self.animated = animated
        self.success = success
        self.failure = failure
        self.taskID = UUID().uuidString
        self.forceNoneAnimated = false
    }

    func execute(complete: @escaping () -> ()) {
        /// 检查是否动画
        let animated = self.forceNoneAnimated ? false : self.animated
        let success = self.success
        let failure = self.failure
        processor.pop(viewController: viewController, animated: animated, success: {
            success()
            complete()
        }, failure: {
            failure($0)
            complete()
        })
    }
}
