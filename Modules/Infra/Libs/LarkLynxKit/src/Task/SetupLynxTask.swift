//
//  SetupLynxTask.swift
//  LarkLynxKit
//
//  Created by ByteDance on 2023/2/1.
//

import Foundation
import BootManager
import Lynx

class SetupLynxTask: FlowBootTask, Identifiable { //Global
    static var identify = "SetupLynxTask"

    override func execute(_ context: BootContext) {
        LynxEnv.sharedInstance()
        LynxComponentRegistry.registerUI(LarkLynxUIText.self, withName: LarkLynxUIText.name)
        
        #if ALPHA || DEBUG
        LarkLynxDebugger.shared.setup()
        #endif
    }
}
