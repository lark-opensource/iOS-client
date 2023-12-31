//
//  OpenAPIErrnoTests.swift
//  LarkOpenAPIModel-Unit-Tests
//
//  Created by 王飞 on 2022/5/26.
//

import Foundation
import XCTest
@testable import LarkOpenAPIModel
class OpenAPIErrnoTests: XCTestCase {
    func testShowToastErrno() {
        let errno: OpenAPIErrnoProtocol = OpenAPILoginErrno.serverError
        XCTAssertTrue(errno.errno() == 10_00_001)
    }
    // 兼容原本的通用异常
//    func testCommonErrno() {
//        let errno = OpenAPICommonErrorCode.unknown
//        XCTAssertTrue(errno.errno() == OpenAPICommonErrorCode.unknown.rawValue)
//    }
    
    // 兼容原本的通用异常
//    func testCommonAPIError() {
//        let errno = OpenAPICommonErrorCode.unknown
//        let apiError = OpenAPIError.OpenAPIErrnoError(errno: errno, msg: nil)
//        XCTAssertTrue(apiError.errnoValue == OpenAPICommonErrorCode.unknown.rawValue)
//    }
    
//    func testAPIError() {
//        let errno: OpenAPIErrnoProtocol = OpenAPILoginErrno.serverError
//        let apiError = OpenAPIError.OpenAPIErrnoError(errno: errno)
//        XCTAssertTrue(apiError.errnoValue == 10_00_001)
//    }
}
