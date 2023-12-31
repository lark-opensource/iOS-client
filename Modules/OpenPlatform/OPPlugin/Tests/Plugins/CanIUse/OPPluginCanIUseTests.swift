//
//  OPPluginCanIUseTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/10/8.
//

import XCTest

import LarkOpenAPIModel
import LarkOpenPluginManager
import OPUnitTestFoundation
import OPFoundation
import ECOInfra

import Swinject
import LarkAssembler
import AppContainer

@testable import OPPlugin
@testable import OPPluginManagerAdapter
@testable import TTMicroApp

@available(iOS 13.0, *)
final class MockBDPAppPageProtocol: NSObject, BDPAppPageProtocol {}

@available(iOS 13.0, *)
final class OPPluginCanIUseTests: GadgetAPIXCTestCase {
    
    let apiName = "canIUse"
    
    private let task = BDPTask()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        BDPTracingManager.sharedInstance().generateTracing(by: testUtils.uniqueID)
        BDPTaskManager.shared().add(task, uniqueID: testUtils.uniqueID)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        BDPTracingManager.sharedInstance().clearAllTracing()
        BDPTaskManager.shared().removeTask(with: testUtils.uniqueID)
    }
    
    func test_api_success() throws {
        // 注入uniqueID到task
        let appPage = BDPAppPage(frame: .zero, delegate: MockBDPAppPageProtocol(), enableSchemeHandler: false)
        appPage.setupWebView(with: testUtils.uniqueID)
        success_async_api_test(apiName: apiName, params: ["schema": "isRenderInSameLayer.input"])
    }
}
