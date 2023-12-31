//
//  OPMockCookieService.swift
//  OPPlugin-Unit-Tests
//
//  Created by 刘焱龙 on 2023/2/19.
//

import Foundation
import LarkAssembler
import Swinject
import RustPB
import ECOInfra
import OPFoundation
final class OpenPluginMockCookieAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Swinject.Container) {
        container.register(ECOCookieDependency.self) { resolver -> ECOCookieDependency in
            return OPMockCookieService(resolver: resolver)
        }.inObjectScope(.container)
    }
}

final class OpenPluginCookieRestoreAssembly: LarkAssemblyInterface {
    static var originCookieDependency: ECOCookieDependency?

    public init() {}

    public func registContainer(container: Swinject.Container) {
        container.register(ECOCookieDependency.self) { resolver -> ECOCookieDependency in
            return Self.originCookieDependency ?? OPMockCookieService(resolver: resolver)
        }.inObjectScope(.container)
    }
}

final class OPMockCookieService: ECOCookieDependency {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    var requestCookieURLWhiteListForWebview: [String] {
        return []
    }

    var userId: String {
        return "123456"
    }

    func setGadgetId(_ gadgetId: GadgetCookieIdentifier, for monitor: ECOProbe.OPMonitor) -> ECOProbe.OPMonitor {
        if let uniqueId = gadgetId as? OPAppUniqueID {
            return monitor.setUniqueID(uniqueId)
        } else {
            return monitor
        }
    }
}
