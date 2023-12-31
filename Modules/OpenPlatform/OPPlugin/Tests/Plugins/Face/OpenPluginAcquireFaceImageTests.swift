//
//  OpenPluginAcquireFaceImageTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/3/24.
//

import XCTest
import OCMock
import Foundation
import LarkOpenAPIModel
import TTMicroApp
import ECOInfra
import OPPlugin
import EEMicroAppSDK
import OPUnitTestFoundation

@available(iOS 13.0, *)
final class OpenPluginAcquireFaceImageTests: XCTestCase {
    
    var testUtils = OpenPluginGadgetTestUtils()
    
    private var mockInstance: OCMockObject?
    private var mockModuleManager: OCMockObject?
 
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        mockInstance = OCMockAssistant.mock_EERoute_deleate(EERoute.shared(), delegate: nil, liveFaceDelegate: OPMockAcquireFaceImage())
        testUtils.prepareGadgetSandboxPath(pkgName: "testPkg")
        mockModuleManager = OPMockStorageModule.mockSandbox(with: testUtils.sandbox)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        mockInstance?.stopMocking()
        mockModuleManager?.stopMocking()
    }
    
    func test_acquire_face_image_success() throws {
        
        let params:[AnyHashable : Any] = [:]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "acquireFaceImage", params: params) { response in
            switch response {
            case .success(data: let result):
                guard let filePath = result?.toJSONDict()["tempFilePath"] as? String
                        else {
                    XCTFail("acquireFaceImage result exception")
                    return
                }
                do {
                    let file = try FileObject(rawValue: filePath)
                    let fsContext = FileSystem.Context(
                        uniqueId: self.testUtils.uniqueID,
                        trace: nil,
                        tag: "acquireFaceImage",
                        isAuxiliary: false
                    )
                    let fileExist = try FileSystem.fileExist(file, context: fsContext)
                    XCTAssert(fileExist, "file not exits in sandbox")
                } catch {
                    XCTFail("\(error)")
                }
                exp.fulfill()
            case .failure(error: let error):
                XCTFail(error.description)
                exp.fulfill()
            default:
                break
            }
        }
        wait(for: [exp], timeout: 10)
    }


}
