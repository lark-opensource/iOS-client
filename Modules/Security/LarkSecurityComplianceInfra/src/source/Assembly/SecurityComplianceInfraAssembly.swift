//
//  SecurityComplianceInfraAssembly.swift
//  LarkSecurityComplianceInfra
//
//  Created by qingchun on 2022/10/27.
//

import Foundation
import LarkAssembler
import LarkContainer
import Swinject

public final class SecurityComplianceInfraAssembly: LarkAssemblyInterface {

    public init() { }

    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)
        // setting配置
        userContainer.register(Settings.self) { resolver in
            return SettingsImp.settings(resolver: resolver)
        }
        // 新 setting 配置
        userContainer.register(SCSettingService.self) { resolver in
            SCSettingsIMP(resolver: resolver)
        }
        userContainer.register(SCRealTimeSettingService.self) { resolver in
            SCRealTimeSettingIMP(resolver: resolver)
        }
        // 新 FG 配置
        userContainer.register(SCFGService.self) { resolver in
            try SCFeatureGatingIMP(resolver: resolver)
        }
        // 网络请求
        // Global
        container.register(HTTPClient.self) { _ in
            return HTTPClientImp()
        }
    }
}
