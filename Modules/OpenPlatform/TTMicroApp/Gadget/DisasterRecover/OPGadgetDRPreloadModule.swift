//
//  OPGadgetDRPreloadModule.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/21.
//

import Foundation


final class OPGadgetDRPreloadModule: OPGadgetDRModule {
    
    override class func getModuleName() -> String {
        return DRModuleName.PRELOAD.rawValue
    }
    
    override class func getPriority() -> DRModulePriority {
        return .preload
    }
    
    override func startDRModule(config: OPGadgetDRConfig?) {
        self.config = config
        BDPPreRunManager.sharedInstance.cleanAllCacheByDR()
        BDPJSRuntimePreloadManager.releaseAllPreloadRuntime(withReason: "DR")
        BDPAppPageFactory.releaseAllPreloadedAppPage(withReason: "DR")
        moduleDidFinished(self)
    }
    
}
