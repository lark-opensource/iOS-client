//
//  OpenPluginPrefetchErrnoTest.swift
//  OPPlugin-Unit-Tests
//
//  Created by 刘焱龙 on 2023/4/3.
//

import XCTest
import TTMicroApp
import RustPB
import LarkOpenAPIModel

@available(iOS 13.0, *)
final class OpenPluginPrefetchErrnoTest: OpenPluginPrefetchTests {
    func test_errno_1605000() throws {
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTFail("should not reach")
                }, error: &prefetchError)
            XCTAssertEqual(prefetchError?.errnoValue, 1605000)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test_errno_1605001() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(url: "https://open.feishu-boe.cn?a=123/456@"),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTFail("should not reach")
                }, error: &prefetchError)
            XCTAssertEqual(prefetchError?.errnoValue, 1605001)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test_errno_1605002() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(url: "https://open.feishu.cn/123/456?a=123/456@"),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTFail("should not reach")
                }, error: &prefetchError)
            XCTAssertEqual(prefetchError?.errnoValue, 1605002)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test_errno_1605003() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(url: "https://open.feishu.cn?a=123/456@&b=test"),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTFail("should not reach")
                }, error: &prefetchError)
            XCTAssertEqual(prefetchError?.errnoValue, 1605003)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    // 这里不会出现 1605004 错误，因为目前只匹配 host、path、query，不包括 hash，hash 不同依旧能匹配成功
    // 这里先记个 test case
    func test_errno_1605004() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(url: "https://open.feishu.cn?a=123/456@#test"),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTAssertNotNil(data)
                }, error: &prefetchError)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test_errno_1605005() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(method: "POST"),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTFail("should not reach")
                }, error: &prefetchError)
            XCTAssertEqual(prefetchError?.errnoValue, 1605005)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test_errno_1605006() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(header: """
                    {
                        "content-type": "application/json",
                        "set-cookie": "xx=123;path=/test"
                    }
                """),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTFail("should not reach")
                }, error: &prefetchError)
            XCTAssertEqual(prefetchError?.errnoValue, 1605006)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test_errno_1605007() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(responseType: "test"),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTFail("should not reach")
                }, error: &prefetchError)
            XCTAssertEqual(prefetchError?.errnoValue, 1605007)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test_errno_1605008() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(method: "POST"),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(
                    method: "POST",
                    data: """
                            {
                                "type": "application/json",
                            }
                        """
                ),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTFail("should not reach")
                }, error: &prefetchError)
            XCTAssertEqual(prefetchError?.errnoValue, 1605008)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test_errno_1605009() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestFailResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(),
            backupPath: nil,
            isFromPlugin: false
        )
        // 因为 prefetch 会复用网络请求，所以 sleep 一下让 prefetch 请求结束
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTFail("should not reach")
                }, error: &prefetchError)
            XCTAssertEqual(prefetchError?.errnoValue, 1605009)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    /// Mock

    private func mockPrefetchRules(method: String = "GET") throws -> [String: Any] {
        let result = """
        {
            "page/component/index": {
                "https://open.feishu.cn?a=${a}&b=${b}": [
                    {
                        "method": "\(method)",
                        "header": {
                            "content-type": "application/json"
                        },
                        "hitPrefetchExtraRules": {
                            "missKeyConfig":{
                                "a":{
                                    "default": "123%2F456%40",
                                    "delete_miss_key": false
                                },
                                "b":{
                                    "delete_miss_key": true
                                }
                            }
                        }
                    }
                ]
            }
        }
        """
        return try result.convertToJsonObject()
    }

    private func mockSchema() -> BDPSchema {
        let url = "sslocal://microapp?version=v2&app_id=cli_a24ebc88c8f9d013&ide_disable_domain_check=0&identifier=cli_a24ebc88c8f9d013&isdev=1&scene=1012&token=ODQ3ODE0OTgtYzk4OC00MjVmLTg1N2ItZjVjNTkyMDQ4NDhk&version_type=preview&start_page=page%2Fcomponent%2Findex%3Fb%3D123%252F456%2540&bdpsum=b50c0a5"
        let result = BDPSchema(url: URL(string: url), appType: .gadget)
        result?.appID = testUtils.appID
        result?.startPagePath = "page/component/index"
        return result!
    }

    private func mockRequestparams(
        url: String = "https://open.feishu.cn?a=123/456@",
        method: String = "GET",
        header: String = """
            {
                "content-type": "application/json"
            }
        """,
        responseType: String = "text",
        data: String = """
            {
                "type": "application/json",
                "cookie": "xx=123;path=/test"
            }
        """
    ) throws -> [String: Any] {
        let result = """
        {
            "dataType": "json",
            "header": \(header),
            "method": "\(method)",
            "requestTaskId": "02168018097400480f346cc917405673e9703e7b93719f0000000",
            "responseType": "\(responseType)",
            "url": "\(url)",
            "data": \(data),
            "usePrefetchCache": 1
        }
        """
        return try result.convertToJsonObject()
    }
    
}
