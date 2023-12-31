//
//  OPPluginConfigGetEnvVariableTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/20.
//

import XCTest
import Foundation
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
import OPUnitTestFoundation
import OPPlugin
import OCMock
@available(iOS 13.0, *)
class OPPluginConfigGetEnvVariableTests: XCTestCase {
    private let task = BDPTask()
    var testUtils = OpenPluginGadgetTestUtils()
    override func setUpWithError() throws {

        BDPTracingManager.sharedInstance().generateTracing(by: testUtils.uniqueID)
        BDPTaskManager.shared().add(task, uniqueID: testUtils.uniqueID)
    }

    override func tearDownWithError() throws {
    
        BDPTracingManager.sharedInstance().clearAllTracing()
        BDPTaskManager.shared().removeTask(with: testUtils.uniqueID)
    }
    
    func test_getEnvVariable_success() {
        let exp = XCTestExpectation(description: "getEnvVariable2Async")
        var mockInstance: AnyObject? = OCMockAssistant.mockEMARequestUtil_fetchEnvVariable(byUniqueIDCompletion_mockResult: ["1":"1"], mockError: nil) as AnyObject
        testUtils.asyncCall(apiName: "getEnvVariable", params: [:]) { result in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            case .success(let data):
                if let data = data,
                   let config = data.toJSONDict()["config"] as? [AnyHashable: Any],
                   let value = config["1"] as? String,
                   value == "1" {
                } else {
                    XCTFail("\(data?.toJSONDict())")
                }
            case .continue( _, _):
                XCTFail("should not be continue!")
            @unknown default:
                XCTFail("should not be default!")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        mockInstance = nil

    }

   
}
