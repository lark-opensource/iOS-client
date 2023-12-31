//
//  VCLarkAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkRVC
import BootManager
import LarkAssembler

final class VCLarkAssembly: LarkAssemblyInterface {

    func registLaunch(container: Container) {
        NewBootManager.register(SetupLoggerBootTask.self)
        NewBootManager.register(RVCSetupBootTask.self)
    }
}
