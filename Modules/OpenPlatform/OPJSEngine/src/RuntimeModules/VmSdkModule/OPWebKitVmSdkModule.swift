//
//  OPWebKitVmSdkModule.swift
//  OPJSEngine
//
//  Created by bytedance on 2022/11/8.
//

import Foundation
import vmsdk
import LarkJSEngine
import LKCommonsLogging


@objc
final class OPWebKitVmSdkModule: OPJSEventHandlers, LarkVmSdkJSModule {

    required init() {
        super.init(jsRuntime: nil)
    }
    
    required init(param: Any) {
        guard let param_arr = param as? [Any] else {
            Self.logger.error("OPWebKitVmSdkModule param convert to array fail, init fail")
            assertionFailure("OPWebKitVmSdkModule init failed! param convert to array fail")
            super.init(jsRuntime: nil)
            return
        }

        guard param_arr.count > 0 else {
            Self.logger.error("OPWebKitVmSdkModule param length less than 1, init fail")
            assertionFailure("OPWebKitVmSdkModule init fail! param length less than 1")

            super.init(jsRuntime: nil)
            return
        }
        super.init(jsRuntime: param_arr[0] as? GeneralJSRuntime)
    }
    
    override init(jsRuntime: GeneralJSRuntime?) {
        super.init(jsRuntime: jsRuntime)
    }
    
    
    @objc static var name: String {
        return "OPWebKitVmSdkModule"
    }
    
    @objc static var methodLookup: [String: String] {
        return [
            "invokeNative": NSStringFromSelector(#selector(invokeNative(dic:))),
            "publish2": NSStringFromSelector(#selector(publish(dic:)))
        ]
    }
    
    var exportProps: [String: Any] {
        return [
            "messageHandlers": [
                "invokeNative": [
                    "postMessage": NSStringFromSelector(#selector(invokeNative(dic:)))
                ],
                "publish2": [
                    "postMessage": NSStringFromSelector(#selector(publish(dic:)))
                ]
            ]
        ]
    }
    @objc override func invokeNative(dic: [String: Any]) -> Any? {
        var invokeParam: [String: Any] = dic
        var data: [AnyHashable: Any]?
        if let sourceCode = invokeParam["data"] as? [AnyHashable: Any] {
            data = decodeNativeBufferData(source: sourceCode)
            invokeParam["data"] = data
        }
        return super.invokeNative(dic: invokeParam)

    }
    
    func decodeNativeBufferData(source: [AnyHashable: Any]) -> [AnyHashable: Any] {
        if let buffers = source["__nativeBuffers__"] as? [[AnyHashable: Any]] {
            var invokeParam: [AnyHashable: Any] = source
            invokeParam.removeValue(forKey: "__nativeBuffers__")
            for buffer in buffers {
                if let bufferKey = buffer["key"] as? String, let bufferValue = buffer["value"] as? NSData {
                    invokeParam[bufferKey] = bufferValue
                }
            }
            return invokeParam
        }
        return source
    }
    func setup() {
    }
}
