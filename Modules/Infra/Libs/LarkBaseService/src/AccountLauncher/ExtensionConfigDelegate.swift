//
//  ExtensionConfigDelegate.swift
//  LarkAccount
//
//  Created by liuwanlin on 2018/11/25.
//

import Foundation
import Swinject
import LarkAccountInterface
import LarkExtensionCommon

public final class ExtensionConfigDelegate: LauncherDelegate, PassportDelegate {
    public let name: String = "Extension"

    private let resolver: Resolver

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    func updateShareExtension() {
        ShareExtensionConfig.share.isLarkLogin = true
    }

    public func afterLogout(_ context: LauncherContext) {
        ShareExtensionConfig.share.isLarkLogin = false
    }

    public func userDidOffline(state: PassportState) {
        ShareExtensionConfig.share.isLarkLogin = false
    }
}
