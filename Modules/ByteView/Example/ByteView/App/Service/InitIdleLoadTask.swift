//
//  InitIdleLoadTask.swift
//  ByteView_Example
//
//  Created by fakegourmet on 2021/10/13.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import BootManager
import LKLoadable

class InitIdleLoadTask: FlowBootTask, Identifiable {

    override var runOnlyOnce: Bool { return true }

    static var identify: TaskIdentify = "IdleLoadTask"

    override func execute(_ context: BootContext) {
        LKLoadableManager.run(LKLoadable.runloopIdle)
    }
}
