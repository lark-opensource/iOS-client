//
//  OPPluginBluetooth_ModelTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by zhaojingxin on 2023/12/20.
//

import XCTest
import CoreBluetooth
@testable import OPPlugin

final class OPPluginBluetooth_ModelTests: XCTestCase {
    
    func testCBCharacteristicPropertiesJSON() throws {
        let indicateCharacterModel = BluetoothDeviceCharacteristicModel(characteristicID: "1", serviceID: "2", hexValue: "3", operation: [.indicate, .read])
        let noIndicateCharacterModel = BluetoothDeviceCharacteristicModel(characteristicID: "1", serviceID: "2", hexValue: "3", operation: [.notify, .read])
        
        if let indicateProperties = indicateCharacterModel.toJSONDict()["properties"] as? [String: Any], let indicateValue1 = indicateProperties["isIndicate"] as? Bool, let indicateValue2 = indicateProperties["isIndicate"] as? Bool {
            XCTAssert(indicateValue1, "indicate value should be true")
            XCTAssert(indicateValue2, "isIndicate value should be true")
        } else {
            XCTFail("properties invalid")
        }
        
        if let noIndicateProperties = noIndicateCharacterModel.toJSONDict()["properties"] as? [String: Any], let indicateValue1 = noIndicateProperties["isIndicate"] as? Bool, let indicateValue2 = noIndicateProperties["isIndicate"] as? Bool {
            XCTAssert(!indicateValue1, "indicate value should be false")
            XCTAssert(!indicateValue2, "isIndicate value should be false")
        } else {
            XCTFail("properties invalid")
        }
    }
}
