//
//  OPPluginStartLocationUpdateTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/20.
//

import XCTest
import LarkContainer
import LarkOpenAPIModel
import TTMicroApp
import LarkAssembler
import AppContainer
import LarkContainer
import ECOInfra
import TTMicroApp
import LarkCoreLocation
import Swinject
import OPPlugin
import OPUnitTestFoundation
@available(iOS 13.0, *)
final class OPPluginStartLocationUpdateTests: XCTestCase {
    
    let task = BDPTask()
    var testUtils = OpenPluginGadgetTestUtils()
    override func setUpWithError() throws {
        let assemblies: [LarkAssemblyInterface] = [
            OPContinueLocationTaskMockAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().generateTracing(by: testUtils.uniqueID)
        BDPTaskManager.shared().add(task, uniqueID: testUtils.uniqueID)
    }

    override func tearDownWithError() throws {
        let assemblies: [LarkAssemblyInterface] = [
            LarkCoreLocationAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().clearAllTracing()
        BDPTaskManager.shared().removeTask(with: testUtils.uniqueID)
    }
    
    func  test_starLocationUpdate_success() {
        mockContinueLocationTaskResult = .success
        let exp = XCTestExpectation(description: "startLocationUpdateV2Async")
        testUtils.asyncCall(apiName: "startLocationUpdateV2", params: [:]) { response in
            switch response {
            case .failure(let error):
                XCTFail(error.description)
            case .success(_):
                break
            case .continue(_, _):
                XCTFail("should not continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
}

