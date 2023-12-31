//
//  BDPVersionManagerTests.swift
//  OPSDKTest
//
//  Created by laisanpin on 2022/7/12.
//

import XCTest

@testable import OPSDK

class VersionHelperTests: XCTestCase {
    func test_compareVersionsGreater() {
        // Arrange
        let versionA = "5.22.0"
        let versionB = "5.21.1"

        // Act
        let result = VersionHelper.compareVersions(versionFirst: versionA, versionSecond: versionB)

        // Assert
        XCTAssertEqual(result, 1)
    }

    func test_compareVersionEqual() {
        // Arrange
        let versionA = "5.23.1"
        let versionB = "5.23.1"

        // Act
        let result = VersionHelper.compareVersions(versionFirst: versionA, versionSecond: versionB)

        // Assert
        XCTAssertEqual(result, 0)
    }

    func test_compareVersionsLessThan() {
        // Arrange
        let versionA = "5.20.0"
        let versionB = "5.21.1"

        // Act
        let result = VersionHelper.compareVersions(versionFirst: versionA, versionSecond: versionB)

        // Assert
        XCTAssertEqual(result, -1)
    }
}
