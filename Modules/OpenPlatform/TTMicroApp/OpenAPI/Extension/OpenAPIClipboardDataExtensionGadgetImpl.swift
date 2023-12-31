//
//  OpenAPIClipboardDataExtensionGadgetImpl.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/8/15.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

final class OpenAPIClipboardDataExtensionGadgetImpl: OpenAPIClipboardDataExtension, OpenAPIExtensionApp {
    let gadgetContext: GadgetAPIContext
    
    required init(extensionResolver: ExtensionResolver, context: OpenAPIContext) throws {
        self.gadgetContext = try getGadgetContext(context)
        try super.init(extensionResolver: extensionResolver, context: context)
    }
    
    override func preCheck() -> OpenAPIError? {
        guard let common = BDPCommonManager.shared()?.getCommonWith(gadgetContext.uniqueID) else {
            return OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
        }
        guard common.isReady, common.isActive else {
            return OpenAPIError(code: OpenAPISetClipboardDataErrorCode.inovkeInBackground)
                .setErrno(OpenAPIClipboardErrno.invokeInBackground)
        }
        return nil
    }
    
    override var alertWhiteListKey: String {
        uniqueID.appID
    }
}
