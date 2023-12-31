//
//  LarkLynxAssembly.swift
//  LarkLynxKit
//
//  Created by ByteDance on 2023/2/1.
//

import Foundation
import LarkAssembler
import Swinject
import BootManager
import EENavigator
import BDXServiceCenter

public final class LarkLynxAssembly: LarkAssemblyInterface {
    
    public init() {}
    
    public func registLaunch(container: Container) {
        NewBootManager.register(SetupLynxTask.self)
    }
    
    public func registRouter(container: Container) {
        Navigator.shared.registerRoute_(
            regExpPattern: "//remote_debug_lynx",
            priority: .high,
              { (req, res) in
                guard let service = BDXServiceManager.getObjectWith(BDXLynxKitProtocol.self, bizID: nil) as? BDXLynxKitProtocol else {
                    res.end(resource: nil)
                    return
                }
                let succeed = service.enableLynxDevtool(req.url, withOptions: ["App": "Lark", "AppVersion": "1.0.0"])
                res.end(resource: nil)
                return
            }
        )
    }
    
}
