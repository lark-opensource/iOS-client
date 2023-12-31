//
//  BTStatisticFPSHelperTests.swift
//  SKBitable-Unit-Tests
//
//  Created by 刘焱龙 on 2023/12/2.
//

import XCTest
@testable import SKBitable
@testable import SKFoundation
import SKCommon

class BTStatisticFPSHelperTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.mobile.statistic_trace", value: true)
    }

    override func tearDown() {
        super.tearDown()
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.mobile.statistic_trace")
    }

    func testFPSAverageSuccess() {
        let fpsAverage = BTStatisticFPSHelper.getFPSAverage(fpsInfo: [1: 60, 2: 30])
        XCTAssertTrue(fpsAverage == 45)
    }

    func testDropFrameSuccess() {
        let dropStateRatio = BTStatisticFPSHelper.dropStateRatio(dropCountInfo: ["1": 3, "3": 4, "8": 9, "20": 1, "25": 1, "40": 3])
        XCTAssertTrue(dropStateRatio!.count > 0)
    }

    func testDropDurationSuccess() {
        let dropDurationRatio = BTStatisticFPSHelper.dropDurationRatio(dropDurationInfo: ["1": 3, "3": 4, "8": 9, "20": 1, "25": 1, "40": 3], hitchDuration: 123, duration: 1234)
        XCTAssertTrue(dropDurationRatio!.count > 0)
    }

    func testFPSAverageEmpty() {
        let fpsAverage = BTStatisticFPSHelper.getFPSAverage(fpsInfo: [:])
        XCTAssertTrue(fpsAverage == 0)
    }

    func testDropFrameEmpty() {
        let dropStateRatio = BTStatisticFPSHelper.dropStateRatio(dropCountInfo: [:])
        XCTAssertNil(dropStateRatio)
    }

    func testDropDurationEmpty() {
        let dropDurationRatio = BTStatisticFPSHelper.dropDurationRatio(dropDurationInfo: [:], hitchDuration: 123, duration: 1234)
        XCTAssertNil(dropDurationRatio)
    }

    func testFPSAverageExceed() {
        var info: [Int: Double] = [:]
        for i in 0..<70 {
            info[i] = Double(i)
        }
        let fpsAverage = BTStatisticFPSHelper.getFPSAverage(fpsInfo: info)
        XCTAssertTrue(fpsAverage == 0)
    }

    func testDropFrameExceed() {
        var info: [String: Int] = [:]
        for i in 0..<70 {
            info["\(i)"] = i
        }
        let dropStateRatio = BTStatisticFPSHelper.dropStateRatio(dropCountInfo: info)
        XCTAssertNil(dropStateRatio)
    }

    func testDropDurationExceed() {
        var info: [String: Double] = [:]
        for i in 0..<70 {
            info["\(i)"] = Double(i)
        }
        let dropDurationRatio = BTStatisticFPSHelper.dropDurationRatio(dropDurationInfo: info, hitchDuration: 123, duration: 1234)
        XCTAssertNil(dropDurationRatio)
    }

    func testDropFrameInvalid() {
        let dropStateRatio = BTStatisticFPSHelper.dropStateRatio(dropCountInfo: ["1": -1])
        XCTAssertNil(dropStateRatio)
    }

    func testDropDurationInvalid() {
        let dropDurationRatio = BTStatisticFPSHelper.dropDurationRatio(dropDurationInfo: ["1": -1], hitchDuration: 123, duration: 1234)
        XCTAssertTrue((dropDurationRatio!["drop3_dur_ratio"] as? Double) == 0)

        let dropDurationRatioInvalidDuration = BTStatisticFPSHelper.dropDurationRatio(dropDurationInfo: ["1": -1], hitchDuration: -1, duration: 1234)
        XCTAssertNil(dropDurationRatioInvalidDuration)
    }
}
