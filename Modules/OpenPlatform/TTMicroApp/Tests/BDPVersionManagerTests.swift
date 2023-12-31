//
//  BDPVersionManagerTests.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/7/12.
//

import Foundation
import XCTest
import TTMicroApp
import LarkContainer
import OPSDK


class BDPVersionManagerTests: XCTestCase {
    override class func setUp() {
        OPApplicationService.setupGlobalConfig(accountConfig:
                                                OPAppAccountConfig(userSession: "", accountToken: "", userID: "", tenantID: ""),
                                               envConfig: OPAppEnvironment(envType: .online, larkVersion: "5.18", language: ""),
                                               domainConfig: OPAppDomainConfig(openDomain: "", configDomain: "", pstatpDomain: "", vodDomain: "", snssdkDomain: "", referDomain: "", appLinkDomain: "", openAppInterface: "", webViewSafeDomain: ""),
                                               resolver: implicitResolver)
    }

    func testInValidLarkVersion() {
        let invalidLarkVersionArray = ["a", "a.b.c", "%$", " ", "5", "5.", "5.18.", "5.18.4.", "5.18.0.0", "5.18.0-alpha1", "5.18.0-beta", "5.18.0-gama", "5.18.0-alpha", " 5.18.0", "5.18.0 "]

        let matchVersion = invalidLarkVersionArray.first(where: { version in
            BDPVersionManager.isValidLarkVersion(version)
        })

        XCTAssertNil(matchVersion, "\(String(describing: matchVersion)) should be invalid, but now is valid")
    }

    func testValidLarkVersion() {
        let validLarkVersionArray = ["5.18", "5.18.0", "10.18", "10.18.0"]

        let matchVersion = validLarkVersionArray.first { version in
            !BDPVersionManager.isValidLarkVersion(version)
        }

        XCTAssertNil(matchVersion, "\(String(describing: matchVersion)) should be valid, but now is invalid")
    }

    func testLocalLarkVersionCorrect() {
        XCTAssert(BDPVersionManager.isValidLocalLarkVersion(), "local lark version is invalid")
    }

    func testLocalLarkVersionIsHigher() {
        let lowerMetaLarkVersion = ["5.1", "5.1.5", "5.15", "5.15.0", "5.15.5", "5", "5.1.0-apha", "5.17"]

        let matchVersion = lowerMetaLarkVersion.first { version in
            BDPVersionManager.isLocalLarkVersionLowerThanVersion(version)
        }

        XCTAssertNil(matchVersion, "\(String(describing: matchVersion)) should be lower than local version, but now is higher")
    }


    func testLocalLarkVersionIsLower() {
        let higherMetaLarkVersion = ["5.19", "5.19.0", "5.20", "5.20.5"]
        let matchVersion = higherMetaLarkVersion.first { version in
            !BDPVersionManager.isLocalLarkVersionLowerThanVersion(version)
        }

        XCTAssertNil(matchVersion, "\(String(describing: matchVersion)) should be higher than local version, but now is lower")
    }
}

