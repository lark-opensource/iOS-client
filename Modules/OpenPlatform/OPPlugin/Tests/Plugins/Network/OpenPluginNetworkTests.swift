//
//  OpenPluginNetworkTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/8.
//

import XCTest
import Swinject
import LarkAssembler
import AppContainer
import ECOInfra
import LarkContainer
import LarkRustClient
import RustPB
import TTMicroApp
import OPUnitTestFoundation
@available(iOS 13.0, *)
class OpenPluginNetworkTests: XCTestCase, OpenPluginUnitTestsConfig {
    private let task = BDPTask()

    @Provider var rustService: RustService
    @Provider var cookieService: ECOCookieService
    var testUtils = OpenPluginGadgetTestUtils()

    @Provider var originCookieDependency: ECOCookieDependency

    var config: [AnyHashable : Any]?
    var configFileName: String { "" }

    override func setUpWithError() throws {
        if (OpenPluginCookieRestoreAssembly.originCookieDependency == nil) {
            OpenPluginCookieRestoreAssembly.originCookieDependency = originCookieDependency
        }
        // 替换RustClient实现者
        let assemblies: [LarkAssemblyInterface] = [
            OpenPluginRustMockAssembly(),
            OpenPluginMockCookieAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().generateTracing(by: testUtils.uniqueID)
        BDPTaskManager.shared().add(task, uniqueID: testUtils.uniqueID)
        config = try loadConfig()
    }

    override func tearDownWithError() throws {
        // 恢复RustClient
        let assemblies: [LarkAssemblyInterface] = [
            OpenPluginRustRestoreAssembly(),
            OpenPluginCookieRestoreAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().clearAllTracing()
        BDPTaskManager.shared().removeTask(with: testUtils.uniqueID)
        config = nil
    }

    var mockRustService: OPMockRustService {
        return rustService as! OPMockRustService
    }
}
