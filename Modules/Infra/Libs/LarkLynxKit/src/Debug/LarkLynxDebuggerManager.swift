//
//  LarkLynxDebugger.swift
//  LarkLynxKit
//
//  Created by ByteDance on 2023/2/15.
//

import Foundation
import Lynx
import LarkDebug
import BDXServiceCenter
import LKCommonsLogging
import BDXBridgeKit

final public class LarkLynxDebugger: NSObject, BDXLynxDevtoolProtocol {
    static let logger = Logger.oplog(LarkLynxDebugger.self, category: "LarkLynxDebugger")
    
    public static let shared = LarkLynxDebugger()
    public var debugUrl: String?
    
    public func setup() {
        guard let service = BDXServiceManager.getObjectWith(BDXLynxKitProtocol.self, bizID: nil) as? BDXLynxKitProtocol,
            let loader = BDXServiceManager.getObjectWith(BDXResourceLoaderProtocol.self, bizID: nil) as? BDXResourceLoaderProtocol else {
            Self.logger.error("bullet init failed, get service failed")
            return
        }
        
        service.addDevtoolDelegate(self)
        service.initLynxKit()
    }
    
    public func openDevtoolCard(_ urlStr: String) -> Bool {
        guard let service = BDXServiceManager.getObjectWith(BDXRouterProtocol.self, bizID: nil) as? BDXRouterProtocol else {
            return false
        }
        let context = BDXContext()
        service.open(withUrl: urlStr, context: context, completion: nil)
        self.debugUrl = urlStr
        return true
    }
}


