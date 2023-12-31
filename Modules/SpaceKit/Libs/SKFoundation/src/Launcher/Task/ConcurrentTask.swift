//
//  ConcurrentTask.swift
//  Launcher
//
//  Created by nine on 2019/12/31.
//  Copyright © 2019 nine. All rights reserved.
//

import Foundation

class ConcurrentTask: Operation {
    private var taskClosure: () -> Void

    init(name: String? = nil, taskClosure: @escaping () -> Void) {
        self.taskClosure = taskClosure
        super.init()
        self.name = name
    }

    override func main() {
        taskClosure()
    }
}
