//
//  TestFactorProvider.swift
//  LarkPolicyEngine-Unit-Tests
//
//  Created by ByteDance on 2023/9/27.
//

import Foundation
@testable import LarkPolicyEngine
import LarkSnCService
import XCTest

let subjectFactorInfoCacheKey = "SubjectFactorInfoCacheKey"

struct SubjectFactorResponse: Codable {
    let commonFactorsMap: [String: FactorVal]?
    let groupIDList: [String]?
    let userDeptIDPaths: [[String]]?
    let userDeptIdsWithParent: [String]?
    
    enum CodingKeys: String, CodingKey {
        case commonFactorsMap
        case groupIDList = "USER_GROUP_IDS"
        case userDeptIDPaths = "USER_DEPT_ID_PATHS"
        case userDeptIdsWithParent = "USER_DEPT_IDS_WITH_PARENT"
    }
}

struct IPFactorInfoResponse: Codable {
    let sourceIP: String
    let sourceIPV4: String
    
    enum CodingKeys: String, CodingKey {
        case sourceIP = "SOURCE_IP"
        case sourceIPV4 = "SOURCE_IP_V4"
    }
}

let testSubjectFactorResponse = SubjectFactorResponse(commonFactorsMap: testCommonFactorsMap,
                                                      groupIDList: testGroupIDList,
                                                      userDeptIDPaths: testUserDeptIDPaths,
                                                      userDeptIdsWithParent: testUserDeptIdsWithParent)
let testCommonFactorsMap = [
    "DEVICE_OWNERSHIP": FactorVal(val: "Unknown", type: .STRING),
    "DEVICE_CREDIBILITY": FactorVal(val: "Unknown", type: .STRING),
    "BOOL_TEST": FactorVal(val: "yes", type: .BOOL),
    "FLOAT_TEST": FactorVal(val: "10", type: .FLOAT),
    "INT_TEST": FactorVal(val: "100", type: .INT),
    "UNKNOWN_TEST": FactorVal(val: "Unknown", type: .UNKNOWN)
]

let testGroupIDList = ["7291261268048543763"]

let testUserDeptIDPaths = [
    ["0"],
    ["0", "7291276489880764435", "7291276754474237972", "7291276855707959315"]
]

let testUserDeptIdsWithParent = ["0", "7291276855707959315", "7291276489880764435", "7291276754474237972"]

let testIPFactorInfoResponse = IPFactorInfoResponse(sourceIP: "10.0.0.1", sourceIPV4: "167772161")

class TestFactorProvider: XCTestCase {

    let testStorage = TestStorage()
    let testStorageFailure = TestStorageFailure()
    let testHttpClient = TestHTTPClient()
    let testSettings = TestSettings()
    let testEnvironment = TestEnvironment()
    let testHTTPClientCodeNotZero = TestHTTPClientCodeNotZero()
    let testHTTPClientFailure = TestHTTPClientFailure()
    let testEnvironmentDomainFailure = TestEnvironmentDomainFailure()

    override func setUpWithError() throws {
        testStorage.mmkv.removeAll()
        try? super.setUpWithError()
    }

    override func tearDownWithError() throws {
        testStorage.mmkv.removeAll()
        try? super.tearDownWithError()
    }

    func testSubjectFactor() throws {
        let testService = TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: testSettings, environment: testEnvironment)
        let testServiceCodeNotZero = TestSnCService(client: TestHTTPClientCodeNotZero(), storage: testStorage, settings: testSettings, environment: testEnvironment)
        let testServiceFailure = TestSnCService(client: TestHTTPClientFailure(), storage: testStorage, settings: testSettings, environment: testEnvironment)

        // 主体特征获取成功
        var subjectFactorProvider = SubjectFactorProvider(service: testService)
        subjectFactorProvider.fetchSubjectFactor()
        var expectation = XCTestExpectation(description: "fetchSubjectFactor")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let subjectInfo = self.testStorage.mmkv[subjectFactorInfoCacheKey] as? SubjectFactorModel
            let subjectDict = subjectFactorProvider.getSubjectFactorDict()
            XCTAssertNotNil(subjectInfo)
            XCTAssertTrue(subjectInfo?.groupIDList?.first == 7_291_261_268_048_543_763)
            XCTAssertTrue(subjectDict["BOOL_TEST"] as? Bool == true)
            XCTAssertTrue(subjectDict["FLOAT_TEST"] as? Float == 10)
            XCTAssertTrue(subjectDict["INT_TEST"] as? Int == 100)
            XCTAssertTrue(subjectDict["DEVICE_OWNERSHIP"] as? String == "Unknown")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
        
        // Code 非零
        testStorage.mmkv.removeAll()
        subjectFactorProvider = SubjectFactorProvider(service: testServiceCodeNotZero)
        subjectFactorProvider.fetchSubjectFactor()
        expectation = XCTestExpectation(description: "fetchSubjectFactor Code Not Zero")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let subjectInfo = self.testStorage.mmkv[subjectFactorInfoCacheKey] as? SubjectFactorModel
            XCTAssertNil(subjectInfo)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
        
        //  主体特征获取失败
        testStorage.mmkv.removeAll()
        subjectFactorProvider = SubjectFactorProvider(service: testServiceFailure)
        subjectFactorProvider.fetchSubjectFactor()
        expectation = XCTestExpectation(description: "fetchSubjectFactor ServiceFailure")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let subjectInfo = self.testStorage.mmkv[subjectFactorInfoCacheKey] as? SubjectFactorModel
            XCTAssertNil(subjectInfo)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testIPFactor() throws {
        let testService = TestSnCService(client: TestHTTPClient(), storage: testStorage, settings: testSettings, environment: testEnvironment)
        let testServiceCodeNotZero = TestSnCService(client: TestHTTPClientCodeNotZero(), storage: testStorage, settings: testSettings, environment: testEnvironment)
        let testServiceFailure = TestSnCService(client: TestHTTPClientFailure(), storage: testStorage, settings: testSettings, environment: testEnvironment)

        // IP 特征获取成功
        var ipFactorProvider = IPFactorProvider(service: testService)
        ipFactorProvider.fetchIPFactor()
        var expectation = XCTestExpectation(description: "fetchIPFactor")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let iPFactorDict = ipFactorProvider.getIPFactorDict()
            XCTAssertTrue(iPFactorDict["SOURCE_IP"] as? String == "10.0.0.1")
            XCTAssertTrue(iPFactorDict["SOURCE_IP_V4"] as? Int64 == 167_772_161)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
        
        // Code 非零
        testStorage.mmkv.removeAll()
        ipFactorProvider = IPFactorProvider(service: testServiceCodeNotZero)
        ipFactorProvider.fetchIPFactor()
        expectation = XCTestExpectation(description: "fetchIPFactor Code Not Zero")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let iPFactorDict = ipFactorProvider.getIPFactorDict()
            XCTAssertTrue(iPFactorDict.isEmpty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
        
        //  IP 特征获取失败
        testStorage.mmkv.removeAll()
        ipFactorProvider = IPFactorProvider(service: testServiceFailure)
        ipFactorProvider.fetchIPFactor()
        expectation = XCTestExpectation(description: "fetchIPFactor ServiceFailure")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let iPFactorDict = ipFactorProvider.getIPFactorDict()
            XCTAssertTrue(iPFactorDict.isEmpty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }
}
