//
//  OPPluginLocationGetLocationTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/16.
//

import XCTest
import LarkContainer
import LarkOpenAPIModel
import TTMicroApp
import LarkAssembler
import AppContainer
import LarkContainer
import ECOInfra
import TTMicroApp
import LarkCoreLocation
import Swinject
import OPPlugin
import OPUnitTestFoundation
@available(iOS 13.0, *)
final class OPPluginLocationGetLocationTests: XCTestCase {
    @Provider var locationAuth: LocationAuthorization
    let task = BDPTask()
    var testUtils = OpenPluginGadgetTestUtils()
    override func setUpWithError() throws {
        let assemblies: [LarkAssemblyInterface] = [
            OPSingleLocationTaskMockAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().generateTracing(by: testUtils.uniqueID)
        BDPTaskManager.shared().add(task, uniqueID: testUtils.uniqueID)
    }
    
    override func tearDownWithError() throws {
        let assemblies: [LarkAssemblyInterface] = [
            LarkCoreLocationAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().clearAllTracing()
        BDPTaskManager.shared().removeTask(with: testUtils.uniqueID)
        
    }
    
    
    func test_getLocationV2_success() throws {
        mockSingleLocationTaskResult = .success
        let exp = XCTestExpectation(description: "testGetLocationV2Async")
        testUtils.asyncCall(apiName: "getLocationV2", params: [:]) { response in
            switch response {
            case .failure(let error):
                XCTFail(error.description)
            case .success(_):
                break
            case .continue(_, _):
                XCTFail("should not continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_getLocationV2_failure_timeout() throws {
        mockSingleLocationTaskResult = .failed(LocationError(rawError: nil, errorCode: .timeout, message: ""))
        let exp = XCTestExpectation(description: "testGetLocationV2Async")
        testUtils.asyncCall(apiName: "getLocationV2", params: [:]) { response in
            switch response {
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue ?? 0, OpenAPILocationErrno.timeout.errno())
            case .success(_):
                XCTFail("should not success")
            case .continue(_, _):
                XCTFail("should not continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_getLocationV2_failure_authorization() throws {
        mockSingleLocationTaskResult = .failed(LocationError(rawError: nil, errorCode: .authorization, message: ""))
        let exp = XCTestExpectation(description: "testGetLocationV2Async")
        testUtils.asyncCall(apiName: "getLocationV2", params: [:]) { response in
            switch response {
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue ?? 0, OpenAPILocationErrno.locatingAuthorization.errno())
            case .success(_):
                XCTFail("should not success")
            case .continue(_, _):
                XCTFail("should not continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_getLocationV2_failure_locationUnknown() throws {
        mockSingleLocationTaskResult = .failed(LocationError(rawError: nil, errorCode: .locationUnknown, message: ""))
        let exp = XCTestExpectation(description: "testGetLocationV2Async")
        testUtils.asyncCall(apiName: "getLocationV2", params: [:]) { response in
            switch response {
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue ?? 0, OpenAPILocationErrno.locationFail.errno())
            case .success(_):
                XCTFail("should not success")
            case .continue(_, _):
                XCTFail("should not continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_getLocationV2_failure_network() throws {
        mockSingleLocationTaskResult = .failed(LocationError(rawError: nil, errorCode: .network, message: ""))
        let exp = XCTestExpectation(description: "testGetLocationV2Async")
        testUtils.asyncCall(apiName: "getLocationV2", params: [:]) { response in
            switch response {
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue ?? 0, OpenAPILocationErrno.network.errno())
            case .success(_):
                XCTFail("should not success")
            case .continue(_, _):
                XCTFail("should not continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_getLocationV2_failure_unkonw() throws {
        mockSingleLocationTaskResult = .failed(LocationError(rawError: nil, errorCode: .unknown, message: ""))
        let exp = XCTestExpectation(description: "testGetLocationV2Async")
        testUtils.asyncCall(apiName: "getLocationV2", params: [:]) { response in
            switch response {
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue ?? 0, OpenAPILocationErrno.locationFail.errno())
            case .success(_):
                XCTFail("should not success")
            case .continue(_, _):
                XCTFail("should not continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_getLocationV2_failure_riskOfFakeLocation() throws {
        mockSingleLocationTaskResult = .failed(LocationError(rawError: nil, errorCode: .riskOfFakeLocation, message: ""))
        let exp = XCTestExpectation(description: "testGetLocationV2Async")
        testUtils.asyncCall(apiName: "getLocationV2", params: [:]) { response in
            switch response {
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue ?? 0, OpenAPILocationErrno.locationFail.errno())
            case .success(_):
                XCTFail("should not success")
            case .continue(_, _):
                XCTFail("should not continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_getLocationV2_failure() throws {
        mockSingleLocationTaskResult = .failed(mockLocationError)
        let exp = XCTestExpectation(description: "testGetLocationV2Async")
        testUtils.asyncCall(apiName: "getLocationV2", params: [:]) { response in
            switch response {
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue ?? 0, OpenAPILocationErrno.timeout.errno())
            case .success(_):
                XCTFail("should not success")
            case .continue(_, _):
                XCTFail("should not continue")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
    
}
