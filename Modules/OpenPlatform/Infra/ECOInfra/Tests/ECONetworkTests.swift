//
//  ECONetworkTests.swift
//  AppHost-TTMicroApp-Unit-Tests
//
//  Created by 刘焱龙 on 2023/5/4.
//

import Foundation
import XCTest
import LarkContainer
import Swinject
import LarkAssembler
import AppContainer
import SwiftyJSON
@testable import ECOInfra

class ECONetworkContext: ECONetworkServiceContext {
    func getSource() -> ECOInfra.ECONetworkRequestSourceWapper? {
        return nil
    }

    func getTrace() -> OPTrace {
        return OPTrace(traceId: "123456")
    }
}

struct ECONetworkDecodableResult: Decodable {
    let keyA: String
    let keyB: String
    let keyC: String
}

class ECONetworkTests: XCTestCase {
    @Provider var ecoService: ECONetworkService

    private static let path = "https://open.feishu.cn/open-apis/mina/getOpenDepIDsByDepIDs"

    override func setUpWithError() throws {
        let assemblies: [LarkAssemblyInterface] = [
            ECONetworkClientMockAssembly(resultMock: requestResultMock())
        ]
        assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }

    override func tearDownWithError() throws {
        let assemblies: [LarkAssemblyInterface] = [
            ECONetworkAssembly() as LarkAssemblyInterface
        ]
        assemblies.forEach { $0.registContainer(container: BootLoader.container) }
    }

    func test_common_params_when_set_content_type() throws {
        let exp = XCTestExpectation(description: "async")

        let task = ecoService.get(
            url: Self.path,
            header: ["c": "789", "Content-type": "application/octet-stream;tt-data=a"],
            params: ["b": "456"],
            context: ECONetworkContext()) { response, error in
                XCTAssertTrue(self.checkCommonParams(header: response!.request.allHTTPHeaderFields!))
                XCTAssertEqual(response?.request.value(forHTTPHeaderField: "Content-Type"), "application/octet-stream;tt-data=a")
                exp.fulfill()
            }
        ecoService.resume(task: task!)

        wait(for: [exp], timeout: 2)
    }

    func test_common_params_when_not_set_content_type() throws {
        let exp = XCTestExpectation(description: "async")

        let task = ecoService.get(
            url: Self.path,
            header: ["c": "789"],
            params: ["b": "456"],
            context: ECONetworkContext()) { response, error in
                XCTAssertTrue(self.checkCommonParams(header: response!.request.allHTTPHeaderFields!))
                XCTAssertEqual(response?.request.value(forHTTPHeaderField: "Content-Type"), "application/json")
                exp.fulfill()
            }
        ecoService.resume(task: task!)

        wait(for: [exp], timeout: 2)
    }

    func test_get() throws {
        let exp = XCTestExpectation(description: "async")

        let task = ecoService.get(
            url: Self.path,
            header: ["c": "789", "Content-type": "application/octet-stream;tt-data=a"],
            params: ["b": "456"],
            context: ECONetworkContext()) { response, error in
                XCTAssertNil(error)
                XCTAssertEqual(response?.request.url?.absoluteString, "\(Self.path)?b=456")
                XCTAssertEqual(response?.request.allHTTPHeaderFields?["c"], "789")
                XCTAssertTrue(self.checkCommonParams(header: response!.request.allHTTPHeaderFields!))
                XCTAssertEqual(response?.request.httpBody, nil)
                XCTAssertEqual(response?.request.value(forHTTPHeaderField: "Content-Type"), "application/octet-stream;tt-data=a")
                exp.fulfill()
            }
        ecoService.resume(task: task!)

        wait(for: [exp], timeout: 2)
    }

    func test_post() throws {
        let params: [String: String] = [
            "app_version": "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "")",
            "platform": "ios",
            "b": "456"
        ]
        let exp = XCTestExpectation(description: "async")

        let task = ecoService.post(
            url: Self.path,
            header: ["c": "789"],
            params: ["b": "456"],
            context: ECONetworkContext()) { response, error in
                XCTAssertNil(error)
                XCTAssertEqual(response?.request.url?.absoluteString, "\(Self.path)")
                XCTAssertEqual(response?.request.allHTTPHeaderFields?["c"], "789")
                XCTAssertTrue(self.checkCommonParams(header: response!.request.allHTTPHeaderFields!))
                XCTAssertEqual(response?.request.value(forHTTPHeaderField: "Content-Type"), "application/json")

                let jsonBody = try! JSONSerialization.jsonObject(with: response!.request.httpBody!) as? [String: String]
                XCTAssertEqual(jsonBody, params)

                exp.fulfill()
            }
        ecoService.resume(task: task!)

        wait(for: [exp], timeout: 2)
    }

    func test_get_decodable() throws {
        let exp = XCTestExpectation(description: "async")

        let task = ecoService.get(
            url: Self.path,
            header: [:],
            params: nil,
            context: ECONetworkContext()) { (response: ECONetworkResponse<ECONetworkDecodableResult>?, error) in
                XCTAssertNil(error)
                XCTAssertEqual(response?.request.url?.absoluteString, "\(Self.path)")
                XCTAssertTrue(self.checkCommonParams(header: response!.request.allHTTPHeaderFields!))
                XCTAssertEqual(response?.request.httpBody, nil)
                XCTAssertTrue(response?.result is ECONetworkDecodableResult)
                XCTAssertTrue(self.checkDecodableResult(result: response!.result!))
                exp.fulfill()
            }
        ecoService.resume(task: task!)

        wait(for: [exp], timeout: 2)
    }

    func test_post_decodable() throws {
        let exp = XCTestExpectation(description: "async")

        let task = ecoService.post(
            url: Self.path,
            header: [:],
            params: [:],
            context: ECONetworkContext()) { (response: ECONetworkResponse<ECONetworkDecodableResult>?, error) in
                XCTAssertNil(error)
                XCTAssertEqual(response?.request.url?.absoluteString, "\(Self.path)")
                XCTAssertTrue(self.checkCommonParams(header: response!.request.allHTTPHeaderFields!))
                XCTAssertTrue(response?.result is ECONetworkDecodableResult)
                XCTAssertTrue(self.checkDecodableResult(result: response!.result!))
                exp.fulfill()
            }
        ecoService.resume(task: task!)

        wait(for: [exp], timeout: 2)
    }

    func test_get_JSON() throws {
        let exp = XCTestExpectation(description: "async")

        let task = ecoService.get(
            url: Self.path,
            header: [:],
            params: nil,
            context: ECONetworkContext()) { (response: ECONetworkResponse<JSON>?, error) in
                XCTAssertNil(error)
                XCTAssertEqual(response?.request.url?.absoluteString, "\(Self.path)")
                XCTAssertTrue(self.checkCommonParams(header: response!.request.allHTTPHeaderFields!))
                XCTAssertEqual(response?.request.httpBody, nil)
                XCTAssertTrue(response?.result is JSON)
                XCTAssertTrue(self.checkJSONResult(result: response!.result!))
                exp.fulfill()
            }
        ecoService.resume(task: task!)

        wait(for: [exp], timeout: 2)
    }

    func test_post_JSON() throws {
        let exp = XCTestExpectation(description: "async")

        let task = ecoService.post(
            url: Self.path,
            header: [:],
            params: [:],
            context: ECONetworkContext()) { (response: ECONetworkResponse<JSON>?, error) in
                XCTAssertNil(error)
                XCTAssertEqual(response?.request.url?.absoluteString, "\(Self.path)")
                XCTAssertTrue(self.checkCommonParams(header: response!.request.allHTTPHeaderFields!))
                XCTAssertTrue(response?.result is JSON)
                XCTAssertTrue(self.checkJSONResult(result: response!.result!))
                exp.fulfill()
            }
        ecoService.resume(task: task!)

        wait(for: [exp], timeout: 2)
    }

    private func checkDecodableResult(result: ECONetworkDecodableResult) -> Bool {
        return result.keyA == "a" && result.keyB == "b" && result.keyC == "c"
    }

    private func checkJSONResult(result: JSON) -> Bool {
        return result["keyA"] == "a" && result["keyB"] == "b" && result["keyC"] == "c"
    }

    private func checkCommonParams(header: [String : String]) -> Bool {
        let keys = Set(header.keys)
        let commons = Set(["x-request-id-op", "x-tt-logid", "x-request-id", "called_from"])
        return commons.isSubset(of: keys)
    }

    private func requestResultMock() -> [String: String] {
        return [
            "keyA": "a",
            "keyB": "b",
            "keyC": "c"
        ]
    }
}
