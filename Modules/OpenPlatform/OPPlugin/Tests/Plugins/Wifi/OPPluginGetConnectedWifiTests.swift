//
//  OPPluginGetConnectedWifiTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/20.
//

import XCTest
import Foundation
import LarkContainer
import LarkOpenAPIModel
import LarkOpenPluginManager
import TTMicroApp
import LarkAssembler
import AppContainer
import LarkContainer
import ECOInfra
import LarkCoreLocation
import Swinject
import OPPlugin
import OPUnitTestFoundation

@testable import OPPlugin
@testable import OPPluginManagerAdapter

@available(iOS 15.0, *)
class OPPluginGetConnectedWifiTests: XCTestCase {
    private let task = BDPTask()
    var testUtils = OpenPluginGadgetTestUtils()
    override func setUpWithError() throws {
        try super.setUpWithError()
        let assemblies: [LarkAssemblyInterface] = [
            OPMockLocationAuthorizationAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().generateTracing(by: testUtils.uniqueID)
        BDPTaskManager.shared().add(task, uniqueID: testUtils.uniqueID)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let assemblies: [LarkAssemblyInterface] = [
            LarkCoreLocationAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().clearAllTracing()
        BDPTaskManager.shared().removeTask(with: testUtils.uniqueID)
    }
    
    func test_getConnectedWifi_success() {
        let mockBSSID = "bc:d0:74:a8:ad:1f"
        let mockSSID = "123"
        let _ = OCMockAssistant.mock_NEHotspotNetwork_fetch_bssid("bc:d0:74:a8:ad:1f", ssid: "123") as AnyObject
        let exp = XCTestExpectation(description: "getConnectedWifi2Async")
        testUtils.asyncCall(apiName: "getConnectedWifi", params: [:]) { result in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            case .success(let data):
                let bssid = data?.toJSONDict()["BSSID"] as? String
                let ssid = data?.toJSONDict()["SSID"] as? String
                XCTAssertEqual(bssid, mockBSSID)
                XCTAssertEqual(ssid, mockSSID)
            case .continue( _, _):
                XCTFail("should not be continue!")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
        
    }
    
    func test_getConnectedWifi_formatBssid() {
        let mockBSSID = "bc:d:74:a8:ad:1f"
        let resultBSSID = "bc:0d:74:a8:ad:1f"
        let mockSSID = "123"
    
        let _ = OCMockAssistant.mock_NEHotspotNetwork_fetch_bssid(mockBSSID, ssid: "123") as AnyObject
        let exp = XCTestExpectation(description: "getConnectedWifi2Async")
        testUtils.asyncCall(apiName: "getConnectedWifi", params: [:]) { result in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            case .success(let data):
                let bssid = data?.toJSONDict()["BSSID"] as? String
                let ssid = data?.toJSONDict()["SSID"] as? String
                XCTAssertEqual(bssid, resultBSSID)
                XCTAssertEqual(ssid, mockSSID)
            case .continue( _, _):
                XCTFail("should not be continue!")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
        
    }
}


@available(iOS 15.0, *)
class OPPluginGetConnectedWifiExtensionTests: OPPluginGetConnectedWifiTests {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        APIExtensionFGHelper.enableExtension()
        testUtils.pluginManager.register(OpenAPIWifiExtension.self) { resolver, context in
            try OpenAPIWifiExtensionAppImpl(extensionResolver: resolver, context: context)
        }
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        APIExtensionFGHelper.disableExtension()
    }
    
    override func test_getConnectedWifi_success() {
        super.test_getConnectedWifi_success()
    }
}
