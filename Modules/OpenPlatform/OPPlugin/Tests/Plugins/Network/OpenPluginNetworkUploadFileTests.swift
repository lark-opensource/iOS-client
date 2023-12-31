//
//  OpenPluginNetworkUploadFileTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by 刘焱龙 on 2023/2/22.
//

import XCTest
import OCMock
import RustPB
import LarkRustClient
import LarkContainer
import LarkOpenAPIModel
import TTMicroApp
import OPUnitTestFoundation
@available(iOS 13.0, *)
final class OpenPluginNetworkUploadFileTests: OpenPluginNetworkTests {
    override var configFileName: String { "uploadFile" }
    
    private var chooseImageTestInstance: OCMockObject?
    private var mockModuleManager: OCMockObject?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // mock小程序本地包路径和tmp路径
        testUtils.prepareGadgetSandboxPath(pkgName: "testPkg")
        mockModuleManager = OPMockStorageModule.mockSandbox(with: testUtils.sandbox)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        mockModuleManager?.stopMocking()
    }

    func test_fail_when_filePath_not_exist() throws {
        let payload = try getParams(key: #function)
        let params = [
            "payload" : payload
        ]
        let errResult = try getErrResult(key: #function)

        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "uploadFile", params: params) { response in
            switch response {
            case .failure(error: let error):
                XCTAssertEqual(error.errnoError?.errnoValue, errResult.errno)
                XCTAssertEqual(error.errnoError?.errString, errResult.errString)
                exp.fulfill()
            default:
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }

    func test_fail_when_filePath_not_tempFile_or_userFile() throws {
        let payload = try getParams(key: #function)
        let params = [
            "payload" : payload
        ]
        let errResult = try getErrResult(key: #function)


        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "uploadFile", params: params) { response in
            switch response {
            case .failure(error: let error):
                XCTAssertEqual(error.errnoError?.errnoValue, errResult.errno)
                XCTAssertEqual(error.errnoError?.errString, errResult.errString)
                exp.fulfill()
            default:
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }


    func test_success() throws {
        let filePath = try mock_local_file()
        try mockRustService.setResponses(responses: mockSuccessResponse(key: #function))

        let payload = try getParams(key: #function, customKey: ["filePath": filePath])
        let params = [
            "payload" : payload
        ]

        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "uploadFile", params: params) { response in
            switch response {
            case .success(data: _):
                exp.fulfill()
            case .failure(error: let error):
                XCTFail(error.description)
            default:
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }

    func test_fail_when_canceled() throws {
        let filePath = try mock_local_file()
        mockRustService.setResponses(responses: mockFailResponse(errorCode: 301))
        let errResult = try getErrResult(key: #function)

        let payload = try getParams(key: #function, customKey: ["filePath": filePath])
        let params = [
            "payload" : payload
        ]

        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "uploadFile", params: params) { response in
            switch response {
            case .failure(error: let error):
                XCTAssertEqual(error.errnoError?.errnoValue, errResult.errno)
                exp.fulfill()
            default:
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }
}

@available(iOS 13.0, *)
extension OpenPluginNetworkUploadFileTests {
    func mock_local_file() throws -> String {
        let source = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_upload_file.txt").path
        let isFileExist = FileManager.default.fileExists(atPath: source)
        if !isFileExist {
            FileManager.default.createFile(atPath: source, contents: try JSONSerialization.data(withJSONObject: ["test": "test"]))
        }

        let context = FileSystem.Context(
            uniqueId: testUtils.uniqueID,
            trace: nil,
            tag: "tt.uploadFile",
            isAuxiliary: false
        )
        let destFileObj = FileObject.generateSpecificTTFile(type: .temp, pathComponment: "test_upload_file")
        let fileExist = try FileSystem.fileExist(destFileObj, context: context)
        if fileExist { return destFileObj.rawValue }
        try FileSystemCompatible.moveSystemFile(source, to: destFileObj, context: context)
        return destFileObj.rawValue
    }
}
