//
//  OpenPluginNetworkDownloadFileTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by 刘焱龙 on 2023/2/21.
//

import XCTest
import RustPB
import LarkRustClient
import LarkContainer
import LarkOpenAPIModel
import TTMicroApp
import OPUnitTestFoundation
@available(iOS 13.0, *)
final class OpenPluginNetworkDownloadFileTests: OpenPluginNetworkTests {
    override var configFileName: String { "downloadFile" }

    func test_downloadFile_fail_with_filePath_not_ttfile() throws {
        let payload = try getParams(key: #function)
        let params = [
            "payload" : payload
        ]
        let errResult = try getErrResult(key: #function)

        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "downloadFile", params: params) { response in
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

    func test_downloadFile_success() throws {
        let downloadFilePath = try mock_download_local_file()
        try mockRustService.setResponses(
            responses: mockSuccessResponse(key: #function,
                                           payloadCustomKey: [:],
                                           extraCustomKey: ["downloadFilePath": downloadFilePath]))
        let payload = try getParams(key: #function)
        let params = [
            "payload" : payload
        ]

        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "downloadFile", params: params) { response in
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

    func test_downloadFile_request_canceled() throws {
        mockRustService.setResponses(responses: mockFailResponse(errorCode: 301))
        let payload = try getParams(key: #function)
        let params = [
            "payload" : payload
        ]
        let errResult = try getErrResult(key: #function)

        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "downloadFile", params: params) { response in
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
extension OpenPluginNetworkDownloadFileTests {
    func mock_download_local_file() throws -> String {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_download_file.txt").path
        let isFileExist = FileManager.default.fileExists(atPath: path)
        if !isFileExist {
            FileManager.default.createFile(atPath: path, contents: try JSONSerialization.data(withJSONObject: ["test": "test"]))
        }
        return path
    }
}
