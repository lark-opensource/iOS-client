//
//  ConsoleLogVmsdkModule.swift
//  OPJSEngine
//
//  Created by bytedance on 2022/11/21.
//

import Foundation
import vmsdk
import LarkJSEngine
import LKCommonsLogging

#if DEBUG
@objc
final class ConsoleLogVmsdkModule: NSObject, LarkVmSdkJSModule {
    static let logger = Logger.log(ConsoleLogVmsdkModule.self, category: "ConsoleLogVmsdkModule")
    required override init() {
        super.init()
    }
    
    required init(param: Any) {
        super.init()
    }
    
    
    @objc static var name: String {
        return "VMLog"
    }
    
    @objc static var methodLookup: [String: String] {
        return [
            "log": NSStringFromSelector(#selector(log(message:)))
        ]
    }
    
    @objc func log(message: String) -> Any? {
        Self.logger.info(message)
    }
    
    func setup() {
    }
}

#endif
