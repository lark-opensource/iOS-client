//
//  OPPluginUserLoginTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/20.
//

import XCTest
import Foundation
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
import LarkOpenAPIModel
//@testable  import ECOInfra
@testable import OPPlugin
import OPUnitTestFoundation
import LarkAccountInterface
@available(iOS 13.0, *)
class OPPluginUserLoginTests: XCTestCase {
    private let task = BDPTask()
    @Provider var ecoService: ECONetworkService
    var testUtils = OpenPluginGadgetTestUtils()
    override func setUpWithError() throws {
        let assemblies: [LarkAssemblyInterface] = [
            OPECONetworkServiceMockAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().generateTracing(by: testUtils.uniqueID)
        BDPTaskManager.shared().add(task, uniqueID: testUtils.uniqueID)
    }

    override func tearDownWithError() throws {
        let assemblies: [LarkAssemblyInterface] = [
            ECONetworkAssembly()
        ]
        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }
        BDPTracingManager.sharedInstance().clearAllTracing()
        BDPTaskManager.shared().removeTask(with: testUtils.uniqueID)
    }
    var mockService: OPMockECONetworkService? {
        return ecoService as? OPMockECONetworkService
    }
    
    let semaphore = DispatchSemaphore(value: 1)
    //MARK: - test_login_success
    func test_login_success() {
        semaphore.wait()
        let exp = XCTestExpectation(description: #function)
        OpenPluginUser.mockSession = "mockSession"
        OpenPluginUser.mockUpdateSessionSuccess = true
        var response = OPenAPINetworkLoginModel.init(errorCode: 0, session: "session", message: "message", data: OPenAPINetworkLoginModel.Data.init(code: "0"), autoConfirm: false, scope: "")
        mockService?.mockResult = (response, nil)
        testUtils.asyncCall(apiName: "login", params: [:]) { [unowned self] result in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            case .success(_):
                break
            case .continue( _, _):
                XCTFail("should not be continue!")
            @unknown default:
                XCTFail("should not be default!")
            }
            exp.fulfill()
            OpenPluginUser.mockSession = nil
            OpenPluginUser.mockUpdateSessionSuccess = nil
            self.mockService?.mockResult = nil
        }
        wait(for: [exp], timeout: 10)
        OpenPluginUser.mockUpdateSessionSuccess = nil
        OpenPluginUser.mockSession = nil
        mockService?.mockResult = nil
        semaphore.signal()
    }
    //MARK: - test_login_sandBox_failed
    func test_login_sandBox_failed() {
        semaphore.wait()
        let exp = XCTestExpectation(description: #function)
        OpenPluginUser.mockSession = "mockSession"
        OpenPluginUser.mockUpdateSessionSuccess = false
        mockService?.mockResult = (nil, nil)
        testUtils.asyncCall(apiName: "login", params: [:]) { [unowned self] result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue ?? 0, OpenAPICommonErrorCode.internalError.rawValue)
            case .success(_):
                XCTFail("should not be success!")
            case .continue( _, _):
                XCTFail("should not be continue!")
            @unknown default:
                XCTFail("should not be default!")
            }
            exp.fulfill()
            OpenPluginUser.mockSession = nil
            OpenPluginUser.mockUpdateSessionSuccess = nil
            self.mockService?.mockResult = nil
        }
        wait(for: [exp], timeout: 10)
        OpenPluginUser.mockUpdateSessionSuccess = nil
        OpenPluginUser.mockSession = nil
        mockService?.mockResult = nil
        semaphore.signal()
    }
    // MARK: - test_login_network_failed
    func test_login_network_failed() {
        semaphore.wait()
        let exp = XCTestExpectation(description: #function)
        OpenPluginUser.mockSession = "mockSession"
        OpenPluginUser.mockUpdateSessionSuccess = true
        var response = OPenAPINetworkLoginModel(errorCode: 0, session: nil, message: "message", data: OPenAPINetworkLoginModel.Data.init(code: "0"), autoConfirm: false, scope: "")
        mockService?.mockResult = (response, nil)
        testUtils.asyncCall(apiName: "login", params: [:]) { [unowned self] result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error.errnoError?.errnoValue ?? 0, OpenAPILoginErrno.serverError.errno())
            case .success(_):
                XCTFail("should not be success!")
            case .continue( _, _):
                XCTFail("should not be continue!")
            @unknown default:
                XCTFail("should not be default!")
            }
            exp.fulfill()
            OpenPluginUser.mockSession = nil
            OpenPluginUser.mockUpdateSessionSuccess = nil
            self.mockService?.mockResult = nil
        }
        wait(for: [exp], timeout: 10)
        OpenPluginUser.mockUpdateSessionSuccess = nil
        OpenPluginUser.mockSession = nil
        mockService?.mockResult = nil
        semaphore.signal()
    }
    
}

