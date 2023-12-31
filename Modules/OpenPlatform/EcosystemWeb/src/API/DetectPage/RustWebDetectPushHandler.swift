//
//  RustWebDetectPushHandler.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2022/10/25.
//

import Foundation
import AppContainer
import LarkContainer
import LarkRustClient
import RustPB
import RxSwift
import LKCommonsLogging

struct DetectPageNetConfig: PushMessage, Hashable {
    public let useVpn: Bool
    public let useProxy: Bool
    
    init(useVpn: Bool, useProxy: Bool) {
        self.useVpn = useVpn
        self.useProxy = useProxy
    }
}

final class RustWebDetectPushHandler: BaseRustPushHandler<RustPB.Tool_V1_PushNetInterfaceConfigV2> {// user:global
    private static let logger = Logger.log(RustWebDetectPushHandler.self, category: "RustWebDetectPushHandler")
    
    private let resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }
    
    override func doProcessing(message: Tool_V1_PushNetInterfaceConfigV2) {
        Self.logger.info("detect page rust push privateNet: \(message.useVpn), proxy: \(message.useProxy)")
        let message = DetectPageNetConfig(useVpn: message.useVpn, useProxy: message.useProxy)
        try? resolver.userPushCenter.post(message, replay: true)
    }
}
