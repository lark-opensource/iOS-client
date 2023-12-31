//
//  OPGadgetDegradeTests.swift
//  OPGadget-Unit-Tests
//
//  Created by laisanpin on 2023/2/28.
//

import Foundation
import XCTest
import OPSDK
import LarkContainer

@testable import OPGadget

class OPVersionRangeTestCase: XCTestCase {
    func test_version_inRange() {
        // Arrange
        let range = OPVersionRange(maxVersion: "1.1.2", minVersion: "1.0.0")
        let version = "1.0.5"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_version_inRange_1_0() {
        // Arrange
        let range = OPVersionRange(maxVersion: "1.1.2", minVersion: "1.0.0")
        let version = "1.0"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_version_inRange_1_0_5() {
        // Arrange
        let range = OPVersionRange(maxVersion: "1.1", minVersion: "1.0")
        let version = "1.0.5"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_version_outRange() {
        // Arrange
        let range = OPVersionRange(maxVersion: "1.1.2", minVersion: "1.0.0")
        let version = "2.0.5"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func test_version_emptyVersion() {
        // Arrange
        let range = OPVersionRange(maxVersion: nil, minVersion: nil)
        let version = "2.0.5"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_version_invalidVersion() {
        // Arrange
        let range = OPVersionRange(maxVersion: "2.0.a", minVersion: "a.b.c")
        let version = "2.0.5"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_version_reverseVersion() {
        // Arrange
        let range = OPVersionRange(maxVersion: "1.0.0", minVersion: "2.0.7")
        let version = "2.0.5"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func test_vesion_minVersionOutRange() {
        // Arrange
        let range = OPVersionRange(maxVersion: nil, minVersion: "1.1.0")
        let version = "1.0.5"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func test_vesion_minVersionInRange() {
        // Arrange
        let range = OPVersionRange(maxVersion: nil, minVersion: "0.0.1")
        let version = "1.0.1"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_vesion_maxVersionOutRange() {
        // Arrange
        let range = OPVersionRange(maxVersion: "1.0.1", minVersion: nil)
        let version = "1.0.5"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func test_vesion_maxVersionInRange() {
        // Arrange
        let range = OPVersionRange(maxVersion: "1.0.1", minVersion: nil)
        let version = "1.0.1"
        
        // Act
        let result = range.versionInRange(version)
        
        // Assert
        XCTAssertTrue(result)
    }
}


class OPGadgetDegradeConfigTestCase: XCTestCase {
    
    override class func setUp() {
        OPApplicationService.setupGlobalConfig(accountConfig:
                                                OPAppAccountConfig(userSession: "", accountToken: "", userID: "", tenantID: ""),
                                               envConfig: OPAppEnvironment(envType: .online, larkVersion: "5.18", language: ""),
                                               domainConfig: OPAppDomainConfig(openDomain: "", configDomain: "", pstatpDomain: "", vodDomain: "", snssdkDomain: "", referDomain: "", appLinkDomain: "", openAppInterface: "", webViewSafeDomain: ""),
                                               resolver: implicitResolver)
    }
    
    func test_degrade_enable() {
        // Arrange
        let mockSettings: [String : Any] = [
            "front_effect_condition": [
                "degrade_link": "https://oa.feishu-boe.cn/attendance/demotion"
            ],
            "is_open": true
        ]
        
        let degradeConfig = OPGadgetDegradeConfig(settings: mockSettings, appID: "cli_mock", tenantID: "1", userID: "12")
        
        // Act
        let result = degradeConfig.degradeEnable()
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_degrade_notEnable() {
        // Arrange
        let mockSettings: [String : Any] = [
            "front_effect_condition": [
                "degrade_link": "https://oa.feishu-boe.cn/attendance/demotion"
            ],
            "is_open": false
        ]
        
        let degradeConfig = OPGadgetDegradeConfig(settings: mockSettings, appID: "cli_mock", tenantID: "1", userID: "12")
        
        // Act
        let result = degradeConfig.degradeEnable()
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func test_degrade_inBlackTenants() {
        // Arrange
        let mockSettings: [String : Any] = [
            "front_effect_condition": [
                "black_tenant_ids": ["2"],
                "white_tenant_ids": ["3", "2", "1"],
                "white_user_ids": ["12345", "12"],
                "degrade_link": "https://oa.feishu-boe.cn/attendance/demotion"
            ],
            "is_open": false
        ]
        
        let degradeConfig = OPGadgetDegradeConfig(settings: mockSettings, appID: "cli_mock", tenantID: "2", userID: "12")
        
        // Act
        let result = degradeConfig.degradeEnable()
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func test_degrade_inWhiteTenants() {
        // Arrange
        let mockSettings: [String : Any] = [
            "front_effect_condition": [
                "black_tenant_ids": ["2"],
                "white_tenant_ids": ["3", "1"],
                "degrade_link": "https://oa.feishu-boe.cn/attendance/demotion"
            ],
            "is_open": true
        ]
        
        let degradeConfig = OPGadgetDegradeConfig(settings: mockSettings, appID: "cli_mock", tenantID: "1", userID: "12")
        
        // Act
        let result = degradeConfig.degradeEnable()
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_degrade_inBlackUsers() {
        // Arrange
        let mockSettings: [String : Any] = [
            "front_effect_condition": [
                "white_user_ids": ["12345", "12"],
                "black_user_ids": ["12", "3"],
                "degrade_link": "https://oa.feishu-boe.cn/attendance/demotion"
            ],
            "is_open": true
        ]
        
        let degradeConfig = OPGadgetDegradeConfig(settings: mockSettings, appID: "cli_mock", tenantID: "1", userID: "12")
        
        // Act
        let result = degradeConfig.degradeEnable()
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func test_degrade_inWhiteUsers() {
        // Arrange
        let mockSettings: [String : Any] = [
            "front_effect_condition": [
                "white_user_ids": ["12345", "12"],
                "black_user_ids": ["12", "3"],
                "degrade_link": "https://oa.feishu-boe.cn/attendance/demotion"
            ],
            "is_open": true
        ]
        
        let degradeConfig = OPGadgetDegradeConfig(settings: mockSettings, appID: "cli_mock", tenantID: "1", userID: "12345")
        
        // Act
        let result = degradeConfig.degradeEnable()
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func test_degrade_sameSSLocalLink() {
        // Arrange
        let mockSettings: [String : Any] = [
            "front_effect_condition": [
                "degrade_link": "sslocal://microapp?app_id=cli_mock"
            ],
            "is_open": true
        ]
        
        let degradeConfig = OPGadgetDegradeConfig(settings: mockSettings, appID: "cli_mock", tenantID: "1", userID: "12345")
        
        // Act
        let result = degradeConfig.degradeEnable()
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func test_degrade_h5Link() {
        // Arrange
        let mockSettings: [String : Any] = [
            "front_effect_condition": [
                "degrade_link": "https://oa.feishu-boe.cn/attendance/demotion"
            ],
            "is_open": true
        ]
        
        let degradeConfig = OPGadgetDegradeConfig(settings: mockSettings, appID: "cli_mock", tenantID: "1", userID: "12345")
        
        // Act
        let result = degradeConfig.degradeEnable()
        
        // Assert
        XCTAssertTrue(result)
    }
}
