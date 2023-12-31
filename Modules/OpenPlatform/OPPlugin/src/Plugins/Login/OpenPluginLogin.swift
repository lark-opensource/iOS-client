//
//  OpenPluginLogin.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/4/20.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import LarkContainer

final class OpenPluginLogin: OpenBasePlugin {

    static let kBDPSessionExpireTime = "kBDPSessionExpireTime"

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "checkSession",
                                           pluginType: Self.self) { this, _, context, gadgetContext, callback in
            this.checkSession(context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
