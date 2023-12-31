//
//  LarkRuntimeSafeModeTask.swift
//  LarkSafeMode
//
//  Created by luyz on 2022/11/4.
//

import Foundation
import BootManager
import Heimdallr
import LarkDebugExtensionPoint
import LarkReleaseConfig
import LarkAccountInterface

public final class LarkRuntimeSafeModeTask: FlowBootTask, Identifiable {
    public static var identify = "LarkRuntimeSafeModeTask"
    public override var runOnlyOnce: Bool { return true }
    public override var deamon: Bool { true }
    private let runtimeSafeMode = LarkRuntimeSafeMode()

    public override func execute(_ context: BootContext) {
        if !LarkSafeMode.safeModeRuntimeEnable {
            return
        }
        runtimeSafeMode.registerObserve()
    }
}
