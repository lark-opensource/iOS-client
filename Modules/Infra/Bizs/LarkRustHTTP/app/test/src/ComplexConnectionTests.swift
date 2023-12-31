//
//  ComplexConnectionTests.swift
//  LarkRustHTTPDevEEUnitTest
//
//  Created by SolaWing on 2019/7/21.
//

import Foundation
import XCTest

class ComplexConnectionTests: URLProtocolTests {

    override var enableComplexConnect: Bool { true }
    open override class func testSelectors() -> [String]? {
        return [
            NSStringFromSelector(#selector(testGetRequest)),
            NSStringFromSelector(#selector(testOptionsRequest)),
            NSStringFromSelector(#selector(testPostRequest)),
            NSStringFromSelector(#selector(testPostRequest)),
            NSStringFromSelector(#selector(testBodyStreamWithoutContentLengthShouldnotCrash)),
            NSStringFromSelector(#selector(testHeaderRequest)),
            NSStringFromSelector(#selector(testPutPatchDeleteRequest)),
            NSStringFromSelector(#selector(testCancelRequest)),
            // 复合连接没中间进度通知，是总时间而不是无k响应时间
            // NSStringFromSelector(#selector(testUploadTask)),
            NSStringFromSelector(#selector(testUploadFile)),

            NSStringFromSelector(#selector(testDownloadTask)),
            NSStringFromSelector(#selector(testBugs)),
            NSStringFromSelector(#selector(test404Request)),
            // redirect
            NSStringFromSelector(#selector(testRedirectCodeAndMethod)),
            NSStringFromSelector(#selector(testCanControlNoRedirect)),
            NSStringFromSelector(#selector(testRedirectOfNSConnection)),
            NSStringFromSelector(#selector(testRedirectCountShouldLimited)),
            // cookie
            NSStringFromSelector(#selector(testCookieCanBeSaved)),
            NSStringFromSelector(#selector(testCookieSavePolicyCanbeControl)),
            NSStringFromSelector(#selector(testRequestWithCookie)),
            NSStringFromSelector(#selector(testRequestWithoutCookie)),
            // cache
            NSStringFromSelector(#selector(testCache)),
            // auth
            NSStringFromSelector(#selector(testBasicAuth)),
            NSStringFromSelector(#selector(testMetrics)),
            NSStringFromSelector(#selector(testRetryCount))
        ]
    }
}
