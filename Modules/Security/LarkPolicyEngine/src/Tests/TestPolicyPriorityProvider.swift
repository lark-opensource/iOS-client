//
//  TestPolicyPriorityProvider.swift
//  LarkPolicyEngine-Unit-Tests
//
//  Created by Wujie on 2023/10/17.
//

import Foundation
@testable import LarkPolicyEngine
import LarkSnCService
import XCTest

class TestPolicyPriorityProvider: XCTestCase {

    let testStorage = TestStorage()
    let testStorageFailure = TestStorageFailure()
    let testHttpClient = TestHTTPClient()
    let testSettings = TestSettings()
    let testEnvironmentForPolicyPriority = TestEnvironmentForPolicyPriority()
    let testHTTPClientCodeNotZero = TestHTTPClientCodeNotZero()
    let testHTTPClientFailure = TestHTTPClientFailure()
    let testEnvironmentDomainFailure = TestEnvironmentDomainFailure()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        testStorage.mmkv.removeAll()
    }

    func testPolicyPriorityProvider() throws {
        // 正常计算策略优先级
        var eventDriver = WeakManager<EventDriver>()
        let testService = TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: testSettings, environment: testEnvironmentForPolicyPriority)
        let testServiceErrorUserId = TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: testSettings, environment: TestEnvironmentForPolicyPriorityErrorUserId())
        var policyProvider = PolicyProvider(service: testService)
        var subjectFactorProvider = SubjectFactorProvider(service: testService)
        subjectFactorProvider.fetchSubjectFactor()
        policyProvider.updatePolicyInfo()
        
        var priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider, factorProvider: subjectFactorProvider, service: testService)
        eventDriver.register(object: priorityProvider)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            eventDriver.sendEvent(event: .policyUpdate)
        }
        
        var expectation = XCTestExpectation(description: "testPolicyPriorityProvider 1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let data = priorityProvider.priorityData
            // user
            XCTAssertTrue(data?.user.policyMap.keys.contains("7291237162719952915") == true)
            XCTAssertTrue(data?.user.policyMap["7291237162719952915"]?.version == "1697632397028291189")
            XCTAssertTrue(data?.user.policyMap["7291237162719952915"]?.filterCondition == "([USER_ID] hasIn {7290815892810645524})")
            
            // userGroup
            XCTAssertTrue(data?.userGroup.groupIdList == [7_291_261_268_048_543_763])
            XCTAssertTrue(data?.userGroup.policyMap.keys.contains("7291237151878184979") == true)
            XCTAssertTrue(data?.userGroup.policyMap["7291237151878184979"]?.version == "1697632806820311875")
            XCTAssertTrue(data?.userGroup.policyMap["7291237151878184979"]?.filterCondition == "([USER_GROUP_IDS] hasIn {7291261268048543763})")
            
            // department
            XCTAssertTrue(data?.department.policyMap.keys.contains("7291237167988539411") == true)
            let rootDepartment = data?.department.rootNode
            XCTAssertTrue(rootDepartment?.deptId == 0)
            let secondDepartment = rootDepartment?.children[7_291_276_489_880_764_435]
            XCTAssertTrue(secondDepartment?.deptId == 7_291_276_489_880_764_435)
            XCTAssertTrue(secondDepartment?.policyMap.keys.contains("7291237167988539411") == true)
            XCTAssertTrue(secondDepartment?.policyMap["7291237167988539411"]?.version == "1697632858124091689")
            XCTAssertTrue(secondDepartment?.policyMap["7291237167988539411"]?.filterCondition == "([USER_DEPT_IDS_WITH_PARENT] hasIn {7291276489880764435})")
            let thridDepartment = secondDepartment?.children[7_291_276_754_474_237_972]
            XCTAssertTrue(thridDepartment?.deptId == 7_291_276_754_474_237_972)
            let lastDepartment = thridDepartment?.children[7_291_276_855_707_959_315]
            XCTAssertTrue(lastDepartment?.deptId == 7_291_276_855_707_959_315)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
        
        // 策略为空的异常
        testStorage.mmkv.removeAll()
        policyProvider = PolicyProvider(service: testService)
        subjectFactorProvider = SubjectFactorProvider(service: testService)
        priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider, factorProvider: subjectFactorProvider, service: testService)
        eventDriver = WeakManager<EventDriver>()
        eventDriver.register(object: priorityProvider)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            eventDriver.sendEvent(event: .policyUpdate)
        }
        
        expectation = XCTestExpectation(description: "testPolicyPriorityProvider 2")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let data = priorityProvider.priorityData
            XCTAssertNil(data)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
        
        // userId 异常
        testStorage.mmkv.removeAll()
        policyProvider = PolicyProvider(service: testServiceErrorUserId)
        subjectFactorProvider = SubjectFactorProvider(service: testServiceErrorUserId)
        priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider, factorProvider: subjectFactorProvider, service: testServiceErrorUserId)
        eventDriver = WeakManager<EventDriver>()
        eventDriver.register(object: priorityProvider)
        policyProvider.updatePolicyInfo()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            eventDriver.sendEvent(event: .policyUpdate)
        }
        
        expectation = XCTestExpectation(description: "testPolicyPriorityProvider 3")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let data = priorityProvider.priorityData
            XCTAssertNil(data)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
        
        // 主体特征获取异常
        testStorage.mmkv.removeAll()
        policyProvider = PolicyProvider(service: testService)
        subjectFactorProvider = SubjectFactorProvider(service: testService)
        priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider, factorProvider: subjectFactorProvider, service: testService)
        eventDriver = WeakManager<EventDriver>()
        eventDriver.register(object: priorityProvider)
        policyProvider.updatePolicyInfo()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            eventDriver.sendEvent(event: .policyUpdate)
        }
        
        expectation = XCTestExpectation(description: "testPolicyPriorityProvider 4")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let data = priorityProvider.priorityData
            XCTAssertNil(data)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }
    
//  rust 代码尚未集成，单测会卡CI，这里先注释掉，本地测试通过
//    func testPolicyPriorityProviderForRustExpr() throws {
//        // 正常计算策略优先级
//        var eventDriver = WeakManager<EventDriver>()
//        let testService = TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: TestSettingsRustExpr(), environment: testEnvironmentForPolicyPriority)
//        let testServiceErrorUserId = TestSnCService(client: TestHTTPClient(),
//                                                    storage: testStorage,
//                                                    settings: TestSettingsRustExpr(),
//                                                    environment: TestEnvironmentForPolicyPriorityErrorUserId())
//        var policyProvider = PolicyProvider(service: testService)
//        var subjectFactorProvider = SubjectFactorProvider(service: testService)
//        subjectFactorProvider.fetchSubjectFactor()
//        policyProvider.updatePolicyInfo()
//
//        var priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider, factorProvider: subjectFactorProvider, service: testService)
//        eventDriver.register(object: priorityProvider)
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            eventDriver.sendEvent(event: .policyUpdate)
//        }
//        
//        var expectation = XCTestExpectation(description: "testPolicyPriorityProvider 1")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            let data = priorityProvider.priorityData
//            // user
//            XCTAssertTrue(data?.user.policyMap.keys.contains("7291237162719952915") == true)
//            XCTAssertTrue(data?.user.policyMap["7291237162719952915"]?.version == "1697632397028291189")
//            XCTAssertTrue(data?.user.policyMap["7291237162719952915"]?.filterCondition == "([USER_ID] hasIn {7290815892810645524})")
//            
//            // userGroup
//            XCTAssertTrue(data?.userGroup.groupIdList == [7_291_261_268_048_543_763])
//            XCTAssertTrue(data?.userGroup.policyMap.keys.contains("7291237151878184979") == true)
//            XCTAssertTrue(data?.userGroup.policyMap["7291237151878184979"]?.version == "1697632806820311875")
//            XCTAssertTrue(data?.userGroup.policyMap["7291237151878184979"]?.filterCondition == "([USER_GROUP_IDS] hasIn {7291261268048543763})")
//            
//            // department
//            XCTAssertTrue(data?.department.policyMap.keys.contains("7291237167988539411") == true)
//            let rootDepartment = data?.department.rootNode
//            XCTAssertTrue(rootDepartment?.deptId == 0)
//            let secondDepartment = rootDepartment?.children[7_291_276_489_880_764_435]
//            XCTAssertTrue(secondDepartment?.deptId == 7_291_276_489_880_764_435)
//            XCTAssertTrue(secondDepartment?.policyMap.keys.contains("7291237167988539411") == true)
//            XCTAssertTrue(secondDepartment?.policyMap["7291237167988539411"]?.version == "1697632858124091689")
//            XCTAssertTrue(secondDepartment?.policyMap["7291237167988539411"]?.filterCondition == "([USER_DEPT_IDS_WITH_PARENT] hasIn {7291276489880764435})")
//            let thridDepartment = secondDepartment?.children[7_291_276_754_474_237_972]
//            XCTAssertTrue(thridDepartment?.deptId == 7_291_276_754_474_237_972)
//            let lastDepartment = thridDepartment?.children[7_291_276_855_707_959_315]
//            XCTAssertTrue(lastDepartment?.deptId == 7_291_276_855_707_959_315)
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 4.0)
//        
//        // 策略为空的异常
//        testStorage.mmkv.removeAll()
//        policyProvider = PolicyProvider(service: testService)
//        subjectFactorProvider = SubjectFactorProvider(service: testService)
//        priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider, factorProvider: subjectFactorProvider, service: testService)
//        eventDriver = WeakManager<EventDriver>()
//        eventDriver.register(object: priorityProvider)
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            eventDriver.sendEvent(event: .policyUpdate)
//        }
//        
//        expectation = XCTestExpectation(description: "testPolicyPriorityProvider 2")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            let data = priorityProvider.priorityData
//            XCTAssertNil(data)
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 4.0)
//        
//        // userId 异常
//        testStorage.mmkv.removeAll()
//        policyProvider = PolicyProvider(service: testServiceErrorUserId)
//        subjectFactorProvider = SubjectFactorProvider(service: testServiceErrorUserId)
//        priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider, factorProvider: subjectFactorProvider, service: testServiceErrorUserId)
//        eventDriver = WeakManager<EventDriver>()
//        eventDriver.register(object: priorityProvider)
//        policyProvider.updatePolicyInfo()
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            eventDriver.sendEvent(event: .policyUpdate)
//        }
//        
//        expectation = XCTestExpectation(description: "testPolicyPriorityProvider 3")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            let data = priorityProvider.priorityData
//            XCTAssertNil(data)
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 4.0)
//        
//        // 主体特征获取异常
//        testStorage.mmkv.removeAll()
//        policyProvider = PolicyProvider(service: testService)
//        subjectFactorProvider = SubjectFactorProvider(service: testService)
//        priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider, factorProvider: subjectFactorProvider, service: testService)
//        eventDriver = WeakManager<EventDriver>()
//        eventDriver.register(object: priorityProvider)
//        policyProvider.updatePolicyInfo()
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            eventDriver.sendEvent(event: .policyUpdate)
//        }
//        
//        expectation = XCTestExpectation(description: "testPolicyPriorityProvider 4")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            let data = priorityProvider.priorityData
//            XCTAssertNil(data)
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 4.0)
//    }
}
