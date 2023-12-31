//
//  ReachSDKAssembly.swift
//  UGReachSDK
//
//  Created by shizhengyu on 2021/3/15.
//

import Foundation
import AppContainer
import Swinject
import UGRCoreIntegration
import LarkAssembler

// MARK: - Assembly
public final class ReachSDKAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.inObjectScope(.userV2).register(UGReachSDKService.self) { (r) -> UGReachSDKService in
            return UGReachSDKPresenter(userResolver: r)
        }
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        CoreIntegrationAssembly()
    }
}
