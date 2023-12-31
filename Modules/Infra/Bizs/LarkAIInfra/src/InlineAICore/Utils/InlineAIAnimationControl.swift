//
//  InlineAIAnimationControl.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/23.
//  


import UIKit

/// 主线程动画队列管理
class InlineAIAnimationControl {
    enum Timing {
        case now
        case async
        case delay(DispatchTime)
    }
    class Task {
        var completion: (() -> Void)
        var fulfilClosure: (() -> Void)?
        var timing: Timing
        init(timing: InlineAIAnimationControl.Timing, completion: @escaping (() -> Void)) {
            self.completion = completion
            self.timing = timing
        }
        
        func perform() {
            LarkInlineAILogger.info("[ai queue] perform timing:\(timing) ready")
            switch timing {
            case .now:
                run()
            case .async:
                DispatchQueue.main.async { [weak self] in
                    self?.run()
                }
            case let .delay(deadline):
                DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
                    self?.run()
                }
            }
        }
        
        private func run() {
            completion()
            LarkInlineAILogger.info("[ai queue] perform timing:\(timing) end")
            fulfilClosure?()
        }
    }
    var tasks: [Task] = []

    func perform(with timing: Timing, completion: @escaping (() -> Void)) {
        assert(Thread.current.isMainThread)
        let task = Task(timing: timing, completion: completion)
        task.fulfilClosure = { [weak self]  in
            // 移除已经处理完的
            self?.removeFirstTask()
            // 下个任务开始
            if let next = self?.removeFirstTask() {
                // 处理队列下个任务
                next.perform()
            } else {
                LarkInlineAILogger.info("[ai queue] queue clear")
            }
        }
        if !tasks.isEmpty {
            // 稍后执行
            tasks.append(task)
            LarkInlineAILogger.info("[ai queue] suspend node")
        } else {
            // 立即执行
            tasks.append(task)
            task.perform()
        }
    }

    @discardableResult
    private func removeFirstTask() -> Task? {
        guard !tasks.isEmpty else { return nil }
        return tasks.removeFirst()
    }
    
}


class InlineAIDampingControl {
    
    static func dampingFunction(current: CGFloat, max: CGFloat, delayDistance: CGFloat = 60) -> CGFloat {
        guard current > 0, current <= max else {
            return current
        }
        // 剩余距离 / 总距离
        var ratio = 1 - current / max
        // ratio范围为0 ~ 1
        let currentDelayDistance = ratio * delayDistance
        return current + currentDelayDistance
    }
}
