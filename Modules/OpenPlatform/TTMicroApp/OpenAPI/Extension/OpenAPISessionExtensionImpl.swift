//
//  OpenAPISessionExtensionImpl.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/6/10.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

typealias OpenAPISessionExtensionGadgetImpl = OpenAPISessionExtensionMina
typealias OpenAPISessionExtensionBlockImpl = OpenAPISessionExtensionMina

final class OpenAPISessionExtensionMina: OpenAPIExtensionApp, OpenAPISessionExtension {
    let gadgetContext: GadgetAPIContext
    
    init(gadgetContext: GadgetAPIContext) {
        self.gadgetContext = gadgetContext
    }
    
    func session() -> String {
        getSession() ?? ""
    }
    
    func sessionHeader() -> [String: String] {
        guard let session = getSession() else {
            return [:]
        }
        return [
            SessionKey.sessionType.rawValue: SessionKey.minaSession.rawValue,
            SessionKey.sessionValue.rawValue: session
        ]
    }
    
    func getSession() -> String? {
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID),
              let session = TMASessionManager.shared()?.getSession(common.sandbox) else {
            return nil
        }
        return session
    }
}
