//
//  OPPluginManagerAdapter+ExtensionRegister.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/8/15.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter

let getGadgetContext: (OpenAPIContext) throws -> GadgetAPIContext = { context in
    guard let gadgetContext = context.gadgetContext as? GadgetAPIContext else {
        throw OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage("gadgetContext is nil")
            .setErrno(OpenAPICommonErrno.unknown)
    }
    return gadgetContext
}

public extension OPPluginManagerAdapter {
    // MARK: block js runtime extension注入点
    func blockRegisterPoint() {
        guard apiExtensionEnable else { return }
        register(OpenAPISessionExtension.self) { _, context in
            OpenAPISessionExtensionBlockImpl(gadgetContext: try getGadgetContext(context))
        }
        register(OpenAPIGetSystemInfoExtension.self) { resolver, context in
            try OpenAPIGetSystemInfoExtensionBlockImpl(extensionResolver: resolver, context: context)
        }
        // getChatIDsByOpenChatIDs
        register(OpenAPIChatIDExtension.self) { resolver, context in
            try OpenAPIChatIDExtensionBlockImpl(extensionResolver: resolver, context: context)
        }
    }
}

@objc
final public class OPManagerAdatperOCBridge: NSObject {
    
    // MARK: 小程序 render extension注入点
    @objc public static func gadgetRenderRegisterPoint(_ pm: OPPluginManagerAdapter) {
        pm.gadgetRegister()
    }
}

extension OPPluginManagerAdapter {
    
    // MARK: 小程序js runtime extension注入点
    func gadgetRegisterPoint() {
        gadgetRegister()
    }
    
    // MARK: 小程序 seperateWorker js runtime extension注入点
    func seperateWorkerRegisterPoint() {
        gadgetRegister()
    }
    
    fileprivate func gadgetRegister() {
        guard apiExtensionEnable else { return }
        // session
        register(OpenAPISessionExtension.self) { _, context in
            OpenAPISessionExtensionGadgetImpl(gadgetContext: try getGadgetContext(context))
        }
        // getSystemInfo
        register(OpenAPIGetSystemInfoExtension.self) { resolver, context in
            try OpenAPIGetSystemInfoExtensionGadgetImpl(extensionResolver: resolver, context: context)
        }
        // showModalTipInfo
        register(OpenAPIShowModalTipInfoExtension.self) { resolver, context in
            try OpenAPIShowModalTipExtensionGadgetImpl(extensionResolver: resolver, context: context)
        }
        // getClipboardData, setClipboardData
        register(OpenAPIClipboardDataExtension.self) { resolver, context in
            try OpenAPIClipboardDataExtensionGadgetImpl(extensionResolver: resolver, context: context)
        }
        // getChatIDsByOpenChatIDs
        register(OpenAPIChatIDExtension.self) { resolver, context in
            try OpenAPIChatIDExtensionGadgetImpl(extensionResolver: resolver, context: context)
        }
    }
}
