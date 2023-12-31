//
//  SerialStage.swift
//  Launcher
//
//  Created by nine on 2019/12/30.
//  Copyright © 2019 nine. All rights reserved.
//

import Foundation

public final class SerialStage: Stage {
    public var finishCallBack: (() -> Void)?
    public typealias T = SerialTask
    public var state: StageState = .ready
    public var identifier: String
    public var tasks: [T] = []
    public let isLeisureStage: Bool

    public func appendTask(_ tasks: T...) {
        for task in tasks {
            self.tasks.append(task)
        }
    }

    public func appendTask(name: String? = nil, taskClosure: @escaping () -> Void) {
        tasks.append(T(name: name, taskClosure: taskClosure))
    }

    public func kickoff() {
        DocsLogger.info("【DocsLauncher】SerialStage \(identifier) kickoff")
        guard state == .ready else { return }
        state = .running
        for task in tasks {
            task.main()
        }
        finishCallBack?()
        state = .done
    }

    public func shutdown() {
        state = .done
    }

    public init(identifier: String, isLeisureStage: Bool = false) {
        self.identifier = identifier
        self.isLeisureStage = isLeisureStage
    }

    public convenience init(identifier: String, tasks: LauncherTask...) {
        self.init(identifier: identifier)
    }
}

extension SerialStage: AsyncStageNode {}
