//
//  StrategyTrigger.swift
//  ByteView
//
//  Created by wulv on 2022/8/2.
//

import Foundation

/// 策略触发器(频控+自定义锁定）
class StrategyTrigger<T> {
    private let debugOn: Bool = false
    typealias ExcuteAction = (T) -> Void
    private let excuteAction: ExcuteAction
    @RwAtomic private var lastWorkItem: DispatchWorkItem?
    private let actionQueue: DispatchQueue
    private let lockQueue: DispatchQueue
    private var locked: Bool = false // 为了外部调用的lock/unlock能配对
    private var frequencyBlocked: Bool = false // 用于dealloc时判断是否suspend
    private let frequencyTime: DispatchTimeInterval
    private let id: String
    init(with frequencyTime: DispatchTimeInterval = .milliseconds(500), id: String, action: @escaping ExcuteAction) {
        self.frequencyTime = frequencyTime
        self.excuteAction = action
        self.actionQueue = DispatchQueue(label: "byteview.strategyTrigger.action_\(id)")
        self.lockQueue = DispatchQueue(label: "byteview.strategyTrigger.lock_\(id)")
        self.id = id
        debugLog("init qId: \(id)")
    }

    deinit {
        lastWorkItem?.cancel()
        if locked || frequencyBlocked {
            // dealloc时如果有任务suspend，会crash
            actionQueue.resume()
        }
        debugLog("deinit qId: \(id)")
    }

    /// 频控
    private func frequencyBlock() {
        lockQueue.async { [weak self] in
            guard let self = self, !self.frequencyBlocked else { return }
            self.frequencyBlocked = true
            self.actionQueue.suspend()
            self.debugLog("suspend, qId: \(self.id), time: \(Date().timeIntervalSince1970)")
            self.lockQueue.asyncAfter(deadline: .now() + self.frequencyTime) { [weak self] in
                self?.frequencyBlocked = false
                self?.actionQueue.resume()
                self?.debugLog("resume, qId: \(self?.id ?? ""), time: \(Date().timeIntervalSince1970)")
            }
        }
    }
}

// MARK: - Public
extension StrategyTrigger {

    func lock() {
        debugLog("lock, qId: \(id), time: \(Date().timeIntervalSince1970)")
        lockQueue.async { [weak self] in
            guard let self = self, !self.locked else { return }
            self.locked = true
            self.actionQueue.suspend()
        }
    }

    func unlock() {
        debugLog("unlock, qId: \(id), time: \(Date().timeIntervalSince1970)")
        lockQueue.async { [weak self] in
            guard let self = self, self.locked else { return }
            self.locked = false
            self.actionQueue.resume()
        }
    }

    func excute(_ param: T, file: String = #fileID, function: String = #function, line: Int = #line) {
        let paramId = random()
        debugLog("excute, qId: \(id), time: \(Date().timeIntervalSince1970), paramId: \(paramId), file: \(file), func: \(function), line: \(line)")
        let item = DispatchWorkItem { [weak self] in
            self?.lastWorkItem = nil
            self?.excuteAction(param)
            self?.debugLog("perform, qId: \(self?.id ?? ""), time: \(Date().timeIntervalSince1970), paramId: \(paramId), file: \(file), func: \(function), line: \(line)")
            self?.frequencyBlock()
        }
        lastWorkItem?.cancel()
        lastWorkItem = item
        actionQueue.async {
            item.perform()
        }
    }
}

extension StrategyTrigger {
    func debugLog(_ s: String) {
        guard debugOn else { return }
        Logger.participant.info(s)
    }

    func random() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...4).map { _ in letters.randomElement()! })
    }
}
