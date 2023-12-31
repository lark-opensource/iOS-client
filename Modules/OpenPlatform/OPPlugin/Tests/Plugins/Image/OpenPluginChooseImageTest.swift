//
//  OpenPluginChooseImageTest.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/6/8.
//

import XCTest
import OCMock
import OPUnitTestFoundation
@testable import OPPlugin

@available(iOS 13.0, *)
final class OpenPluginChooseImageTest: XCTestCase {

    private var testUtils = OpenPluginGadgetTestUtils()
    private var chooseImageTestInstance: OCMockObject?
    private var mockModuleManager: OCMockObject?
    
    override func setUpWithError() throws {
        chooseImageTestInstance = OCMockAssistant.mock_BDPPluginImageCustomImpl()
        testUtils.prepareGadgetSandboxPath(pkgName: "testPkg")
        mockModuleManager = OPMockStorageModule.mockSandbox(with: testUtils.sandbox)
    }

    override func tearDownWithError() throws {
        chooseImageTestInstance?.stopMocking()
        mockModuleManager?.stopMocking()
    }
    
    func test_chooseImage_success() throws {
        let params:[AnyHashable : Any] = [:]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "chooseImage", params: params) { response in
            switch response {
            case .success(_):
                exp.fulfill()
            case .failure(error: let error):
                XCTFail(error.description)
                exp.fulfill()
            default:
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }
}
