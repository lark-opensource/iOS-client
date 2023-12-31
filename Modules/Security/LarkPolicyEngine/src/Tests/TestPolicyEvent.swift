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

class ObserverImp: Observer {
    var flag: Int

    init() {
        self.flag = 0
    }

    func notify(event: LarkPolicyEngine.Event) {
        flag = 1
    }
}

let observerImp = ObserverImp()

class TestPolicyEvent: XCTestCase, ProviderDelegate {
    func postOuterEvent(event: LarkPolicyEngine.Event) {
        
    }

    func postInnerEvent(event: LarkPolicyEngine.InnerEvent) {
        
    }

    func tenantHasDeployPolicy() -> Bool {
        true
    }

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
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testStorage.mmkv.removeAll()
    }

    func testInnerEvent() {
        let eventDriver = WeakManager<EventDriver>()
        // 策略信息事件响应
        testStorage.mmkv.removeAll()
        let policyProvider = PolicyProvider(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))

        policyProvider.delegate = self
        eventDriver.register(object: policyProvider)
        eventDriver.sendEvent(event: .initCompletion)
        var expectation = XCTestExpectation(description: "sendEvent")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertNotNil(self.testStorage.mmkv[policyEntityInfoCacheKey])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)

        // 快速剪枝事件响应
        testStorage.mmkv.removeAll()
        let fastPassInfoProvider = FastPassInfoProvider(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))

        eventDriver.register(object: fastPassInfoProvider)
        eventDriver.sendEvent(event: .initCompletion)
        expectation = XCTestExpectation(description: "sendEvent 2")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertNotNil(self.testStorage.mmkv["FastPassConfigCacheKey"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)

        // 切点信息事件响应
        testStorage.mmkv.removeAll()
        let pointCutProvider = PointCutProvider(service: TestSnCService(client: TestHTTPClient(),
                                                                storage: testStorage,
                                                                logger: TestLogger(),
                                                                monitor: TestMonitor(),
                                                                settings: TestSettings(),
                                                                environment: TestEnvironment()))

        eventDriver.register(object: pointCutProvider)
        // 重复注册
        eventDriver.register(object: pointCutProvider)
        eventDriver.sendEvent(event: .initCompletion)
        expectation = XCTestExpectation(description: "sendEvent 3")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertNotNil(self.testStorage.mmkv["PointCutInfoCacheKey"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        eventDriver.remove(object: pointCutProvider)
    }

    func testOuterEvent() {
        let observerManager = WeakManager<Observer>()
        let expectation = XCTestExpectation(description: "sendEvent")
        observerManager.register(object: observerImp)
        // 重复注册
        observerManager.register(object: observerImp)
        observerManager.sendEvent(event: .decisionContextChanged)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(observerImp.flag, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        observerManager.remove(object: observerImp)
        // 重复移除
        observerManager.remove(object: observerImp)
    }

}
