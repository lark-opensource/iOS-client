//
//  OPMockStorageModule.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/4/25.
//

import Foundation
import OCMock
import OPFoundation
import OPUnitTestFoundation

final class OPMockStorageModule {
    
    class func mockSandbox(with sandboxEntity: BDPSandboxProtocol? = nil) -> OCMockObject? {
        let moduleManager = BDPModuleManager(of: .gadget)
        if let storageModule = moduleManager.resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModule {
            return OCMockAssistant.mock_BDPStorageModule(storageModule, sandboxBlk: { uniqueID in
                return sandboxEntity ?? BDPSandboxEntity(uniqueID: uniqueID, pkgName: "testPkg")
            })
        }
        return nil
    }
}
