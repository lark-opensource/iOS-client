//
//  SetupOpenPlatformTask.swift
//  LarkOpenPlatform
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager
import LarkContainer
import RunloopTools
//import EEMicroAppSDK
import LarkOPInterface
//import AppContainer
import ECOProbe
import ECOInfra
//import LKLoadable
//import Heimdallr
//import LarkReleaseConfig
//import LarkAccountInterface
//import LKCommonsLogging
//import LarkSetting
//import LarkStorage
//import LarkUIKit
//import EcosystemWeb
//import UniversalCard

//fileprivate let log = Logger.oplog(SetupOpenPlatformTask.self, category: "SetupOpenPlatformTask")

class SetupOpenPlatformTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupOpenPlatformTask"
    
    override var scope: Set<BizScope> { return [.openplatform] }
    
    override class var compatibleMode: Bool { OPUserScope.compatibleModeEnabled }
    
    @ScopedProvider var openPlatformService: OpenPlatformService?
    
    override func execute(_ context: BootContext) {
        self.openPlatformService?.setup()
    }
}
