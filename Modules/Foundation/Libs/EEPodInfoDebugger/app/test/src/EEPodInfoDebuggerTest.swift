//
//  RepleacemeSpec.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import Foundation
import XCTest
import EEPodInfoDebugger

class EEPodInfoDebuggerTest: XCTestCase {

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let source = DebugPodInfoJsonDataSource()
        XCTAssertEqual(1, source.podInfoArray.count)

        let dataSource = DebugPodInfosDataSource()
        XCTAssertEqual(0, dataSource.podVersionInfos.count)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            _ = DebugPodInfoJsonDataSource()
        }
    }

}
