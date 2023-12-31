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

let policyEntityInfoCacheKey = "PolicyEntityCacheKey"
let testRequestKey: String = "{\"entity\":{\"entityType\":\"IM_MSG_FILE\",\"senderTenantId\":1," +
"\"entityDomain\":\"IM\",\"operatorTenantId\":1," +
"\"chatID\":null,\"senderUserId\":7023590783160680468,\"operatorUid\":7129402444798246931," +
"\"entityOperate\":\"IM_MSG_FILE_READ\",\"fileKey\":null,\"chatType\":null," +
"\"msgId\":\"7223316523140513815\",\"fileBizDomain\":\"IM\"}," +
"\"pointKey\":\"PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ\"}"

let testExpressionTrue: String = "true"

let testExpressionFalse: String = "False"

let testExpressionError: String = "1 + 1"

let testBizParams: [String: Any] = ["TENANT_ID": 1,
                                    "FILE_PROTECT_FILE_OP_BIZ_DOMAIN": "CCM",
                                    "ENTITY_TYPE": "FILE",
                                    "ENTITY_DOMAIN": "CCM",
                                    "ENTITY_OPERATE": "CCM_FILE_PREVIEW",
                                    "USER_ID": 7_129_402_444_798_246_931]

let testBaseParams: [String: Parameter] = ["DEVICE_TERMINAL": Parameter(key: "DEVICE_TERMINAL", value: {
                                                "DEVICE_TERMINAL"
                                            }),
                                           "DEVICE_OS": Parameter(key: "DEVICE_OS", value: {
                                               "DEVICE_OS"
                                           })]

let policyPriorityCacheKey = "PolicyPriorityCacheKey"
let testUserPolicyData = UserPolicyData(policyMap: ["7238857098922328084": PolicyInfo(version: "", filterCondition: testExpressionTrue)])
let testUserGroupPolicyData = UserGroupPolicyData(groupIdList: [], policyMap: [:])
let testDeptPolicyData = DeptPolicyData(userDeptIdsWithParent: [], userDeptIDPaths: [[]], rootNode: DeptNode(deptId: 1), policyMap: [:])
let testTenantPolicyData = TenantPolicyData(policyMap: [:])
let testPolicyPriorityData = PolicyPriorityData(user: testUserPolicyData,
                                                userGroup: testUserGroupPolicyData,
                                                department: testDeptPolicyData,
                                                tenant: testTenantPolicyData)

class TestPolicyEngine: XCTestCase {

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
        try? testStorage.set(testFastPassConfig, forKey: "FastPassConfigCacheKey")
        try? testStorage.set(testPolicyInfoDeny, forKey: policyEntityInfoCacheKey)
        try? testStorage.set(pointCutInfo, forKey: "PointCutInfoCacheKey")
        try? testStorage.set(testPolicyPriorityData, forKey: policyPriorityCacheKey)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testStorage.mmkv.removeAll()
    }

    func testRemoteValidate() throws {
        // 正常服务端计算
        var remoteValidate = RemoteValidate(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        remoteValidate.validate(requestMap: [testRequestKey: validateRequest]) { remoteResultMap in
            XCTAssertTrue(remoteResultMap[testRequestKey]?.type == .remote)
            XCTAssertTrue(remoteResultMap[testRequestKey]?.effect == .permit)
        }

        // domain校验失败
        remoteValidate = RemoteValidate(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironmentDomainFailure()))
        remoteValidate.validate(requestMap: [testRequestKey: validateRequest]) { remoteResultMap in
            XCTAssertTrue(remoteResultMap[testRequestKey]?.type == .local)
            XCTAssertTrue(remoteResultMap[testRequestKey]?.effect == .indeterminate)
        }

        // 错误码异常
        remoteValidate = RemoteValidate(service: TestSnCService(client: TestHTTPClientCodeNotZero(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        remoteValidate.validate(requestMap: [testRequestKey: validateRequest]) { remoteResultMap in
            XCTAssertTrue(remoteResultMap[testRequestKey]?.type == .remote)
            XCTAssertTrue(remoteResultMap[testRequestKey]?.effect == .indeterminate)
        }

        // 请求失败
        remoteValidate = RemoteValidate(service: TestSnCService(client: TestHTTPClientFailure(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        remoteValidate.validate(requestMap: [testRequestKey: validateRequest]) { remoteResultMap in
            XCTAssertTrue(remoteResultMap[testRequestKey]?.type == .local)
            XCTAssertTrue(remoteResultMap[testRequestKey]?.effect == .indeterminate)
        }
    }

    func testLocalValidate() throws {
        // 正常本地计算
        try? testStorage.set(testPolicyInfoDeny, forKey: policyEntityInfoCacheKey)
        let localValidate = LocalValidate(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        let policyProvider = PolicyProvider(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        let pointCutProvider = PointCutProvider(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        let subjectFactorProvider = SubjectFactorProvider(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        let priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider,
                                                      factorProvider: subjectFactorProvider,
                                                      service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        var validateContext = ValidateContext(policyProvider: policyProvider,
                                              pointCutProvider: pointCutProvider,
                                              priorityProvider: priorityProvider,
                                              factors: [:],
                                              baseParam: testBaseParams)
        var result = localValidate.validate(requestMap: [testRequestKey: validateRequest], context: validateContext)
        XCTAssertTrue(result[testRequestKey]?.effect == .deny)
        XCTAssertTrue(result[testRequestKey]?.type == .local)

        // 不支持的策略类型
        try? testStorage.set(pointCutInfoNoSupportPolicy, forKey: "PointCutInfoCacheKey")
        let localValidateNoSupportPolicy = LocalValidate(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        let policyProviderNoSupportPolicy = PolicyProvider(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        let pointCutProviderNoSupportPolicy = PointCutProvider(service: TestSnCService(client: TestHTTPClient(),
                                                                                       storage: testStorage,
                                                                                       settings: TestSettings(),
                                                                                       environment: TestEnvironment()))
        validateContext = ValidateContext(policyProvider: policyProviderNoSupportPolicy,
                                          pointCutProvider: pointCutProviderNoSupportPolicy,
                                          priorityProvider: priorityProvider,
                                          factors: [:],
                                          baseParam: testBaseParams)
        result = localValidateNoSupportPolicy.validate(requestMap: [testRequestKey: validateRequest], context: validateContext)
        XCTAssertTrue(result[testRequestKey]?.effect == .indeterminate)
        XCTAssertTrue(result[testRequestKey]?.type == .local)

        // pointCut异常
        testStorage.mmkv.removeAll()
        let localValidateNoPointCutInfo = LocalValidate(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        let policyProviderNoPointCutInfo = PolicyProvider(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        let pointCutProviderNoPointCutInfo = PointCutProvider(service: TestSnCService(client: TestHTTPClient(),
                                                                                       storage: testStorage,
                                                                                       settings: TestSettings(),
                                                                                       environment: TestEnvironment()))
        validateContext = ValidateContext(policyProvider: policyProviderNoPointCutInfo,
                                          pointCutProvider: pointCutProviderNoPointCutInfo,
                                          priorityProvider: priorityProvider,
                                          factors: [:],
                                          baseParam: testBaseParams)
        result = localValidateNoPointCutInfo.validate(requestMap: [testRequestKey: validateRequest], context: validateContext)
        XCTAssertTrue(result[testRequestKey]?.effect == .indeterminate)
        XCTAssertTrue(result[testRequestKey]?.type == .local)
    }

    func testPolicyRunner() throws {
        // 策略计算返回正确
        var contextParams = testBizParams
        for (key, valueFunc) in testBaseParams {
            contextParams[key] = valueFunc.value()
        }
        var runnerContext: RunnerContext = RunnerContext(uuid: "",
                                          contextParams: contextParams,
                                          policies: ["7238857098922328084": testPolicy],
                                          combineAlgorithm: .firstDenyApplicable,
                                          service: TestSnCService(client: TestHTTPClient(),
                                                                  storage: testStorage,
                                                                  logger: TestLogger(),
                                                                  monitor: TestMonitor(),
                                                                  settings: TestSettings(),
                                                                  environment: TestEnvironment()))
        var policyRunner: PolicyRunner = PolicyRunner(context: runnerContext)
        var result = try? policyRunner.runPolicy()
        XCTAssertTrue(result?.combinedEffect == .deny)

        // 策略计算返回Error
        runnerContext = RunnerContext(uuid: "",
                                      contextParams: contextParams,
                                      policies: ["7238857098922328084": testPolicyError],
                                      combineAlgorithm: .firstDenyApplicable,
                                      service: TestSnCService(client: TestHTTPClient(),
                                                              storage: testStorage,
                                                              logger: TestLogger(),
                                                              monitor: TestMonitor(),
                                                              settings: TestSettings(),
                                                              environment: TestEnvironment()))
        policyRunner = PolicyRunner(context: runnerContext)
        result = try? policyRunner.runPolicy()
        XCTAssertTrue(result?.combinedEffect == .indeterminate)
    }

    func testEnableFastPass() throws {
        // 不剪枝
        var policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        var result = policyEngine.enableFastPass(request: validateRequest)
        XCTAssertFalse(result)

        // 不剪枝，且租户不在配置策略租户列表中
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        result = policyEngine.enableFastPass(request: validateRequestNotFastPass)
        XCTAssertFalse(result)

        // 剪枝
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        result = policyEngine.enableFastPass(request: validateRequestFastPass)
        XCTAssertTrue(result)

        // 租户ID异常
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        result = policyEngine.enableFastPass(request: validateRequestFastPassTenantIdError)
        XCTAssertTrue(result)

        // objectTenantID异常
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        result = policyEngine.enableFastPass(request: validateRequestFastPassObjectTenantIdError)
        XCTAssertTrue(result)

        // 策略引擎开关关闭
        testSettings.setting["enable_policy_engine"] = false
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: testSettings,
                                                                environment: TestEnvironment()))
        result = policyEngine.enableFastPass(request: validateRequestFastPassObjectTenantIdError)
        XCTAssertTrue(result)
        testSettings.setting["enable_policy_engine"] = false

        // 切点信息异常
        testStorage.mmkv.removeAll()
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        result = policyEngine.enableFastPass(request: validateRequestFastPassObjectTenantIdError)
        XCTAssertFalse(result)
    }

    func testDowngradeDecision() throws {
        // 快速通过
        var policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        var result = policyEngine.downgradeDecision(request: validateRequestFastPass)
        XCTAssertTrue(result.effect == .permit)

        // 不剪枝，正常获得降级策略
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        result = policyEngine.downgradeDecision(request: validateRequest)
        XCTAssertTrue(result.effect == .permit)

        // 不剪枝，异常情况
        testStorage.mmkv.removeAll()
        let policyEngineError = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironmentDomainFailure()))
        result = policyEngineError.downgradeDecision(request: validateRequest)
        XCTAssertTrue(result.effect == .indeterminate)
        XCTAssertTrue(result.type == .downgrade)
    }

    func testCheckPointcutIsControlledByFactors() throws {
        var exp = expectation(description: "异步操作1")
        // 不剪枝，正常请求，不受特征管控
        var policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        var checkPointcutRequest = CheckPointcutRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                                        entityJSONObject: entity as [String: Any],
                                                        factors: [])
        policyEngine.checkPointcutIsControlledByFactors(requestMap: [testRequestKey: checkPointcutRequest]) { retMap in
            XCTAssertTrue(retMap[testRequestKey] == false)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }

        // 不剪枝，domain异常，不受特征管控
        exp = expectation(description: "异步操作2")
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironmentDomainFailure()))
        checkPointcutRequest = CheckPointcutRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                                        entityJSONObject: entity as [String: Any],
                                                        factors: [])
        policyEngine.checkPointcutIsControlledByFactors(requestMap: [testRequestKey: checkPointcutRequest]) { retMap in
            XCTAssertTrue(retMap.isEmpty)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }

        // 不剪枝，状态码异常
        exp = expectation(description: "异步操作3")
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClientCodeNotZero(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        checkPointcutRequest = CheckPointcutRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                                        entityJSONObject: entity as [String: Any],
                                                        factors: [])
        policyEngine.checkPointcutIsControlledByFactors(requestMap: [testRequestKey: checkPointcutRequest]) { retMap in
            XCTAssertTrue(retMap.isEmpty)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }

        // 不剪枝，请求失败
        exp = expectation(description: "异步操作4")
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClientFailure(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        checkPointcutRequest = CheckPointcutRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                                        entityJSONObject: entity as [String: Any],
                                                        factors: [])
        policyEngine.checkPointcutIsControlledByFactors(requestMap: [testRequestKey: checkPointcutRequest]) { retMap in
            XCTAssertTrue(retMap.isEmpty)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }

        // 剪枝
        exp = expectation(description: "异步操作5")
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        checkPointcutRequest = CheckPointcutRequest(pointKey: "PC:CLIENT:ios:PointKey_IM_MSG_FILE_READ",
                                                        entityJSONObject: entityFastPass as [String: Any],
                                                        factors: [])
        policyEngine.checkPointcutIsControlledByFactors(requestMap: [testRequestKey: checkPointcutRequest]) { retMap in
            XCTAssertTrue(retMap[testRequestKey] == false)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }

    func testEnvValue() {
        var contextParams = testBizParams
        for (key, valueFunc) in testBaseParams {
            contextParams[key] = valueFunc.value()
        }
        // 取baseParams
        let exp = ExpressionEnv(contextParams: contextParams)
        var result = exp.envValue(ofKey: "DEVICE_TERMINAL")
        XCTAssertTrue(result as? String == "DEVICE_TERMINAL")

        // 取cache
        result = exp.envValue(ofKey: "DEVICE_TERMINAL")
        XCTAssertTrue(result as? String == "DEVICE_TERMINAL")

        // 取bizParams
        result = exp.envValue(ofKey: "ENTITY_TYPE")
        XCTAssertTrue(result as? String == "FILE")

        // 空值
        result = exp.envValue(ofKey: "unknown")
        XCTAssertTrue(result == nil)
    }

    func testEnableFetchPolicy() {
        // 租户ID异常
        var policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        var result = policyEngine.enableFetchPolicy(tenantId: "-1")
        XCTAssertTrue(result)

        // 禁用策略引擎
        testSettings.setting["enable_policy_engine"] = false
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: testSettings,
                                                                environment: TestEnvironment()))
        result = policyEngine.enableFetchPolicy(tenantId: "1")
        XCTAssertFalse(result)
        testSettings.setting["enable_policy_engine"] = true
    }

    func testAsyncValidate() throws {
        // 本地决策
        var policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        let param = Parameter(key: "", value: {
            ""
        })
        policyEngine.register(parameter: param)
        let observerImp = ObserverImp()
        policyEngine.register(observer: observerImp)
        policyEngine.validate(requestMap: [testRequestKey: validateRequest]) { responseMap, _, _ in
            XCTAssertTrue(responseMap[testRequestKey]?.effect == .deny)
        }
        policyEngine.postEvent(event: .timerEvent)
        policyEngine.remove(observer: observerImp)
        policyEngine.remove(parameter: param)

        // 本地决策，全部剪枝
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        policyEngine.validate(requestMap: [testRequestKey: validateRequestFastPass]) { responseMap, _, _ in
            XCTAssertTrue(responseMap[testRequestKey]?.effect == .permit)
        }

        // 服务端决策
        testStorage.mmkv.removeAll()
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                            storage: testStorage,
                                                            logger: TestLogger(),
                                                            monitor: TestMonitor(),
                                                            settings: TestSettings(),
                                                            environment: TestEnvironment()))
        policyEngine.validate(requestMap: [testRequestKey: validateRequest]) { responseMap, _, _ in
            XCTAssertTrue(responseMap[testRequestKey]?.effect == .permit)
        }

        // 服务端决策,有错误信息,key对不上
        try? testStorage.set(testPolicyInfo, forKey: policyEntityInfoCacheKey)
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClientErrorCodeNotZero(),
                                                            storage: testStorage,
                                                            logger: TestLogger(),
                                                            monitor: TestMonitor(),
                                                            settings: TestSettings(),
                                                            environment: TestEnvironment()))
        policyEngine.validate(requestMap: ["errorKey": validateRequestRemote]) { responseMap, _, _ in
            XCTAssertTrue(responseMap["errorKey"]?.effect == .indeterminate)
            XCTAssertTrue(responseMap["errorKey"]?.type == .downgrade)
        }

        // 服务端决策,有错误信息
        try? testStorage.set(testPolicyInfo, forKey: policyEntityInfoCacheKey)
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClientCodeNotZero(),
                                                            storage: testStorage,
                                                            logger: TestLogger(),
                                                            monitor: TestMonitor(),
                                                            settings: TestSettings(),
                                                            environment: TestEnvironment()))
        policyEngine.validate(requestMap: [testRequestKey: validateRequestRemote]) { responseMap, _, _ in
            XCTAssertTrue(responseMap[testRequestKey]?.effect == .indeterminate)
            XCTAssertTrue(responseMap[testRequestKey]?.type == .downgrade)
        }

        // 异步方法测试
        testStorage.mmkv.removeAll()
        let exp = expectation(description: "异步操作")
        policyEngine.asyncValidate(requestMap: [testRequestKey: validateRequest]) { responseMap in
            XCTAssertTrue(responseMap[testRequestKey]?.effect == .permit)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }

    func testReportRealLog() throws {
        // 正常上报
        testStorage.mmkv.removeAll()
        let evaluateInfoStorage = EvaluateInfo(evaluateUk: "11", operateTime: "22", policySetKeys: ["33"])
        try? testStorage.set([evaluateInfoStorage], forKey: "DecisionLogCacheKey")
        var policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        var evaluateInfo = EvaluateInfo(evaluateUk: "1", operateTime: "2", policySetKeys: ["3"])
        var expectation = XCTestExpectation(description: "testReportRealLog")
        policyEngine.reportRealLog(evaluateInfoList: [evaluateInfo])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertTrue((self.testStorage.mmkv["DecisionLogCacheKey"] as? [String])?.isEmpty == true)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)

        // 上报失败
        testStorage.mmkv.removeAll()
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClientFailure(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        evaluateInfo = EvaluateInfo(evaluateUk: "1", operateTime: "2", policySetKeys: ["3"])
        expectation = XCTestExpectation(description: "testreportRealLog")
        policyEngine.reportRealLog(evaluateInfoList: [evaluateInfo])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertNotNil(self.testStorage.mmkv["DecisionLogCacheKey"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testDeleteDecisionLog() throws {
        // 正常上报
        let evaluateInfo = EvaluateInfo(evaluateUk: "1", operateTime: "2", policySetKeys: ["3"])
        var logger = TestLoggerForDecisionLogManager()
        var policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: logger,
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        var expectation = XCTestExpectation(description: "testDeleteDecisionLog")
        policyEngine.deleteDecisionLog(evaluateInfoList: [evaluateInfo])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertEqual(logger.flag, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)

        // 上报失败
        logger = TestLoggerForDecisionLogManager()
        policyEngine = PolicyEngine(service: TestSnCService(client: TestHTTPClientFailure(),
                                                                storage: testStorage,
                                                                logger: logger,
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        expectation = XCTestExpectation(description: "testreportRealLog")
        policyEngine.deleteDecisionLog(evaluateInfoList: [evaluateInfo])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertEqual(logger.flag, 2)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testDecisionLogManager() throws {
        // 正常上报
        testStorage.mmkv.removeAll()
        let evaluateInfoStorageData1 = EvaluateInfo(evaluateUk: "1", operateTime: "11", policySetKeys: ["111"])
        let evaluateInfoStorageData2 = EvaluateInfo(evaluateUk: "2", operateTime: "22", policySetKeys: ["222"])
        let evaluateInfoStorageData3 = EvaluateInfo(evaluateUk: "3", operateTime: "33", policySetKeys: ["333"])
        try? testStorage.set([evaluateInfoStorageData1, evaluateInfoStorageData2], forKey: "DecisionLogCacheKey")
        let logger = TestLoggerForDecisionLogManager()
        let decisionLogManager = DecisionLogManager(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: logger,
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))
        decisionLogManager.addEvaluateInfo(evaluateInfoList: [evaluateInfoStorageData3])
        XCTAssertTrue(decisionLogManager.getDecisionLogList().count == 3)
        XCTAssertTrue(decisionLogManager.getDecisionLogList()[0].evaluateUk == "3")
        
        var evaluateInfoList: [EvaluateInfo] = []
        for i in 1...98 {
            let evaluateInfoStorageData = EvaluateInfo(evaluateUk: "\(i)", operateTime: String(i), policySetKeys: ["\(i)"])
            evaluateInfoList.append(evaluateInfoStorageData)
        }
        decisionLogManager.addEvaluateInfo(evaluateInfoList: evaluateInfoList)
        XCTAssertTrue(decisionLogManager.getDecisionLogList().count == 100)
        XCTAssertTrue(decisionLogManager.getDecisionLogList()[98].evaluateUk == "3")
    }
}
