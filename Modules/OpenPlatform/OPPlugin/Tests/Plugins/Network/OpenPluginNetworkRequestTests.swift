//
//  OpenPluginNetworkRequestTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by 刘焱龙 on 2023/2/18.
//

import XCTest
import RustPB
import LarkRustClient
import LarkContainer
import LarkOpenAPIModel
import TTMicroApp
import OPUnitTestFoundation
@testable import OPPlugin

@available(iOS 13.0, *)
final class OpenPluginNetworkRequestTests: OpenPluginNetworkTests {
    override var configFileName: String { "requestFile" }

    func test_request_success() throws {
        mockRustService.setResponses(responses: try mockSuccessResponse(key: #function))

        let params = [
            "payload" : try getParams(key: #function)
        ]

        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "request", params: params) { response in
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

    func test_request_canceled() throws {
        mockRustService.setResponses(responses: mockFailResponse(errorCode: 301))

        let params = [
            "payload" : try getParams(key: #function)
        ]

        let errResult = try getErrResult(key: #function)

        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "request", params: params) { response in
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

    func test_request_save_cookie_success() throws {
        mockRustService.setResponses(responses: try mockSuccessResponse(key: #function))

        let params = [
            "payload" : try getParams(key: #function)
        ]

        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: "request", params: params) { [weak self] response in
            switch response {
            case .success(data: _):
                let cookies: [String] = OpenPluginNetwork.getStorageCookies(
                    cookieService: self!.cookieService,
                    from: self!.testUtils.uniqueID,
                    url: URL(string: "https://www.feishu.cn")!
                )
                var saveCookieSuccess = false
                for item in cookies {
                    if saveCookieSuccess {
                        break
                    }
                    saveCookieSuccess = item.contains(#function)
                }
                XCTAssertTrue(saveCookieSuccess)
                exp.fulfill()
            default:
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }
}
