//
//  RunLoopDispatchBridge.swift
//  LarkCrashSanitizer
//
//  Created by sniperj on 2020/7/6.
//

import Foundation
import RunloopTools

public final class RunLoopDispatchBridage: NSObject {
    @objc
    public static func doTaskInApplicationDidFinishLaunch(_ task: @escaping () -> Void) {
        RunloopDispatcher.shared.addTask(scope: .container) {
            task()
        }
    }
}
