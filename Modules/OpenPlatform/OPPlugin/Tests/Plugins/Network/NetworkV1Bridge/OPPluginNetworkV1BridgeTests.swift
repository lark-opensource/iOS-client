//
//  OPPluginNetworkV1BridgeTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/10.
//

import XCTest
import OCMock
import LarkOpenAPIModel
import OPUnitTestFoundation
@testable import OPPlugin

@available(iOS 13.0, *)
final class OPPluginNetworkV1BridgeTests: OpenPluginNetworkTests {
    
//    private var testInstance: OCMockObject?
//    private var authTestInstance: OCMockObject?
//    private let auth = BDPAuthorization()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
//        authTestInstance = OCMockAssistant.mock_BDPAuthorization_checkAuthorizationURL_authType(auth)
//
//        testInstance = OCMockAssistant.mock_BDPCommonManager_getCommon(uniqueID_withblock: {
//            let common = BDPCommon()
//            common.auth = self.auth
//            return common
//        })
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
//        testInstance?.stopMocking()
//        authTestInstance?.stopMocking()
    }
    
    override var configFileName: String { "networkV1Bridge" }

    func test_createRequestTask_success() throws {
        let params = try getParamsDictionary(key: #function)
        let response = testUtils.syncCall(apiName: OpenPluginNetworkV1Bridge.SyncAPI.createRequestTask.rawValue, params: params)
        switch response {
        case .success(data: _):
            XCTAssertTrue(true)
        case .failure(error: let error):
            // 调通即可
            XCTAssertTrue(true, error.description)
        default:
            break
        }
    }
    
    func test_createUploadTask_success() throws {
        let params = try getParamsDictionary(key: #function)
        let response = testUtils.syncCall(apiName: OpenPluginNetworkV1Bridge.SyncAPI.createUploadTask.rawValue, params: params)
        switch response {
        case .success(data: _):
            XCTAssertTrue(true)
        case .failure(error: let error):
            // 调通即可
            XCTAssertTrue(true, error.description)
        default:
            break
        }
    }
    
    func test_createDownloadTask_success() throws {
        let params = try getParamsDictionary(key: #function)
        let response = testUtils.syncCall(apiName: OpenPluginNetworkV1Bridge.SyncAPI.createDownloadTask.rawValue, params: params)
        switch response {
        case .success(data: _):
            XCTAssertTrue(true)
        case .failure(error: let error):
            // 调通即可
            XCTAssertTrue(true, error.description)
        default:
            break
        }
    }
    
    func test_createSocketTask_success() throws {
        let params = try getParamsDictionary(key: #function)
        let response = testUtils.syncCall(apiName: OpenPluginNetworkV1Bridge.SyncAPI.createSocketTask.rawValue, params: params)
        switch response {
        case .success(data: _):
            XCTAssertTrue(true)
        case .failure(error: let error):
            // 调通即可
            XCTAssertTrue(true, error.description)
        default:
            break
        }
    }
    
    func test_operateSocketTask_success() throws {
        let params = try getParamsDictionary(key: #function)
        let response = testUtils.syncCall(apiName: OpenPluginNetworkV1Bridge.SyncAPI.operateSocketTask.rawValue, params: params)
        switch response {
        case .success(data: _):
            XCTAssertTrue(true)
        case .failure(error: let error):
            // 调通即可
            XCTAssertTrue(true, error.description)
        default:
            break
        }
    }
    
    func test_operateRequestTask_success() throws {
        let abortParams = [
            "operationType": "abort",
            "requestTaskId": 123,
        ] as [String : Any]
        let exp = XCTestExpectation(description: "async")
        testUtils.asyncCall(apiName: OpenPluginNetworkV1Bridge.AsyncAPI.operateRequestTask.rawValue, params: abortParams) { result in
            exp.fulfill()
            switch result {
            case .success(let data):
                XCTAssertTrue(true, "\(String(describing: data))")
            case .failure(error: let error):
                XCTAssertTrue(true, error.description)
            default:
                XCTFail("operateRequestTask callback is not success either failed!")
                break
            }
        }
        wait(for: [exp], timeout: 2)
    }
}
