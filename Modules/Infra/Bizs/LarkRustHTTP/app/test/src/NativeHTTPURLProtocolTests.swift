//
//  NativeHTTPURLProtocolTests.swift
//  LarkRustHTTPDevEEUnitTest
//
//  Created by SolaWing on 2019/7/22.
//

import Foundation
import XCTest
import HTTProtocol

class NativeHTTPURLProtocolTests: URLProtocolTests {
    override class var registerProtocolClass: URLProtocol.Type? {
        return NativeHTTProtocol.self
    }
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
            // URLSession也失败，是因为要堆积一定data才回调？
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
            // FIXME: 日志输出会影响保存的结果，是因为保存得慢？
            NSStringFromSelector(#selector(testCache)),
            // auth
            NSStringFromSelector(#selector(testBasicAuth))
            // NSStringFromSelector(#selector(testMetrics)),
            // NSStringFromSelector(#selector(testRetryCount)),
        ]
    }
}
