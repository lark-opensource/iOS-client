//
//  OPPluginBluetoothTests.swift
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
import Swinject
@testable import OPPlugin
@testable import LarkOpenPluginManager
import OPUnitTestFoundation
@available(iOS 13.0, *)
class OPPluginBluetoothTests: XCTestCase {
    private let task = BDPTask()
    var testUtils = OpenPluginGadgetTestUtils()
    override func setUpWithError() throws {

        BDPTracingManager.sharedInstance().generateTracing(by: testUtils.uniqueID)
        BDPTaskManager.shared().add(task, uniqueID: testUtils.uniqueID)
    }

    override func tearDownWithError() throws {
    
        BDPTracingManager.sharedInstance().clearAllTracing()
        BDPTaskManager.shared().removeTask(with: testUtils.uniqueID)
    }
//    private cbManagerMock: any
    func test_openBluetoothAdapter_success() {
        let exp = XCTestExpectation(description: "openBluetoothAdapter2Async")
        testUtils.asyncCall(apiName: "openBluetoothAdapter", params: [:]) { [weak self] _ in
            XCTAssertNotNil(self)
            guard let self = self else { return }
            let bluetoothPlugin = self.testUtils.pluginManager.plugins["OPPlugin.OpenPluginBluetooth"] as? OPPlugin.OpenPluginBluetooth
            XCTAssertNotNil(bluetoothPlugin)
            let cbManager = bluetoothPlugin?.manager.centerManager
            XCTAssertNotNil(cbManager)
            guard let cbManager = cbManager else { return }
            var mock: AnyObject? = OCMockAssistant.mock_CBCentralManager_manager(cbManager, state: .poweredOn, isScanning: false) as AnyObject
            self.testUtils.asyncCall(apiName: "openBluetoothAdapter", params: [:]) { result in
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
                mock = nil
                exp.fulfill()
            }
            
        }
        wait(for: [exp], timeout: 10)
    }
    
    func test_openBluetoothAdapter_failed() {
        let exp = XCTestExpectation(description: "openBluetoothAdapter2Async")
        testUtils.asyncCall(apiName: "openBluetoothAdapter", params: [:]) { [weak self] _ in
            XCTAssertNotNil(self)
            guard let self = self else { return }
            let bluetoothPlugin = self.testUtils.pluginManager.plugins["OPPlugin.OpenPluginBluetooth"] as? OPPlugin.OpenPluginBluetooth
            XCTAssertNotNil(bluetoothPlugin)
            let cbManager = bluetoothPlugin?.manager.centerManager
            XCTAssertNotNil(cbManager)
            guard let cbManager = cbManager else { return }
            var mock: AnyObject? = OCMockAssistant.mock_CBCentralManager_manager(cbManager, state: .unknown, isScanning: false) as AnyObject
            self.testUtils.asyncCall(apiName: "openBluetoothAdapter", params: [:]) { result in
                switch result {
                case .failure(_):
                        break
                case .success(_):
                    XCTFail("should not be success!")
                case .continue( _, _):
                    XCTFail("should not be continue!")
                @unknown default:
                    XCTFail("should not be default!")
                }
                mock = nil
                exp.fulfill()
            }
            
        }
        wait(for: [exp], timeout: 10)
    }
    func test_startBluetoothDevicesDiscovery_success() {
        let exp = XCTestExpectation(description: "startBluetoothDevicesDiscovery2Async")
        testUtils.asyncCall(apiName: "openBluetoothAdapter", params: [:]) { [weak self] _ in
            XCTAssertNotNil(self)
            guard let self = self else { return }
            let bluetoothPlugin = self.testUtils.pluginManager.plugins["OPPlugin.OpenPluginBluetooth"] as? OPPlugin.OpenPluginBluetooth
            XCTAssertNotNil(bluetoothPlugin)
            let cbManager = bluetoothPlugin?.manager.centerManager
            XCTAssertNotNil(cbManager)
            guard let cbManager = cbManager else { return }
            var mock: AnyObject? = OCMockAssistant.mock_CBCentralManager_manager(cbManager, state: .poweredOn, isScanning: false) as AnyObject
            
            self.testUtils.asyncCall(apiName: "startBluetoothDevicesDiscovery", params: [:]) { result in
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
                mock = nil
                exp.fulfill()
            }
            
        }
        wait(for: [exp], timeout: 10)
    }
    
    
}

