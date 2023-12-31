//
//  UserPermissionUtilsTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/21.
//

import XCTest
import SKResource
@testable import SKPermission
import SKFoundation
import SwiftyJSON
import SpaceInterface

final class UserPermissionUtilsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testParseInvalidAPIResult() {
        do {
            let _: UserPermissionAPIResult<Void>? = try UserPermissionUtils.parseNoPermission(json: JSON(), permission: nil, error: nil)
            XCTFail("expect error when parse invalid json")
        } catch {
            XCTAssertTrue(DocsNetworkError.error(error, equalTo: .invalidData))
        }

        do {
            let _: UserPermissionAPIResult<Void>? = try UserPermissionUtils.parseNoPermission(json: JSON(), permission: nil, error: LoadJSONError.fileNotFound)
            XCTFail("expect error when parse invalid json")
        } catch {
            let expectError = error as? LoadJSONError
            XCTAssertNotNil(expectError)
        }
    }

    func testParseSuccessResult() {
        do {
            let json: JSON = [
                "code": 0,
                "data": [:]
            ]
            let result: UserPermissionAPIResult<Void>? = try UserPermissionUtils.parseNoPermission(json: json, permission: nil, error: nil)
            XCTAssertNil(result)
        } catch {
            XCTFail("un-expected error found: \(error)")
        }
    }

    func testOtherCodeResult() {
        let errorCode = DocsNetworkError.Code.serviceError
        // 优先抛传入的 error
        do {
            let json: JSON = [
                "code": errorCode.rawValue
            ]
            let _: UserPermissionAPIResult<Void>? = try UserPermissionUtils.parseNoPermission(json: json, permission: nil, error: LoadJSONError.fileNotFound)
            XCTFail("expect error when parse failed json")
        } catch {
            let expectError = error as? LoadJSONError
            XCTAssertNotNil(expectError)
        }

        // 其次尝试解析 code 为 DocsNetworkError.Code
        do {
            let json: JSON = [
                "code": errorCode.rawValue
            ]
            let _: UserPermissionAPIResult<Void>? = try UserPermissionUtils.parseNoPermission(json: json, permission: nil, error: nil)
            XCTFail("expect error when parse failed json")
        } catch {
            XCTAssertTrue(DocsNetworkError.error(error, equalTo: errorCode))
        }

        // 不认识的 code 用 invalidData 兜底
        do {
            let json: JSON = [
                "code": -1
            ]
            let _: UserPermissionAPIResult<Void>? = try UserPermissionUtils.parseNoPermission(json: json, permission: nil, error: nil)
            XCTFail("expect error when parse failed json")
        } catch {
            XCTAssertTrue(DocsNetworkError.error(error, equalTo: .invalidData))
        }
    }

    func testParseNoPermission() {
        // 同时有 statusCode 和 applyInfo
        do {
            let json = try Resource.loadJSON(path: Resource.JSON.UserPermission.Document.requirePassword)
            let result: UserPermissionAPIResult<Int>? = try UserPermissionUtils.parseNoPermission(json: json, permission: 5, error: nil)
            guard let result,
                  case let .noPermission(permission, statusCode, applyUserInfo) = result else {
                XCTFail("un-expected result found: \(String(describing: result))")
                return
            }
            XCTAssertEqual(permission, 5)
            XCTAssertEqual(statusCode, .passwordRequired)
            let aliasInfo = UserAliasInfo(displayName: "吴文鉴",
                                          i18nDisplayNames: [
                                            "en_us": "",
                                            "zh_cn": "",
                                            "ja_jp": ""
                                          ])
            let expectUserInfo = AuthorizedUserInfo(userID: "6916435883298160644",
                                                    userName: "吴文鉴",
                                                    i18nNames: [:],
                                                    aliasInfo: aliasInfo)
            XCTAssertEqual(applyUserInfo, expectUserInfo)
        } catch {
            XCTFail("un-expected error found: \(error)")
        }

        // 没有 applyInfo 或不能 apply
        do {
            let json = try Resource.loadJSON(path: Resource.JSON.UserPermission.Folder.requirePassword)
            let result: UserPermissionAPIResult<Void>? = try UserPermissionUtils.parseNoPermission(json: json, permission: nil, error: nil)
            guard let result,
                  case let .noPermission(_, statusCode, applyUserInfo) = result else {
                XCTFail("un-expected result found: \(String(describing: result))")
                return
            }
            XCTAssertEqual(statusCode, .passwordRequired)
            XCTAssertNil(applyUserInfo)
        } catch {
            XCTFail("un-expected error found: \(error)")
        }
    }

    func testUserPermissionResponseStatusCode() {
        typealias Code = UserPermissionResponse.StatusCode

        XCTAssertEqual(Code(rawValue: 0), .normal)
        XCTAssertEqual(Code.normal.rawValue, 0)

        XCTAssertEqual(Code(rawValue: 10009), .auditError)
        XCTAssertEqual(Code.auditError.rawValue, 10009)

        XCTAssertEqual(Code(rawValue: 10013), .reportError)
        XCTAssertEqual(Code.reportError.rawValue, 10013)

        XCTAssertEqual(Code(rawValue: 10016), .passwordRequired)
        XCTAssertEqual(Code.passwordRequired.rawValue, 10016)

        XCTAssertEqual(Code(rawValue: 10017), .wrongPassword)
        XCTAssertEqual(Code.wrongPassword.rawValue, 10017)

        XCTAssertEqual(Code(rawValue: 10018), .attemptReachLimit)
        XCTAssertEqual(Code.attemptReachLimit.rawValue, 10018)

        XCTAssertEqual(Code(rawValue: -1), .unknown(code: -1))
        XCTAssertEqual(Code.unknown(code: -1).rawValue, -1)
    }
}
