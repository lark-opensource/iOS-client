//
//  MonitorHelper.swift
//  LarkCore
//
//  Created by lichen on 2018/11/27.
//

import Foundation

/// Monitor 监控 task 模型
///
/// 当 task 没有 bind object, task 以 name 作为唯一标识
///
/// 当 task bind 了 object, task 以 name 和 object 作为唯一标识
/// task 的生命周期与 object 相同
/// 如果 bind object 被释放, task 则被视为无效 task
final class MonitorHelperTask: Equatable {
    public let name: String // 监控的 name
    public var bind: Bool = false // 是否 bind object
    public var extra: [String: Any] = [:] // 存储额外信息的字典
    public weak var object: NSObject? // bind 的 object

    public init(name: String) {
        self.name = name
    }

    public init(name: String, bind object: NSObject) {
        self.name = name
        self.bind = true
        self.object = object
    }

    public static func == (lhs: MonitorHelperTask, rhs: MonitorHelperTask) -> Bool {
        if lhs.bind != rhs.bind ||
            lhs.name != rhs.name ||
            lhs.object != rhs.object {
            return false
        }
        return true
    }
}

protocol MonitorHelperProtocol: AnyObject {

    var queue: DispatchQueue { get }
    var tasks: [MonitorHelperTask] { get set }

    /// 添加一个 task, 并且可以初始化一些 task 的参数, 有默认实现
    ///
    /// - Parameters:
    ///   - task: task name
    ///   - object: bind object
    ///   - updateTaskBlock: 可以配置一些初始化参数
    func start(task: String, bind object: NSObject?, updateTaskBlock: ((MonitorHelperTask) -> Void)?)

    /// 删除一个 task, 并且可以配置一些 task 参数, 有默认实现
    ///
    /// - Parameters:
    ///   - task: task name
    ///   - bind: bind object
    ///   - updateTaskBlock: 可以配置一些结果参数, 比如结束的状态等等
    func stop(task: String, bind: NSObject?, updateTaskBlock: ((MonitorHelperTask) -> Void)?)

    /// 开始一个 task, 需要被 helper 实现, 在 queue 线程被执行
    ///
    /// - Parameters:
    ///   - task: task 对象
    ///   - repetition: task 是否是被重复添加, 可以用作计数相关的 Helper
    func start(task: MonitorHelperTask, repetition: Bool)

    /// 结束一个 task, 需要被 helper 实现, 在 queue 线程被执行
    ///
    /// - Parameter task: task 对象
    func stop(task: MonitorHelperTask)
}

extension MonitorHelperProtocol {
    func start(task: String, bind object: NSObject?, updateTaskBlock: ((MonitorHelperTask) -> Void)?) {
        guard let monitorTask = self.task(name: task, object: object) else {
            return
        }
        updateTaskBlock?(monitorTask)
        self.queue.async { [weak self] in
            guard let `self` = self else { return }
            self.cleanInvalidTask()
            if let index = self.tasks.firstIndex(of: monitorTask) {
                let originTask = self.tasks[index]
                self.start(task: originTask, repetition: true)
            } else {
                self.tasks.append(monitorTask)
                self.start(task: monitorTask, repetition: false)
            }
        }
    }

    func stop(task: String, bind object: NSObject? = nil, updateTaskBlock: ((MonitorHelperTask) -> Void)?) {
        self.queue.async { [weak self] in
            guard let `self` = self else { return }
            self.cleanInvalidTask()
            if let monitorTask = self.task(name: task, object: object) {
                if let index = self.tasks.firstIndex(of: monitorTask) {
                    let removeTask = self.tasks.remove(at: index)
                    updateTaskBlock?(removeTask)
                    self.stop(task: removeTask)
                }
            }
        }
    }

    private func cleanInvalidTask() {
        self.tasks = self.tasks.filter { (task) -> Bool in
            return task.bind == false || task.object != nil
        }
    }

    private func task(name: String, object: NSObject?) -> MonitorHelperTask? {
        if name.isEmpty {
            assertionFailure()
            return nil
        }
        let monitorTask: MonitorHelperTask
        if let object = object {
            monitorTask = MonitorHelperTask(name: name, bind: object)
        } else {
            monitorTask = MonitorHelperTask(name: name)
        }
        return monitorTask
    }
}
