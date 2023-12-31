//
//  Launcher.swift
//  DocsSDK
//
//  Created by weidong fu on 2019/3/7.
//

import Foundation

typealias Task = () -> Void
class LaunchTask {
    let identifier: String
    let kickoff: Task
    init(identifier: String, kickoff: @escaping Task) {
        self.identifier = identifier
        self.kickoff = kickoff
    }
}

class Launcher {
    var tasks: [LaunchTask] = []
    var asyncTasks: [LaunchTask] = []

    func appendTask(_ task: LaunchTask) {
        tasks.append(task)
    }

    func appendAsyncTask(_ task: LaunchTask) {
        asyncTasks.append(task)
    }

    func kickoff() {
        tasks.forEach { (task) in
            if let launchType = MailLaunchStatService.LaunchActionType.init(rawValue: task.identifier) {
                MailLaunchStatService.default.markActionStart(type: launchType)
            }
            task.kickoff()
            if let launchType = MailLaunchStatService.LaunchActionType.init(rawValue: task.identifier) {
                MailLaunchStatService.default.markActionEnd(type: launchType)
            }
        }
        tasks.removeAll()

        DispatchQueue.global(qos: .userInitiated).async {
            self.asyncTasks.forEach { (task) in
                task.kickoff()
            }
            self.asyncTasks.removeAll()
        }
    }
}
