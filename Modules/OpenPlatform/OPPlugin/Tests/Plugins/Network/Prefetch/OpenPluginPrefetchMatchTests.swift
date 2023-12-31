//
//  OpenPluginPrefetchMatchTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by 刘焱龙 on 2023/4/3.
//

import XCTest
import TTMicroApp
import RustPB
import LarkOpenAPIModel

@available(iOS 13.0, *)
class OpenPluginPrefetchMatchTests: OpenPluginPrefetchTests {
    func test_prefetch_success_when_value_has_encoded() throws {
        let rule = try """
        {
            "page/component/index": {
                "https://open.feishu.cn": [
                    {
                        "method": "GET",
                        "header": {
                            "a": "${a}",
                            "b": "${b}"
                        }
                    }
                ]
            }
        }
        """.convertToJsonObject()

        let request = try """
        {
            "dataType": "json",
            "header":     {
                "a": "123%2F456%40",
                "b": "321%2F456%40"
            },
            "method": "GET",
            "requestTaskId": "02168018097400480f346cc917405673e9703e7b93719f0000000",
            "responseType": "text",
            "url": "https://open.feishu.cn?a=123/456@",
            "usePrefetchCache": 1
        }
        """.convertToJsonObject()

        let url = "sslocal://microapp?version=v2&app_id=cli_a24ebc88c8f9d013&ide_disable_domain_check=0&identifier=cli_a24ebc88c8f9d013&isdev=1&scene=1012&token=ODQ3ODE0OTgtYzk4OC00MjVmLTg1N2ItZjVjNTkyMDQ4NDhk&version_type=preview&start_page=page%2Fcomponent%2Findex%3Fb%3D123%252F456%2540&bdpsum=b50c0a5"
        let encodedQuerySchema = BDPSchema(url: URL(string: url), appType: .gadget)!
        encodedQuerySchema.appID = testUtils.appID
        encodedQuerySchema.startPagePath = "page/component/index"
        encodedQuerySchema.startPageQueryDictionary = ["a": "123%2F456%40", "b": "321%2F456%40"]

        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: encodedQuerySchema,
            prefetchDict: [:],
            prefetchRulesDict: rule,
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: request,
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                }, error: &prefetchError)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    /// query 乱序匹配：prefetch 的 rule 的 query 顺序和 request 的 query 顺序不一样，依旧能匹配命中
    func test_prefetch_success_with_query_out_of_order() throws {
        let prefetchRules = try """
        {
          "url": "https://open.feishu.cn?a=123/456@&b=b",
          "method": "GET",
          "header": {
            "content-type": "application/json"
          }
        }
        """.convertToJsonObject()

        let requestParams = try """
        {
            "url": "https://open.feishu.cn?b=b&a=123/456@",
            "method": "GET",
            "header":     {
                "content-type": "application/json"
            },
            "usePrefetchCache": 1
        }
        """.convertToJsonObject()

        let prefetchMatch = BDPAppPagePrefetchMatchKey(param: prefetchRules)
        let requestMatch = BDPAppPagePrefetchMatchKey(param: requestParams)
        let isPrefetch = prefetchMatch.isEqual(requestMatch)
        XCTAssertEqual(isPrefetch, true)
    }

    func test_missKey_match_success() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchema(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRulesWithMissKey(),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                }, error: &prefetchError)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func test_schemaQuery_match_success() throws {
        mockRustService.setResponses(responses: try mockPrefetchRequestSuccessResult())

        prefetcher?.prefetch(
            with: mockSchemaWithQuery(),
            prefetchDict: [:],
            prefetchRulesDict: try mockPrefetchRules(),
            backupPath: nil,
            isFromPlugin: false
        )
        sleep(1)
        do {
            var prefetchError: OPPrefetchErrnoWrapper? = nil
            prefetcher?.shouldUsePrefetchCache(
                withParam: try mockRequestparams(),
                uniqueID: testUtils.uniqueID,
                requestCompletion: { data, response, code, error in
                    XCTAssertNotNil(data)
                    XCTAssertNil(error)
                }, error: &prefetchError)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    /// Mock

    private func mockPrefetchRules() throws -> [String: Any] {
        let result = """
        {
            "page/component/index": {
                "https://open.feishu.cn?a=${a}&b=${b}": [
                    {
                        "method": "GET",
                        "header": {
                            "content-type": "application/json"
                        },
                        "hitPrefetchExtraRules": {
                            "requiredQueryKeys": ["a"],
                            "ignoreHeadersMatching": "true"
                        }
                    }
                ]
            }
        }
        """
        return try result.convertToJsonObject()
    }

    private func mockPrefetchRulesWithMissKey() throws -> [String: Any] {
        let result = """
        {
            "page/component/index": {
                "https://open.feishu.cn?a=${a}&b=${b}": [
                    {
                        "method": "GET",
                        "header": {
                            "content-type": "application/json"
                        },
                        "hitPrefetchExtraRules": {
                            "requiredQueryKeys": ["a"],
                            "ignoreHeadersMatching": "true",
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

    private func mockSchemaWithQuery() -> BDPSchema {
        let url = "sslocal://microapp?version=v2&app_id=cli_a24ebc88c8f9d013&ide_disable_domain_check=0&identifier=cli_a24ebc88c8f9d013&isdev=1&scene=1012&token=ODQ3ODE0OTgtYzk4OC00MjVmLTg1N2ItZjVjNTkyMDQ4NDhk&version_type=preview&start_page=page%2Fcomponent%2Findex%3Fb%3D123%252F456%2540&bdpsum=b50c0a5"
        let result = BDPSchema(url: URL(string: url), appType: .gadget)
        result?.appID = testUtils.appID
        result?.startPagePath = "page/component/index"
        result?.startPageQueryDictionary = ["a": "123/456@", "b": "valueB"]
        return result!
    }

    private func mockRequestparams() throws -> [String: Any] {
        let result = """
        {
            "dataType": "json",
            "header":     {
                "content-type": "application/json",
                "set-cookie": "xx=123;path=/test"
            },
            "method": "GET",
            "requestTaskId": "02168018097400480f346cc917405673e9703e7b93719f0000000",
            "responseType": "text",
            "url": "https://open.feishu.cn?a=123/456@",
            "usePrefetchCache": 1
        }
        """
        return try result.convertToJsonObject()
    }
}
