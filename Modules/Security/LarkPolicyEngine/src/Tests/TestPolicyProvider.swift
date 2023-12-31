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

let testPolicyInfo: PolicyEntityModel? = PolicyEntityModel(policies: ["7238857098922328084": testPolicy],
                                                                     policyType2combineAlgorithm: ["FILE_PROTECT": "FirstDenyApplicable",
                                                                                                   "unknown": "unknown"])

let testPolicyInfoPolicyRuntimeConfigModel: PolicyRuntimeConfigModel? = PolicyRuntimeConfigModel(policies: [testPolicy],
                                                                     policyType2combineAlgorithm: ["FILE_PROTECT": "FirstDenyApplicable",
                                                                                                   "unknown": "unknown"])

let testPolicy: Policy = Policy(id: "7238857098922328084",
                               name: "file control test",
                               tenantID: "1",
                               type: .fileProtect,
                               filterCondition: Condition(rawExpression: testExpressionTrue),
                               rules: [Rule(condition: Condition(rawExpression: testExpressionTrue),
                                            decision: Decision(effect: .deny,
                                                               actions: [ConditionalAction(condition: Condition(rawExpression: "true"),
                                                                                           actions: ["FILE_BLOCK_COMMON"])]))],
                               combineAlgorithm: .firstDenyApplicable,
                               version: "1685428190585612777",
                               basedOn: .policyBasedOnEntitySubject)

let testPolicyFalse: Policy = Policy(id: "7238857098922328084",
                               name: "file control test",
                               tenantID: "1",
                               type: .fileProtect,
                               filterCondition: Condition(rawExpression: testExpressionTrue),
                               rules: [Rule(condition: Condition(rawExpression: testExpressionFalse),
                                            decision: Decision(effect: .deny,
                                                               actions: [ConditionalAction(condition: Condition(rawExpression: "true"),
                                                                                           actions: ["FILE_BLOCK_COMMON"])]))],
                               combineAlgorithm: .firstDenyApplicable,
                               version: "1685428190585612777",
                               basedOn: .policyBasedOnEntitySubject)

let testPolicyError: Policy = Policy(id: "7238857098922328084",
                               name: "file control test",
                               tenantID: "1",
                               type: .fileProtect,
                               filterCondition: Condition(rawExpression: testExpressionTrue),
                               rules: [Rule(condition: Condition(rawExpression: testExpressionError),
                                            decision: Decision(effect: .deny,
                                                               actions: [ConditionalAction(condition: Condition(rawExpression: "true"),
                                                                                           actions: ["FILE_BLOCK_COMMON"])]))],
                               combineAlgorithm: .firstDenyApplicable,
                               version: "1685428190585612777",
                               basedOn: .policyBasedOnEntitySubject)

let testPolicyNoSupport: Policy = Policy(id: "7238857098922328084",
                               name: "file control test",
                               tenantID: "1",
                               type: .unknown,
                               filterCondition: Condition(rawExpression: testExpressionTrue),
                               rules: [Rule(condition: Condition(rawExpression: testExpressionTrue),
                                            decision: Decision(effect: .deny,
                                                               actions: [ConditionalAction(condition: Condition(rawExpression: "true"),
                                                                                           actions: ["FILE_BLOCK_COMMON"])]))],
                               combineAlgorithm: .firstDenyApplicable,
                               version: "1685428190585612777",
                               basedOn: .policyBasedOnEntitySubject)

let testPolicyInfoDeny: PolicyEntityModel? = PolicyEntityModel(policies: ["7238857098922328084": testPolicy],
                                                                     policyType2combineAlgorithm: ["FILE_PROTECT": "FirstDenyApplicable"])

let testPolicyInfoNoSupportPolicy: PolicyEntityModel? = PolicyEntityModel(policies: ["7238857098922328084": testPolicyNoSupport],
                                                                     policyType2combineAlgorithm: ["FILE_PROTECT": "FirstDenyApplicable"])

let testPolicyPairsModel: PolicyPairsModel = PolicyPairsModel(policyPairs: testPolicyPairs, policyType2CombineAlgorithmMap: ["FILE_PROTECT": "FirstDenyApplicable"])

let testPolicyPairs = [PolicyPair(id: "7291237151878184979", version: "1697632806820311875"),
                       PolicyPair(id: "7291237162719952915", version: "1697632397028291189"),
                       PolicyPair(id: "7291237167988539411", version: "1697632858124091689")]

let testPolicyEntityResponse = PolicyEntityResponse(policies: [testPolicyDepartmentFileProtection,
                                                               testPolicyUserGroupFileProtection,
                                                               testPolicyUserFileProtection])

let testPolicyDepartmentFileProtection = Policy(id: "7291237167988539411",
                               name: "部门 - 文件保护",
                               tenantID: "7097511431411499028",
                               type: .fileProtect,
                               filterCondition: Condition(rawExpression: "([USER_DEPT_IDS_WITH_PARENT] hasIn {7291276489880764435})"),
                               rules: [Rule(condition: Condition(rawExpression: "(((([FILE_PROTECT_FILE_OP_BIZ_DOMAIN] == 'CCM') &&" +
                                                                 " ([ENTITY_OPERATE] hasIn {'CCM_FILE_DOWNLOAD'," +
                                                                 "'CCM_ATTACHMENT_DOWNLOAD','CCM_EXPORT'}) &&" +
                                                                 " ([ENTITY_TYPE] hasIn {'DOC','DOCX','SHEET','BITABLE'" +
                                                                 ",'MINDNOTE','DASHBOARD','PIVOT_TABLE','BITABLE_SHARE_FORM'" +
                                                                 ",'CHART','SPACE_CATALOG','WIKI_SPACE'}) &&" +
                                                                 " (([OPERATOR_TENANT_ID] == [OBJECT_TENANT_ID]) ||" +
                                                                 " (IsExisted([OBJECT_TENANT_ID]) == false) ||" +
                                                                 " (IsNull([OBJECT_TENANT_ID]) == true) || ([OBJECT_TENANT_ID] == 0))))) &&" +
                                                                 " ((([DEVICE_OS] hasIn {4,5}))) && ((IsExisted([OPEN_PLATFORM_APP_ID]) == false) ||" +
                                                                 " (IsNull([OPEN_PLATFORM_APP_ID]) == true) || ([OPEN_PLATFORM_APP_ID] == 0))"),
                                            decision: Decision(effect: .deny,
                                                               actions: [ConditionalAction(condition: Condition(rawExpression: "true"),
                                                                                           actions: ["FILE_BLOCK_COMMON"])]))],
                               combineAlgorithm: .firstDenyApplicable,
                               version: "1697632858124091689",
                               basedOn: .policyBasedOnEntitySubject)

let testPolicyUserGroupFileProtection = Policy(id: "7291237151878184979",
                               name: "用户组 - 文件保护",
                               tenantID: "7097511431411499028",
                               type: .fileProtect,
                               filterCondition: Condition(rawExpression: "([USER_GROUP_IDS] hasIn {7291261268048543763})"),
                               rules: [Rule(condition: Condition(rawExpression: "(((([FILE_PROTECT_FILE_OP_BIZ_DOMAIN] == 'CCM')" +
                                                                 " && ([ENTITY_OPERATE] hasIn" +
                                                                 " {'CCM_FILE_DOWNLOAD','CCM_ATTACHMENT_DOWNLOAD','CCM_EXPORT'}) &&" +
                                                                 " ([ENTITY_TYPE] hasIn {'DOC','DOCX','SHEET'," +
                                                                 "'BITABLE','MINDNOTE','DASHBOARD','PIVOT_TABLE'," +
                                                                 "'BITABLE_SHARE_FORM','CHART','SPACE_CATALOG'," +
                                                                 "'WIKI_SPACE'}) && (([OPERATOR_TENANT_ID] ==" +
                                                                 " [OBJECT_TENANT_ID]) || (IsExisted([OBJECT_TENANT_ID]) == false) ||" +
                                                                 " (IsNull([OBJECT_TENANT_ID]) == true) || ([OBJECT_TENANT_ID] == 0))))) &&" +
                                                                 " ((([DEVICE_OS] hasIn {5,4}))) && ((IsExisted([OPEN_PLATFORM_APP_ID]) == false) ||" +
                                                                 " (IsNull([OPEN_PLATFORM_APP_ID]) == true) || ([OPEN_PLATFORM_APP_ID] == 0))"),
                                            decision: Decision(effect: .deny,
                                                               actions: [ConditionalAction(condition: Condition(rawExpression: "true"),
                                                                                           actions: ["FILE_BLOCK_COMMON"])]))],
                               combineAlgorithm: .firstDenyApplicable,
                               version: "1697632806820311875",
                               basedOn: .policyBasedOnEntitySubject)

let testPolicyUserFileProtection = Policy(id: "7291237162719952915",
                               name: "用户 - 文件保护",
                               tenantID: "7097511431411499028",
                               type: .fileProtect,
                               filterCondition: Condition(rawExpression: "([USER_ID] hasIn {7290815892810645524})"),
                               rules: [Rule(condition: Condition(rawExpression: "(((([FILE_PROTECT_FILE_OP_BIZ_DOMAIN] == 'CCM') &&" +
                                                                 " ([ENTITY_OPERATE] hasIn {'CCM_FILE_PREVIEW','CCM_CONTENT_PREVIEW'}) &&" +
                                                                 " ([ENTITY_TYPE] hasIn {'DOC','DOCX','SHEET','BITABLE','MINDNOTE'," +
                                                                 "'DASHBOARD','PIVOT_TABLE','BITABLE_SHARE_FORM'," +
                                                                 "'CHART','SPACE_CATALOG','WIKI_SPACE'}) &&" +
                                                                 " (([OPERATOR_TENANT_ID] == [OBJECT_TENANT_ID]) ||" +
                                                                 " (IsExisted([OBJECT_TENANT_ID]) == false) ||" +
                                                                 " (IsNull([OBJECT_TENANT_ID]) == true) ||" +
                                                                 " ([OBJECT_TENANT_ID] == 0))))) && ((([DEVICE_OS] hasIn {5,4}))) &&" +
                                                                 " ((IsExisted([OPEN_PLATFORM_APP_ID]) == false) ||" +
                                                                 " (IsNull([OPEN_PLATFORM_APP_ID]) == true) ||" +
                                                                 " ([OPEN_PLATFORM_APP_ID] == 0))"),
                                            decision: Decision(effect: .deny,
                                                               actions: [ConditionalAction(condition: Condition(rawExpression: "true"),
                                                                                           actions: ["FILE_BLOCK_COMMON"])]))],
                               combineAlgorithm: .firstDenyApplicable,
                               version: "1697632397028291189",
                               basedOn: .policyBasedOnEntitySubject)

class PolicyProviderDelegateImp: ProviderDelegate {
    func postOuterEvent(event: LarkPolicyEngine.Event) {
        // do nothing
    }

    func postInnerEvent(event: LarkPolicyEngine.InnerEvent) {
        // do nothing
    }

    func tenantHasDeployPolicy() -> Bool {
        true
    }
}

class PolicyProviderDelegateImpFailure: ProviderDelegate {
    func postOuterEvent(event: LarkPolicyEngine.Event) {
        // do nothing
    }

    func postInnerEvent(event: LarkPolicyEngine.InnerEvent) {
        // do nothing
    }

    func tenantHasDeployPolicy() -> Bool {
        false
    }
}

class TestPolicyProvider: XCTestCase {

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
        try? testStorage.set(testPolicyInfo, forKey: policyEntityInfoCacheKey)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testStorage.mmkv.removeAll()
    }

    func testSelectPolicy() throws {
        // 策略类型信息为空
        let policyProvider = PolicyProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        var result = policyProvider.selectPolicy(by: .DLPAsyncPolicy)
        XCTAssertTrue(result.isEmpty)

        // 策略信息正常获得
        result = policyProvider.selectPolicy(by: .fileProtect)
        XCTAssertTrue(result["7238857098922328084"]?.type == .fileProtect)

        // 策略信息为nil
        testStorage.mmkv.removeAll()
        let policyProviderNilTest = PolicyProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        result = policyProviderNilTest.selectPolicy(by: .fileProtect)
        XCTAssertTrue(result.isEmpty)
    }

    func testSelectPolicyCombineAlgorithm() throws {
        // 正常拿到策略组合算法
        let policyProvider = PolicyProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        let result = try policyProvider.selectPolicyCombineAlgorithm(by: .fileProtect)
        XCTAssertTrue(result.rawValue == "FirstDenyApplicable")

        // 没有符合的降级信息
        XCTAssertThrowsError(try policyProvider.selectPolicyCombineAlgorithm(by: .unknown)) { error in
            let myError = error as? PolicyEngineError
            XCTAssertEqual(myError?.error.code, 204)
        }

        // 策略信息为nil
        testStorage.mmkv.removeAll()
        let policyProviderNilTest = PolicyProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings))
        XCTAssertThrowsError(try policyProviderNilTest.selectPolicyCombineAlgorithm(by: .fileProtect)) { error in
            let myError = error as? PolicyEngineError
            XCTAssertEqual(myError?.error.code, 204)
        }
    }

    func testFetchPolicy() throws {
        // 获取信息成功
        testStorage.mmkv.removeAll()
        var policyProvider = PolicyProvider(service: TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        var delegate = PolicyProviderDelegateImp()
        policyProvider.delegate = delegate
        policyProvider.updatePolicyInfo()
        var expectation = XCTestExpectation(description: "testFetchPolicy 1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNotNil(self.testStorage.mmkv[policyEntityInfoCacheKey])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // 成功但是状态码异常
        testStorage.mmkv.removeAll()
        policyProvider = PolicyProvider(service: TestSnCService(client: TestHTTPClientCodeNotZero(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        delegate = PolicyProviderDelegateImp()
        policyProvider.delegate = delegate
        policyProvider.updatePolicyInfo()
        expectation = XCTestExpectation(description: "testFetchPolicy 2")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv[policyEntityInfoCacheKey])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // 获取信息失败
        testStorage.mmkv.removeAll()
        policyProvider = PolicyProvider(service: TestSnCService(client: TestHTTPClientFailure(), storage: testStorage, settings: TestSettings(), environment: TestEnvironment()))
        delegate = PolicyProviderDelegateImp()
        policyProvider.delegate = delegate
        policyProvider.updatePolicyInfo()
        // 失败重试
        policyProvider.updatePolicyInfo()
        expectation = XCTestExpectation(description: "testFetchPolicy 3")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv[policyEntityInfoCacheKey])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // domain无效
        testStorage.mmkv.removeAll()
        policyProvider = PolicyProvider(service: TestSnCService(client: TestHTTPClientFailure(),
                                                                    storage: testStorage,
                                                                    settings: TestSettings(),
                                                                    environment: testEnvironmentDomainFailure))
        delegate = PolicyProviderDelegateImp()
        policyProvider.delegate = delegate
        policyProvider.updatePolicyInfo()
        expectation = XCTestExpectation(description: "testFetchPolicy 4")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv[policyEntityInfoCacheKey])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // 策略引擎开关关闭
        testStorage.mmkv.removeAll()
        testSettings.setting["enable_policy_engine"] = false
        policyProvider = PolicyProvider(service: TestSnCService(client: TestHTTPClientFailure(), storage: testStorage, settings: testSettings, environment: testEnvironment))
        delegate = PolicyProviderDelegateImp()
        policyProvider.delegate = delegate
        policyProvider.updatePolicyInfo()
        expectation = XCTestExpectation(description: "testFetchPolicy 5")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv[policyEntityInfoCacheKey])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        testSettings.setting["enable_policy_engine"] = true

        // 读写失败
        testStorage.mmkv.removeAll()
        policyProvider = PolicyProvider(service: TestSnCService(client: testHttpClient, storage: testStorageFailure, settings: testSettings, environment: testEnvironment))
        delegate = PolicyProviderDelegateImp()
        policyProvider.delegate = delegate
        policyProvider.updatePolicyInfo()
        expectation = XCTestExpectation(description: "testFetchPolicy 6")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv[policyEntityInfoCacheKey])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // 代理失败
        testStorage.mmkv.removeAll()
        policyProvider = PolicyProvider(service: TestSnCService(client: testHttpClient, storage: testStorage, settings: testSettings, environment: testEnvironment))
        let delegateFailure = PolicyProviderDelegateImpFailure()
        policyProvider.delegate = delegateFailure
        policyProvider.updatePolicyInfo()
        expectation = XCTestExpectation(description: "testFetchPolicy 7")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(self.testStorage.mmkv[policyEntityInfoCacheKey])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

}
