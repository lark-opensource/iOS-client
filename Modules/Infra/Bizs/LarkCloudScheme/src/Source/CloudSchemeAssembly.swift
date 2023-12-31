//
//  CloudSchemeAssembly.swift
//  LarkCloudScheme
//
//  Created by 王元洵 on 2022/2/11.
//

import Foundation
import LarkAssembler
import EENavigator
import Swinject

public final class CloudSchemeAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRouter(container: Container) { assembleRouter() }

    private func assembleRouter() -> Router {
        Navigator.shared.registerRoute_(match: { url in
            CloudSchemeManager.shared.canOpen(url: url)
        }, priority: .low, { req, res in
            CloudSchemeManager.shared.open(req.url)
            res.end(resource: EmptyResource())
        })
    }
}
