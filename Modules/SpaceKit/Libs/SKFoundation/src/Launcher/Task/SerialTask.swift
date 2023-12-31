//
//  SerialTask.swift
//  Launcher
//
//  Created by nine on 2019/12/30.
//  Copyright © 2019 nine. All rights reserved.
//

import Foundation

public final class SerialTask: LauncherTask {
    public var name: String?
    private var taskClosure: () -> Void

    public init(name: String? = nil, taskClosure: @escaping () -> Void) {
        self.name = name
        self.taskClosure = taskClosure
    }

    public func main() {
        taskClosure()
    }
}
