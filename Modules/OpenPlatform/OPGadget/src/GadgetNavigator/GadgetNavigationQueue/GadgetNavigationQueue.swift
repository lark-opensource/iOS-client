//
//  GadgetNavigationQueue.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/19.
//

import Foundation
import LKCommonsLogging
import LarkFeatureGating

/// 负责串行调度路由任务
/// - Note: 由于系统push与pop机制，在动画未完成的时候连续push/pop同一个VC会导致crash
///         为了避免连续快速的调用路由，因此这里需要使用串行队列保证时序
final class GadgetNavigationQueue {
    /// 用于保存路由任务的队列
    /// 因为考虑到性能因素，不对taskQueue进行加锁操作
    private var taskQueue: [GadgetNavigationTask] = []

    /// 日志
    static let logger = Logger.oplog(GadgetNavigationQueue.self, category: "OPGadget")

    /// 队列中最大的任务数，如果超过了最大的任务数，后续加入的任务会强制无动画
    /// 如果每个操作都进行动画，那么会让队列中的任务排很长的队
    /// 短时间来很多任务，我们可以认为中间的这些操作用户都不关心
    /// 于是我们可以将中间的这些任务全部关闭动画，快速的执行完成
    private let maxAnimationTaskNumber = 3

    /// 是否进行强制无动画
    /// ⚠️必须在主线程调用⚠️
    private var isForceNoneAnimated: Bool {
        return self.taskQueue.count > maxAnimationTaskNumber
    }

    /// 往队列中增加一个任务
    /// - Parameter task: 路由任务
    /// - Note: 需要在主线程执行
    func addTask(for task: GadgetNavigationTask) {
        /// 如果当前任务队列不空，那么我们仅加入任务队列
        if !taskQueue.isEmpty {
            if !LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.microapp.push_queue_protect") {
                if isSameVCPushTaskIn(task: task) {
                    // 已经存在push相同VC的任务，则不添加到队列中
                    Self.logger.info("prevent from pushing same VC to stack \(task.taskName)")
                } else {
                    taskQueue.append(task)
                }
            } else {
                taskQueue.append(task)
            }
        } else {
            /// 如果当前任务队列为空，那么我们不仅要加入队列，还需要启动任务
            taskQueue.append(task)
            /// 需要检查是否要执行下一个任务
            self.executeNextTaskIfNeed()
        }
    }
    
    /// 检测新的push任务是否已经存在在队列中，判断依据为将同一个VC压栈
    /// - Parameter task: 将要被添加到队列中的任务
    /// - Returns: 是否已经存在push入参
    func isSameVCPushTaskIn(task:GadgetNavigationTask) -> Bool {
        return taskQueue.first { taskInQueue in
            if let pushTaskInQueue = taskInQueue as? GadgetPushNavigationTask, let willAddPushTask = task as? GadgetPushNavigationTask {
                if pushTaskInQueue.comparePushingVC(task: willAddPushTask) {
                    return true
                }
            }
            return false
        } != nil
    }

    /// 移除任务队列中所有的任务
    /// - Note: 需要在主线程执行
    func cancelAllTasks() {
        self.taskQueue.removeAll()
    }

    /// 执行下一个任务
    /// - Note: 需要在主线程执行
    private func executeNextTaskIfNeed() {
        /// 取得这时候队首的任务，执行任务
        if let nextTask = self.taskQueue.first {
            let taskName = nextTask.taskName
            Self.logger.info("task start, name: \(taskName)")
            let taskID = nextTask.taskID
            /// 检查是否强制任务无动画
            if self.isForceNoneAnimated {
                nextTask.forceNoneAnimated = true
            }
            /// 每一个即将开始的任务都必须检查执行是否超时
            queueProtectionCheck(for: taskID)
            nextTask.execute{
                [weak self] in
                guard let `self` = self else {
                    return
                }
                /// 当此任务执行完之后，将执行完的任务移除掉，队列是从左往后执行的，因此执行完的任务一定是在队首
                /// 为了防止task的complete回调被错误的多次调用，在这里我们限制成一个task的complete只可以被执行一次
                /// 使用任务的唯一标识符来确认队首的task是不是正在执行任务的task
                /// 如果是那么我们删除它，执行下一个任务
                /// 如果不是那么表示这个任务已经被删除了，但是complete的回调却还在调用，表示内部调用了多次的complete
                /// 或者发生了队列执行超时，被强制性的移除了，这种情况极小概率的发生在页面切换时进行push/pop动画
                /// 这种时候我们什么都不做，因为无论是complete重复调用还是超时必然会触发`executeNextTaskIfNeed`的调用
                if let firstTask = self.taskQueue.first, firstTask.taskID == taskID {
                    Self.logger.info("task end, name: \(taskName)")
                    self.taskQueue.removeFirst()
                    /// 需要检查是否要执行下一个任务
                    self.executeNextTaskIfNeed()
                } else {
                    let errMsg = "navigation task complete is called repeatedly, name: \(taskName)"
                    Self.logger.error(errMsg)
                }
            }
        }
    }

    /// 检查任务是否超时
    /// - Parameter taskID: 任务ID
    private func queueProtectionCheck(for taskID: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){
            [weak self] in
            guard let `self` = self else {
                return
            }
            /// 取出队列中的第一个任务，如果当前任务还是还是之前执行的任务，那么表示此任务已经超时
            /// 我们主动移除这个任务，然后继续执行下一个任务
            /// 如果没有超时，那么我们什么都不做
            if let firstTask = self.taskQueue.first, firstTask.taskID == taskID {
                Self.logger.error("task execute timeOut!, name: \(firstTask.taskName)")
                self.taskQueue.removeFirst()
                /// 需要检查是否要执行下一个任务
                self.executeNextTaskIfNeed()
            }
        }
    }
}
