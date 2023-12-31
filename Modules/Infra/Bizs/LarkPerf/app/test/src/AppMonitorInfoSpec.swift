//
//  AppMonitorInfoSpec.swift
//  LarkPerfDevEEUnitTest
//
//  Created by qihongye on 2020/6/24.
//

import UIKit
import Foundation
import XCTest

@testable import LarkPerf

class AppMonitorInfoSpec: XCTestCase {
    let startup = AppMonitor.initStartupTimeStamp()

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testAppMonitorStartup() throws {
        let b = AppMonitor.initStartupTimeStamp()
        XCTAssertEqual(AppMonitor.getStartupTimeStamp(), startup)
        XCTAssertNotEqual(AppMonitor.getStartupTimeStamp(), b)
        sleep(1)
        let time = AppMonitor.getMillisecondSinceStartup(CACurrentMediaTime() * 1_000)
        print(time)
        XCTAssertTrue(time > 1_000, "\(time) > 1000")
    }

    func testAppMonitorEnterForeground() throws {
        var current = CACurrentMediaTime() * 1_000
        XCTAssertEqual(AppMonitor.getMillisecondSinceForeground(current), AppMonitor.getMillisecondSinceStartup(current))
        AppMonitor.applicationWillEnterForeground()
        sleep(1)
        current = CACurrentMediaTime() * 1_000
        let time = AppMonitor.getMillisecondSinceForeground(CACurrentMediaTime() * 1_000)
        print(time)
        XCTAssertTrue(time > 1_000, "\(time) > 1000")
    }

    let perfCount = 1_000_000
    func testPerformanceGetTime1() throws {
        // This is an example of a performance test case.
        var a: Double = 0
        self.measure {
            for _ in 0..<perfCount {
                a = Double(clock_gettime_nsec_np(CLOCK_UPTIME_RAW) / 1_000)
            }
        }
    }

    func testPerformanceGetTime2() throws {
        // This is an example of a performance test case.
        var a: Double = 0
        self.measure {
            for _ in 0..<perfCount {
                a = CACurrentMediaTime() * 1_000
            }
        }
    }

}
