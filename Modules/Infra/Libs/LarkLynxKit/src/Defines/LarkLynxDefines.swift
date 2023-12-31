//
//  LarkLynxDefines.swift
//  LarkLynxKit
//
//  Created by ByteDance on 2023/3/20.
//

import Foundation

struct LarkLynxDefines {
    //monitor
    static public let containerLifecycleEvent = "lark_lynx_kit_container_lifecycle"
    static public let methodInvokeEvent = "lark_lynx_method_invoke"
    static public let lynxContainerDomain = "lynx_container_load"
    static public let methodInvokeDomain = "lynx_method_invoke"
    static public let traceId = "trace_id"
    static public let containerType = "container_type"
    static public let methodName = "method_name"
    static public let timingType = "timing_type"
    static public let timing = "timing"
    static public let errorCode = "error_code"
    static public let errorMsg = "error_msg"
    
    //log
    static public let larkLynxKit = "larkLynxKit"
    
    //const
    static public let defaultModuleName = "BDLynxAPIModule"
    static public let defaultFunName = "trigger"
}

public struct JSModuleEntity {
    public let jsModuleName: String
    public let functionName: String
    
    public init(jsModuleName: String, functionName: String) {
        self.jsModuleName = jsModuleName
        self.functionName = functionName
    }
}
