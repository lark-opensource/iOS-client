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

let testFastPassConfig: [String: [String]] = ["FILE_PROTECT": ["1",
                                                          "999",
                                                          "667788"]]

class TestFastPassInfoProvider: XCTestCase {

    let testStorage = TestStorage()
    let testStorageFailure = TestStorageFailure()
    let testHttpClient = TestHTTPClient()
    let testSettings = TestSettings()
    let testEnvironment = TestEnvironment()
    let testHTTPClientCodeNotZero = TestHTTPClientCodeNotZero()
    let testHTTPClientFailure = TestHTTPClientFailure()
    let testEnvironmentDomainFailure = TestEnvironmentDomainFailure()

    override func setUpWithError() throws {
        try? testStorage.set(testFastPassConfig, forKey: "FastPassConfigCacheKey")
        try? super.setUpWithError()
    }

    override func tearDownWithError() throws {
        testStorage.mmkv.removeAll()
        try? super.tearDownWithError()
    }

    func testCheckTenantHasPolicy() throws {
        // 租户配置策略
        let fastPassInfoProvider = FastPassInfoProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        let result = try fastPassInfoProvider.checkTenantHasPolicy(tenantID: "1", policyType: .fileProtect)
        XCTAssertTrue(result)

        // 租户没有配置策略
        let fastPassInfoProviderNoPolicy = FastPassInfoProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        let resultNoPolicy = try fastPassInfoProviderNoPolicy.checkTenantHasPolicy(tenantID: "2", policyType: .fileProtect)
        XCTAssertFalse(resultNoPolicy)

        // 快速剪枝信息中没有该策略类型
        XCTAssertThrowsError(try fastPassInfoProvider.checkTenantHasPolicy(tenantID: "1", policyType: .unknown)) { error in
            let myError = error as? PolicyEngineError
            XCTAssertEqual(myError?.error.code, 206)
        }

        // 快速剪枝信息为空
        testStorage.mmkv.removeAll()
        let fastPassInfoProviderNilTest = FastPassInfoProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        XCTAssertThrowsError(try fastPassInfoProviderNilTest.checkTenantHasPolicy(tenantID: "1", policyType: .fileProtect)) { error in
            let myError = error as? PolicyEngineError
            XCTAssertEqual(myError?.error.code, 206)
        }
    }

    func testTenantHasDeployPolicyInner() throws {
        // 租户ID为空
        let fastPassInfoProvider = FastPassInfoProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        var result = fastPassInfoProvider.tenantHasDeployPolicyInner(tenantId: nil)
        XCTAssertTrue(result)

        // 租户ID异常
        result = fastPassInfoProvider.tenantHasDeployPolicyInner(tenantId: "-1")
        XCTAssertTrue(result)

        // 租户列表包含当前租户
        result = fastPassInfoProvider.tenantHasDeployPolicyInner(tenantId: "1")
        XCTAssertTrue(result)

        // 租户列表不包含当前租户
        result = fastPassInfoProvider.tenantHasDeployPolicyInner(tenantId: "11")
        XCTAssertFalse(result)

        // 快速剪枝信息为nil
        testStorage.mmkv.removeAll()
        let fastPassInfoProviderNilTest = FastPassInfoProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        result = fastPassInfoProviderNilTest.tenantHasDeployPolicyInner(tenantId: "11")
        XCTAssertTrue(result)
    }

    func testFetchConfig() throws {
        // 获取信息成功
        testStorage.mmkv.removeAll()
        var fastPassInfoProvider = FastPassInfoProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings, environment: TestEnvironment()))
        fastPassInfoProvider.fetchConfig()
        XCTAssertNotNil(testStorage.mmkv["FastPassConfigCacheKey"])

        // 成功但是状态码异常
        testStorage.mmkv.removeAll()
        fastPassInfoProvider = FastPassInfoProvider(service: TestSnCService(client: TestHTTPClientCodeNotZero(),
                                                                            storage: testStorage,
                                                                            settings: TestSettings(),
                                                                            environment: TestEnvironment()))
        fastPassInfoProvider.fetchConfig()
        XCTAssertNil(testStorage.mmkv["FastPassConfigCacheKey"])

        // 获取信息失败
        testStorage.mmkv.removeAll()
        fastPassInfoProvider = FastPassInfoProvider(service: TestSnCService(client: TestHTTPClientFailure(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        fastPassInfoProvider.fetchConfig()
        // 失败重试
        fastPassInfoProvider.fetchConfig()
        XCTAssertNil(testStorage.mmkv["FastPassConfigCacheKey"])

        // domain无效
        testStorage.mmkv.removeAll()
        fastPassInfoProvider = FastPassInfoProvider(service: TestSnCService(client: TestHTTPClientFailure(),
                                                                    storage: testStorage,
                                                                    settings: TestSettings(),
                                                                    environment: testEnvironmentDomainFailure))
        fastPassInfoProvider.fetchConfig()
        XCTAssertNil(testStorage.mmkv["FastPassConfigCacheKey"])

        // 策略引擎开关关闭
        testStorage.mmkv.removeAll()
        testSettings.setting["enable_policy_engine"] = false
        fastPassInfoProvider = FastPassInfoProvider(service: TestSnCService(client: TestHTTPClientFailure(), storage: testStorage, settings: testSettings, environment: testEnvironment))
        fastPassInfoProvider.fetchConfig()
        XCTAssertNil(testStorage.mmkv["FastPassConfigCacheKey"])
        testSettings.setting["enable_policy_engine"] = true

        // 读写失败
        testStorage.mmkv.removeAll()
        fastPassInfoProvider = FastPassInfoProvider(service: TestSnCService(client: testHttpClient, storage: testStorageFailure, settings: testSettings, environment: testEnvironment))
        fastPassInfoProvider.fetchConfig()
        XCTAssertNil(testStorage.mmkv["FastPassConfigCacheKey"])
    }

}
