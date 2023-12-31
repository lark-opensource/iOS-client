//
//  TestPointCutProvider.swift
//  LarkPolicyEngine-Unit-Tests
//
//  Created by Wujie on 2023/5/25.
//

import Foundation
@testable import LarkPolicyEngine
import LarkSnCService
import XCTest

let entity: [String: Any?] = ["entityType": "IM_MSG_FILE",
                           "senderTenantId": 1,
                           "entityDomain": "IM",
                           "operatorTenantId": 1,
                           "chatID": nil,
                           "senderUserId": 7_073_453_706_351_476_756,
                           "operatorUid": 7_129_402_444_798_246_931,
                           "entityOperate": "IM_MSG_FILE_READ",
                           "fileKey": nil,
                           "chatType": nil,
                           "fileBizDomain": "IM"]

let validateRequest = ValidateRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                      entityJSONObject: entity as [String: Any])

let validateRequestRemote = ValidateRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ_REMOTE",
                                      entityJSONObject: entity as [String: Any])

let entityNotFastPass: [String: Any?] = ["entityType": "IM_MSG_FILE",
                           "senderTenantId": 1,
                           "entityDomain": "IM",
                           "operatorTenantId": 2,
                           "chatID": nil,
                           "senderUserId": 7_073_453_706_351_476_756,
                           "operatorUid": 7_129_402_444_798_246_931,
                           "entityOperate": "IM_MSG_FILE_READ",
                           "fileKey": nil,
                           "chatType": nil,
                           "fileBizDomain": "IM"]

let validateRequestNotFastPass = ValidateRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                      entityJSONObject: entityNotFastPass as [String: Any])

let entityFastPass: [String: Any?] = ["entityType": "IM_MSG_FILE",
                           "senderTenantId": 2,
                           "entityDomain": "IM",
                           "operatorTenantId": 2,
                           "chatID": nil,
                           "senderUserId": 7_073_453_706_351_476_756,
                           "operatorUid": 7_129_402_444_798_246_931,
                           "entityOperate": "IM_MSG_FILE_READ",
                           "fileKey": nil,
                           "chatType": nil,
                           "fileBizDomain": "IM"]

let validateRequestFastPass = ValidateRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                      entityJSONObject: entityFastPass as [String: Any])

let entityFastPassTenantIdError: [String: Any?] = ["entityType": "IM_MSG_FILE",
                           "senderTenantId": 2,
                           "entityDomain": "IM",
                           "operatorTenantId": -1,
                           "chatID": nil,
                           "senderUserId": 7_073_453_706_351_476_756,
                           "operatorUid": 7_129_402_444_798_246_931,
                           "entityOperate": "IM_MSG_FILE_READ",
                           "fileKey": nil,
                           "chatType": nil,
                           "fileBizDomain": "IM"]

let validateRequestFastPassTenantIdError = ValidateRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                      entityJSONObject: entityFastPassTenantIdError as [String: Any])

let entityFastPassObjectTenantIdError: [String: Any?] = ["entityType": "IM_MSG_FILE",
                           "senderTenantId": -1,
                           "entityDomain": "IM",
                           "operatorTenantId": 2,
                           "chatID": nil,
                           "senderUserId": 7_073_453_706_351_476_756,
                           "operatorUid": 7_129_402_444_798_246_931,
                           "entityOperate": "IM_MSG_FILE_READ",
                           "fileKey": nil,
                           "chatType": nil,
                           "fileBizDomain": "IM"]

let validateRequestFastPassObjectTenantIdError = ValidateRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                      entityJSONObject: entityFastPassObjectTenantIdError as [String: Any])

let pointCutModel: PointCutModel = PointCutModel(
    tags: ["ENTITY_DOMAIN": "IM",
           "ENTITY_OPERATE": "IM_MSG_FILE_READ"],
    contextDerivation: ["DEVICE_ID": "DEVICE_ID",
                       "WEB_DID": "WEB_DID",
                       "OPERATOR_TENANT_ID": "operatorTenantId",
                       "ENTITY_TYPE": "entityType",
                       "DEVICE_OS": "DEVICE_OS",
                       "OBJECT_TENANT_ID": "senderTenantId",
                       "USER_ID": "operatorUid",
                       "DEVICE_TERMINAL": "DEVICE_TERMINAL",
                       "TENANT_ID": "operatorTenantId",
                       "FILE_PROTECT_FILE_OP_BIZ_DOMAIN": "fileBizDomain",
                       "SOURCE_IP": "SOURCE_IP",
                       "OBJECT_USER_ID": "senderUserId"],
    fallbackStrategy: 1,
    identifier: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
    appliedPolicyTypes: [.fileProtect],
    fallbackActions: ["FALLBACK_COMMON"])

let pointCutModelNoSupportPolicy: PointCutModel = PointCutModel(
    tags: ["ENTITY_DOMAIN": "IM",
           "ENTITY_OPERATE": "IM_MSG_FILE_READ"],
    contextDerivation: ["DEVICE_ID": "DEVICE_ID",
                       "WEB_DID": "WEB_DID",
                       "OPERATOR_TENANT_ID": "operatorTenantId",
                       "ENTITY_TYPE": "entityType",
                       "DEVICE_OS": "DEVICE_OS",
                       "OBJECT_TENANT_ID": "senderTenantId",
                       "USER_ID": "operatorUid",
                       "DEVICE_TERMINAL": "DEVICE_TERMINAL",
                       "TENANT_ID": "operatorTenantId",
                       "FILE_PROTECT_FILE_OP_BIZ_DOMAIN": "fileBizDomain",
                       "SOURCE_IP": "SOURCE_IP",
                       "OBJECT_USER_ID": "senderUserId"],
    fallbackStrategy: 1,
    identifier: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
    appliedPolicyTypes: [.unknown],
    fallbackActions: ["FALLBACK_COMMON"])

let pointCutInfo: [String: PointCutModel]? = ["PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ": pointCutModel]

let pointCutInfoNoSupportPolicy: [String: PointCutModel]? = ["PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ": pointCutModelNoSupportPolicy]

class TestPointCutProvider: XCTestCase {

    let testStorage = TestStorage()
    let testStorageFailure = TestStorageFailure()
    let testHttpClient = TestHTTPClient()
    let testSettings = TestSettings()
    let testEnvironment = TestEnvironment()
    let testHTTPClientCodeNotZero = TestHTTPClientCodeNotZero()
    let testHTTPClientFailure = TestHTTPClientFailure()
    let testEnvironmentDomainFailure = TestEnvironmentDomainFailure()

    override func setUpWithError() throws {
        try super.setUpWithError()
        try? testStorage.set(pointCutInfo, forKey: "PointCutInfoCacheKey")
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testStorage.mmkv.removeAll()
    }

    func testSelectPointcutInfo() throws {
        // 切点信息正常获取
        let pointCutProvider = PointCutProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        var result = pointCutProvider.selectPointcutInfo(by: validateRequest)
        XCTAssertEqual(result?.fallbackActions, ["FALLBACK_COMMON"])

        // 切点信息为空
        testStorage.mmkv.removeAll()
        let pointCutProviderNilTest = PointCutProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        result = pointCutProviderNilTest.selectPointcutInfo(by: validateRequest)
        XCTAssertNil(result)
    }

    func testSelectDowngradeDecision() throws {
        // 正常拿到降级策略
        let pointCutProvider = PointCutProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        let result = try? pointCutProvider.selectDowngradeDecision(by: validateRequest)
        XCTAssertEqual(result?.actions[0].name, "FALLBACK_COMMON")
        XCTAssertEqual(result?.effect, .permit)
        XCTAssertEqual(result?.type, .downgrade)

        // 没有拿到降级策略
        testStorage.mmkv.removeAll()
        let pointCutProviderNilTest = PointCutProvider(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings()))
        XCTAssertThrowsError(try pointCutProviderNilTest.selectDowngradeDecision(by: validateRequest)) { error in
            let myError = error as? PolicyEngineError
            XCTAssertEqual(myError?.error.code, 205)
        }
    }

    func testFetchConfig() throws {
        // 获取信息成功
        testStorage.mmkv.removeAll()
        var pointCutProvider = PointCutProvider(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        pointCutProvider.fetchConfig()
        var expectation = XCTestExpectation(description: "fetchConfig_1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNotNil(self.testStorage.mmkv["PointCutInfoCacheKey"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // 成功但是状态码异常
        testStorage.mmkv.removeAll()
        pointCutProvider = PointCutProvider(service: TestSnCService(client: TestHTTPClientCodeNotZero(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        pointCutProvider.fetchConfig()
        expectation = XCTestExpectation(description: "fetchConfig_2")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv["PointCutInfoCacheKey"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // 获取信息失败
        testStorage.mmkv.removeAll()
        pointCutProvider = PointCutProvider(service: TestSnCService(client: TestHTTPClientFailure(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        pointCutProvider.fetchConfig()
        // 失败重试
        pointCutProvider.fetchConfig()
        expectation = XCTestExpectation(description: "fetchConfig_3")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv["PointCutInfoCacheKey"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // domain无效
        testStorage.mmkv.removeAll()
        pointCutProvider = PointCutProvider(service: TestSnCService(client: TestHTTPClientFailure(),
                                                                    storage: testStorage,
                                                                    settings: TestSettings(),
                                                                    environment: testEnvironmentDomainFailure))
        pointCutProvider.fetchConfig()
        expectation = XCTestExpectation(description: "fetchConfig_4")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv["PointCutInfoCacheKey"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // 策略引擎开关关闭
        testStorage.mmkv.removeAll()
        testSettings.setting["enable_policy_engine"] = false
        pointCutProvider = PointCutProvider(service: TestSnCService(client: TestHTTPClientFailure(), storage: testStorage, settings: testSettings, environment: testEnvironment))
        pointCutProvider.fetchConfig()
        expectation = XCTestExpectation(description: "fetchConfig_5")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv["PointCutInfoCacheKey"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        testSettings.setting["enable_policy_engine"] = true

        // 读写失败
        testStorage.mmkv.removeAll()
        pointCutProvider = PointCutProvider(service: TestSnCService(client: testHttpClient, storage: testStorageFailure, settings: testSettings, environment: testEnvironment))
        pointCutProvider.fetchConfig()
        expectation = XCTestExpectation(description: "fetchConfig_6")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv["PointCutInfoCacheKey"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

}
