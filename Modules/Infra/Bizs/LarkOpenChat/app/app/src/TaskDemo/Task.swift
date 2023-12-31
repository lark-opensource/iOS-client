//
//  Task.swift
//  LarkOpenChatDev
//
//  Created by 李勇 on 2020/12/11.
//

import Foundation
import LarkOpenChat

class AContainerTask: ContainerTask {
    override class var name: String { return "AContainerTask" }
}
class ASubATask: Task {
    override class var name: String { return "ASubATask" }
    override func run() {
        super.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.end()
        }
    }
}
class ASubBTask: Task {
    override class var name: String { return "ASubBTask" }
    override func run() {
        super.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.end()
        }
    }
}

class BContainerTask: ContainerTask {
    override class var name: String { return "BContainerTask" }
}

class CContainerTask: ContainerTask {
    override class var name: String { return "CContainerTask" }
}
class CSubATask: Task {
    override class var name: String { return "CSubATask" }
    override func run() {
        super.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.end()
        }
    }
}
class CSubBTask: Task {
    override class var name: String { return "CSubBTask" }
    override func run() {
        super.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.end()
        }
    }
}
