//
//  ShortcutTask.swift
//  LarkShortcut
//
//  Created by kiri on 2023/11/16.
//

import Foundation
import EEAtomic
import LKCommonsLogging
import LKCommonsTracker

final class ShortcutTask {
    let taskId: String
    let request: ShortcutRequest
    let token: String
    private let completion: (Result<ShortcutResponse, Error>) -> Void
    private let handlerFactory: (ShortcutActionContext) throws -> ShortcutHandler
    private var isFinished = false
    // scheduleQueue用来修改变量/调用runStep
    private let scheduleQueue: DispatchQueue
    // executeQueue用来执行handler/completion（含find handler）
    private let executeQueue: DispatchQueue
    private let creationTime = Date()
    private var startTime: Date?
    /// 当前执行到第几步
    private var currentStep: ShortcutTaskStep?

    /// 之前几步执行的结果
    @AtomicObject
    private(set) var actionResults: [ShortcutResponse.ActionResult] = []
    /// task维度的缓存，可在action间传递信息
    @AtomicObject
    var userInfo: [String: Any] = [:]

    init(taskId: String, request: ShortcutRequest, token: String,
         handlerFactory: @escaping (ShortcutActionContext) throws -> ShortcutHandler,
         completion: @escaping (Result<ShortcutResponse, Error>) -> Void) {
        self.taskId = taskId
        self.token = token
        self.request = request
        self.completion = completion
        self.handlerFactory = handlerFactory
        self.scheduleQueue = DispatchQueue(label: "lark.shortcut.schedule.\(taskId)")
        self.executeQueue = DispatchQueue(label: "lark.shortcut.execute.\(taskId)")
    }

    func start() {
        self.startTime = Date()
        log("start task: shortcut = \(request.shortcut.name), actionCount = \(request.shortcut.actions.count)")
        self.scheduleQueue.async { [weak self] in
            self?.next()
        }
    }

    private func reportEnded(index: Int, result: Result<Any, Error>, durationInHandler: TimeInterval? = nil) {
        guard !isFinished, let step = self.currentStep, index == step.index else { return } // already timeout or failed.
        let actionResult = ShortcutResponse.ActionResult(startTime: step.startTime, endTime: Date(), result: result)
        let duration = actionResult.duration
        self.actionResults.append(actionResult)
        var logParams: [String] = []
        if let durationInHandler {
            logParams.append("durationInHandler = \(Util.formatDuration(durationInHandler))")
        }
        logEnd("action(\(step.action.id))", duration: duration, result: result, params: logParams)

        var trackParams: [String: Any] = [
            // start_time位数多，到毫秒，报string，int可能有限制
            "start_time": Int(step.startTime.timeIntervalSince1970 * 1000).description,
            "task_id": taskId,
            "shortcut_name": request.shortcut.name,
            "action_name": step.action.id,
            "from_source": token,
            "duration": Int(duration * 1000)
        ]
        switch result {
        case .success:
            trackParams["status"] = "success"
        case .failure(let error):
            trackParams["status"] = "fail"
            trackParams["error_code"] = toErrorCode(error)
        }
        Tracker.post(TeaEvent("vc_ios_shortcut_action_status", category: "shortcut", params: trackParams))
        if self.finishIfNeeded(result) {
            return
        }
        self.next()
    }

    private func next() {
        let actions = request.shortcut.actions
        let index = (self.currentStep?.index ?? -1) + 1
        let totalCount = actions.count
        guard index < totalCount else {
            assertionFailure("ShortcutTask(\(taskId)): index(\(index)) < totalCount(\(totalCount))")
            self.finishIfNeeded(.success(Void()))
            return
        }
        let action = actions[index]
        let step = ShortcutTaskStep(index: index, action: action, startTime: Date(), isLast: index == totalCount - 1)
        self.currentStep = step
        if action.options.delay > 0 {
            self.scheduleQueue.asyncAfter(deadline: .now() + action.options.delay) { [weak self] in
                self?.runStep(step)
            }
        } else {
            self.runStep(step)
        }
    }

    private func runStep(_ step: ShortcutTaskStep) {
        log("start \(step.action)")
        self.executeQueue.async { [weak self] in
            guard let self = self else { return }
            let index = step.index
            let action = step.action
            let finishAction: (Result<Any, Error>, TimeInterval?) -> Void = { [weak self] result, duration in
                self?.scheduleQueue.async {
                    self?.reportEnded(index: index, result: result, durationInHandler: duration)
                }
            }
            do {
                let context = ShortcutActionContext(action: action, task: self)
                let handler = try self.handlerFactory(context)
                let startTime = Date.timeIntervalSinceReferenceDate
                handler.handleShortcutAction(context: context) { result in
                    finishAction(result, Date.timeIntervalSinceReferenceDate - startTime)
                }
                if action.options.timeout > 0 {
                    self.scheduleQueue.asyncAfter(deadline: .now() + action.options.timeout) { [weak self] in
                        self?.reportEnded(index: index, result: .failure(ShortcutError.timeout))
                    }
                }
            } catch {
                finishAction(.failure(error), nil)
            }
        }
    }

    @discardableResult
    private func finishIfNeeded(_ result: Result<Any, Error>) -> Bool {
        if isFinished { return true }
        guard let step = self.currentStep else {
            finish(result)
            return true
        }

        if case let .failure(error) = result {
            if !step.action.options.nextOnError || step.isLast {
                finish(.failure(error))
                return true
            }
        } else if step.isLast {
            finish(.success(Void()))
            return true
        }
        return false
    }

    private func finish(_ result: Result<Any, Error>) {
        isFinished = true
        let r0 = result.map({ _ in ShortcutResponse(request: request, actionResults: actionResults) })
        self.executeQueue.async {
            if let startTime = self.startTime {
                self.logEnd("task", duration: Date().timeIntervalSince(startTime), result: r0)
            } else {
                assertionFailure("task not started")
            }
            self.completion(r0)
        }
    }

    private func toErrorCode(_ error: Error) -> Int {
        switch error {
        case ShortcutError.handlerNotFound: return 1
        case ShortcutError.noPermission: return 2
        case ShortcutError.timeout: return 3
        case ShortcutError.invalidParameter: return 4
        default: return -1
        }
    }

    private func logEnd<T>(_ action: String, duration: TimeInterval, result: Result<T, Error>, params: [String] = [],
                           file: String = #fileID, function: String = #function, line: Int = #line) {
        let duration = Util.formatDuration(duration)
        let suffix = params.isEmpty ? "" : " , \(params.joined(separator: ", "))"
        switch result {
        case .success:
            log("\(action) success: duration = \(duration)\(suffix)", file: file, function: function, line: line)
        case .failure(let error):
            loge("\(action) failed: duration = \(duration)\(suffix), error = \(error)", file: file, function: function, line: line)
        }
    }

    private func log(_ message: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        Logger.shortcut.info("[ShortcutTask(\(taskId))] \(message)", additionalData: ["contextID": taskId], file: file, function: function, line: line)
    }

    private func loge(_ message: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        Logger.shortcut.error("[ShortcutTask(\(taskId))] \(message)", additionalData: ["contextID": taskId], file: file, function: function, line: line)
    }
}

private struct ShortcutTaskStep {
    let index: Int
    let action: ShortcutAction
    let startTime: Date
    let isLast: Bool
}
