//
//  SerialStage.swift
//  Launcher
//
//  Created by nine on 2019/12/30.
//  Copyright © 2019 nine. All rights reserved.
// swiftlint:disable

import Foundation

public final class ConcurrentStage: Stage {
    public var finishCallBack: (() -> Void)?
    public typealias T = Operation
    public var state: StageState = .ready
    public var identifier: String
    public let isLeisureStage: Bool
    public var tasks: [T] = []
    lazy var operationQueue: OperationQueue = {
        let op = OperationQueue()
        op.maxConcurrentOperationCount = 4
        return op
    }()

    public func appendTask(_ tasks: T...) {
        for task in tasks {
            self.tasks.append(task)
        }
    }

    public func appendTask(name: String? = nil, taskClosure: @escaping () -> Void) {
        tasks.append(ConcurrentTask(name: name, taskClosure: taskClosure))
    }

    public func kickoff() {
        DocsLogger.info("【DocsLauncher】ConcurrentStage \(identifier) kickoff")
        state = .running
        let finishTask = ConcurrentTask {
            self.state = .done
            self.finishCallBack?()
        }
        for task in tasks {
            guard !task.isFinished else { continue }
            finishTask.addDependency(task)
            operationQueue.addOperation(task)
        }
        operationQueue.addOperation(finishTask)
    }

    public func shutdown() {
        operationQueue.cancelAllOperations()
        state = .done
    }

    public init(identifier: String, isLeisureStage: Bool = false) {
        self.identifier = identifier
        self.isLeisureStage = isLeisureStage
    }
}

extension ConcurrentStage: AsyncStageNode {}
