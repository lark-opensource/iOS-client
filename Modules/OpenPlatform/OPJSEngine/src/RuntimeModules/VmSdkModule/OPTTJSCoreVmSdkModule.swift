//
//  OPTTJSCoreVmSdkModule.swift
//  OPJSEngine
//
//  Created by bytedance on 2022/11/8.
//

import Foundation
import vmsdk
import LarkJSEngine
import LKCommonsLogging

@objc
final class OPTTJSCoreVmSdkModule: OPJSEventHandlers, LarkVmSdkJSModule {

    required init() {
        super.init(jsRuntime: nil)
    }
    
    required init(param: Any) {
        guard let param_arr = param as? [Any] else {
            Self.logger.error("OPTTJSCoreVmSdkModule param convert to array fail, init fail")
            assertionFailure("OPTTJSCoreVmSdkModule init failed! param convert to array fail")
            super.init(jsRuntime: nil)
            return
        }

        guard param_arr.count > 0 else {
            Self.logger.error("OPTTJSCoreVmSdkModule param length less than 1, init fail")
            assertionFailure("OPTTJSCoreVmSdkModule init failed! param length less than 1")
            super.init(jsRuntime: nil)
            return
        }
        super.init(jsRuntime: param_arr[0] as? GeneralJSRuntime)
    }
    
    override init(jsRuntime: GeneralJSRuntime?) {
        super.init(jsRuntime: jsRuntime)
    }
    
    @objc static var name: String {
        return "Lark_Bridge"
    }
    
    @objc static var methodLookup: [String: String] {
        return [
            "invoke": NSStringFromSelector(#selector(invoke(_:_:_:))),
            "publish": NSStringFromSelector(#selector(publish(_:_:_:))),
            "call": NSStringFromSelector(#selector(call(_:_:_:))),
            "onDocumentReady": NSStringFromSelector(#selector(onDocumentReady)),
            "setTimer": NSStringFromSelector(#selector(setTimer(_:_:_:))),
            "clearTimer": NSStringFromSelector(#selector(clearTimer(_:_:)))
        ]
    }
    
    
    func setup() {
    }
}
