//
//  Stage.swift
//  Launcher
//
//  Created by nine on 2019/12/30.
//  Copyright © 2019 nine. All rights reserved.
//

import Foundation

public enum StageState {
    case ready
    case running
    case done
}

public protocol Stage: StageNode {
    associatedtype T: LauncherTask
    var tasks: [T] { get set }
    var state: StageState { get set }

    func kickoff()
    func shutdown()
}
