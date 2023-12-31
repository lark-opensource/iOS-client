//
//  TaskDemoViewController.swift
//  LarkOpenChatDev
//
//  Created by 李勇 on 2020/12/10.
//

import Foundation
import UIKit
import LarkOpenChat
import Swinject

class ChatContainerTask: ContainerTask {
    override class var name: String { return "ChatContainerTask" }
}

class TaskDemoViewController: UIViewController, TaskDelegate {
    private let signalTrap = SignalTrap()
    override func viewDidLoad() {
        super.viewDidLoad()
        let chatTask = ChatContainerTask(signalTrap: signalTrap)
        chatTask.delegate = self
        let aContainerTask = AContainerTask(signalTrap: signalTrap)
        do {
            aContainerTask.appendTasks(tasks: [ASubATask(signalTrap: signalTrap), ASubBTask(signalTrap: signalTrap)])
            aContainerTask.appendRelation(relations: [("ASubATask", "ASubBTask")])
        }
        let cContainerTask = CContainerTask(signalTrap: signalTrap)
        do {
            cContainerTask.appendTasks(tasks: [CSubATask(signalTrap: signalTrap), CSubBTask(signalTrap: signalTrap)])
            cContainerTask.appendRelation(relations: [("CSubATask", "CSubBTask")])
        }
        chatTask.appendTasks(tasks: [aContainerTask,
                                     BContainerTask(signalTrap: signalTrap),
                                     cContainerTask])
        chatTask.appendRelation(relations: [("AContainerTask", "BContainerTask"),
                                            ("BContainerTask", "CContainerTask")])
        chatTask.run()
    }

    func taskFinish(name: String) {

    }
}
