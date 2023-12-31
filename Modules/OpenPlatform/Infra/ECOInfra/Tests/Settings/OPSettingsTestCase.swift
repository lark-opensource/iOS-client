//
//  OPSettingsTestCase.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/9/21.
//

import XCTest
@testable import ECOInfra
@testable import LarkSetting

fileprivate enum OPSettingDefinition: String {
    
    static let key = "SettingKey"
    
    case notest = """
{}
"""
    
    case testCase1 = """
{
    "tag1": {},
    "from": "unit_test_1",
    "default": true
}
"""

    case testCase2 = """
{
    "tag1": {
        "default": true
    },
    "from": "unit_test_2",
    "default": false
}
"""

    case testCase3 = """
{
    "tag1": {
        "app_id": {
            "cli_abcd": {
                "default": true
            }
        },
        "default": false
    },
    "from": "unit_test_3",
    "default": false
}
"""
    
    case testCase4 = """
{
    "tag1": {
        "app_id": {
            "cli_abcd": {
                "default": true
            }
        },
        "app_type": {
            "gadget": true
        },
        "default": false
    },
    "from": "unit_test_4",
    "default": false
}
"""
    
    case testCase5 = """
{
    "tag1": {
        "app_id": {
            "cli_abcd": {
                "webapp": 5,
                "default": 4
            }
        },
        "app_type": {
            "gadget": 3
        },
        "default": 2
    },
    "from": "unit_test_5",
    "default": 1
}
"""
    
}

@available(iOS 13.0, *)
final class OPSettingsTestCase: XCTestCase {

    func testGlobalDefault() throws {
        register(setting: .testCase1)
        defer {
            unregister()
        }
        
        let settings = OPSettings(key: .make(userKeyLiteral: "SettingKey"), tag: "tag1", defaultValue: false)
        
        XCTAssert(settings.getValue() == true)
        
        XCTAssert(settings.getValue(appID: "testAppID") == true)
        
        XCTAssert(settings.getValue(appType: "testAppType") == true)
        
        XCTAssert(settings.getValue(appID: "testAppID", appType: "testAppType") == true)
    }

    func testTagDefault() throws {
        register(setting: .testCase2)
        defer {
            unregister()
        }
        
        let settings = OPSettings(key: .make(userKeyLiteral: "SettingKey"), tag: "tag1", defaultValue: false)
        
        XCTAssert(settings.getValue() == true)
        
        XCTAssert(settings.getValue(appID: "testAppID") == true)
        
        XCTAssert(settings.getValue(appType: "testAppType") == true)
        
        XCTAssert(settings.getValue(appID: "testAppID", appType: "testAppType") == true)
        
        let settings2 = OPSettings(key: .make(userKeyLiteral: "SettingKey"), tag: "tag2", defaultValue: false)
        
        XCTAssert(settings2.getValue() == false)
    }
    
    func testAppID() throws {
        register(setting: .testCase3)
        defer {
            unregister()
        }
        
        let settings = OPSettings(key: .make(userKeyLiteral: "SettingKey"), tag: "tag1", defaultValue: false)
        
        XCTAssert(settings.getValue() == false)
        
        XCTAssert(settings.getValue(appID: "cli_abcd") == true)
        
        XCTAssert(settings.getValue(appType: "testAppType") == false)
        
        XCTAssert(settings.getValue(appID: "cli_abcd", appType: "testAppType") == true)
        
        // 已经保存的结果
        XCTAssert(settings.getValue(appID: "cli_abcd") == true)
        
        let settings2 = OPSettings(key: .make(userKeyLiteral: "SettingKey"), tag: "tag2", defaultValue: false)
        
        XCTAssert(settings2.getValue() == false)
    }
    
    func testAppType() throws {
        register(setting: .testCase4)
        defer {
            unregister()
        }
        
        let settings = OPSettings(key: .make(userKeyLiteral: "SettingKey"), tag: "tag1", defaultValue: false)
        
        XCTAssert(settings.getValue() == false)
        
        XCTAssert(settings.getValue(appID: "cli_abcd") == true)
        
        XCTAssert(settings.getValue(appType: "gadget") == true)
        
        XCTAssert(settings.getValue(appType: "otherType") == false)
        
        XCTAssert(settings.getValue(appID: "cli_abcd", appType: "otherType") == true)
        
        XCTAssert(settings.getValue(appID: "cli_other", appType: "gadget") == true)
        
        // 已经保存的结果
        XCTAssert(settings.getValue(appID: "cli_other", appType: "gadget") == true)
        
        let settings2 = OPSettings(key: .make(userKeyLiteral: "SettingKey"), tag: "tag2", defaultValue: false)
        
        XCTAssert(settings2.getValue() == false)
    }
    
    func testNumberSetting() throws {
        register(setting: .testCase5)
        defer {
            unregister()
        }
        
        let settings = OPSettings(key: .make(userKeyLiteral: "SettingKey"), tag: "tag1", defaultValue: 0)
        
        XCTAssert(settings.getValue() == 2)
        
        XCTAssert(settings.getValue(appID: "cli_abcd") == 4)
        
        XCTAssert(settings.getValue(appType: "gadget") == 3)
        
        XCTAssert(settings.getValue(appType: "otherType") == 2)
        
        XCTAssert(settings.getValue(appID: "cli_abcd", appType: "otherType") == 4)
        
        XCTAssert(settings.getValue(appID: "cli_abcd", appType: "webapp") == 5)
        
        XCTAssert(settings.getValue(appID: "cli_other", appType: "gadget") == 3)
        
        // 已经保存的结果
        XCTAssert(settings.getValue(appID: "cli_other", appType: "gadget") == 3)
        
        let settings2 = OPSettings(key: .make(userKeyLiteral: "SettingKey"), tag: "tag2", defaultValue: 0)
        
        XCTAssert(settings2.getValue() == 1)
        
        let settings3 = OPSettings(key: .make(userKeyLiteral: "SettingKeyOther"), tag: "tag1", defaultValue: 0)
        
        XCTAssert(settings3.getValue() == 0)
    }

}


@available(iOS 13.0, *)
fileprivate extension OPSettingsTestCase {
    func register(setting: OPSettingDefinition) {
        let _ = try? SettingStorage.setting(with: SettingManager.currentChatterID(), and: "SettingKey")
        SettingStorage.updateSettingValue(setting.rawValue, with: SettingManager.currentChatterID(), and: OPSettingDefinition.key)
    }
    func unregister() {
        SettingStorage.updateSettingValue(OPSettingDefinition.notest.rawValue, with: SettingManager.currentChatterID(), and: OPSettingDefinition.key)
    }
}
