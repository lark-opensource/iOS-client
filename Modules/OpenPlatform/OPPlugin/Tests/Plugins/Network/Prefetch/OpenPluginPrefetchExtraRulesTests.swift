//
//  OpenPluginPrefetchExtraRulesTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by 刘焱龙 on 2023/4/3.
//

import XCTest
import TTMicroApp
import RustPB
import LarkOpenAPIModel

@available(iOS 13.0, *)
class OpenPluginPrefetchExtraRulesTests: OpenPluginPrefetchTests {
    func test_prefetch_fail_when_header_unmatch() throws {
        let prefetchRules = try """
        {
          "url": "https://open.feishu.cn?a=123/456@",
          "method": "GET",
          "header": {
            "content-type": "application/json"
          }
        }
        """.convertToJsonObject()

        let requestParams = try """
        {
            "url": "https://open.feishu.cn?a=123/456@",
            "method": "GET",
            "header":     {
                "content-type": "application/json",
                "set-cookie": "xx=123;path=/test"
            },
            "usePrefetchCache": 1
        }
        """.convertToJsonObject()

        let prefetchMatch = BDPAppPagePrefetchMatchKey(param: prefetchRules)
        let requestMatch = BDPAppPagePrefetchMatchKey(param: requestParams)
        let isPrefetch = prefetchMatch.isEqual(requestMatch)
        XCTAssertEqual(isPrefetch, false)
        let prefetchErrno = prefetchMatch.isEqual(to: requestMatch)
        XCTAssertEqual(prefetchErrno.errnoValue, 1605006)
    }

    func test_prefetch_success_with_ignoreHeadersMatching() throws {
        let prefetchRules = try """
        {
          "url": "https://open.feishu.cn?a=123/456@",
          "method": "GET",
          "header": {
            "content-type": "application/json",
                        "number": 123
          }
        }
        """.convertToJsonObject()

        let requestParams = try """
        {
            "url": "https://open.feishu.cn?a=123/456@",
            "method": "GET",
            "header":     {
                "content-type": "application/json",
                "set-cookie": "xx=123;path=/test"
            },
            "usePrefetchCache": 1,
            "hitPrefetchExtraRules": {
                "ignoreHeadersMatching": true
            }
        }
        """.convertToJsonObject()

        let prefetchMatch = BDPAppPagePrefetchMatchKey(param: prefetchRules)
        let requestMatch = BDPAppPagePrefetchMatchKey(param: requestParams)
        let isPrefetch = prefetchMatch.isEqual(requestMatch)
        XCTAssertEqual(isPrefetch, true)
    }

    func test_prefetch_fail_when_query_unmatch() throws {
        let prefetchRules = try """
        {
          "url": "https://open.feishu.cn?a=123/456@",
          "method": "GET",
          "header": {
            "content-type": "application/json"
          }
        }
        """.convertToJsonObject()

        let requestParams = try """
        {
            "url": "https://open.feishu.cn?a=123/456@&b=b",
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
        XCTAssertEqual(isPrefetch, false)
        let prefetchErrno = prefetchMatch.isEqual(to: requestMatch)
        XCTAssertEqual(prefetchErrno.errnoValue, 1605003)
    }

    func test_prefetch_success_with_requiredQueryKeys() throws {
        let prefetchRules = try """
        {
          "url": "https://open.feishu.cn?a=123/456@",
          "method": "GET",
          "header": {
            "content-type": "application/json"
          }
        }
        """.convertToJsonObject()

        let requestParams = try """
        {
            "url": "https://open.feishu.cn?a=123/456@&b=b",
            "method": "GET",
            "header":     {
                "content-type": "application/json"
            },
            "usePrefetchCache": 1,
            "hitPrefetchExtraRules": {
                "requiredQueryKeys": ["a"]
            }
        }
        """.convertToJsonObject()

        let prefetchMatch = BDPAppPagePrefetchMatchKey(param: prefetchRules)
        let requestMatch = BDPAppPagePrefetchMatchKey(param: requestParams)
        let isPrefetch = prefetchMatch.isEqual(requestMatch)
        XCTAssertEqual(isPrefetch, true)
    }

    func test_prefetch_success_with_requiredHeaderKeys() throws {
        let prefetchRules = try """
        {
          "url": "https://open.feishu.cn?a=123/456@",
          "method": "GET",
          "header": {
            "content-type": "application/json"
          }
        }
        """.convertToJsonObject()

        let requestParams = try """
        {
            "url": "https://open.feishu.cn?a=123/456@",
            "method": "GET",
            "header":     {
                "content-type": "application/json",
                "set-cookie": "xx=123;path=/test"
            },
            "usePrefetchCache": 1,
            "hitPrefetchExtraRules": {
                "requiredHeaderKeys": ["content-type"]
            }
        }
        """.convertToJsonObject()

        let prefetchMatch = BDPAppPagePrefetchMatchKey(param: prefetchRules)
        let requestMatch = BDPAppPagePrefetchMatchKey(param: requestParams)
        let isPrefetch = prefetchMatch.isEqual(requestMatch)
        XCTAssertEqual(isPrefetch, true)
    }
}
