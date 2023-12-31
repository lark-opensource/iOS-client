//
//  Utils+DeviceSpec.swift
//  LarkFoundationDevEEUnitTest
//
//  Created by qihongye on 2020/3/8.
//

import Foundation
import XCTest

@testable import LarkFoundation

class Utils_DeviceSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUtilsDevice() {
        XCTAssertEqual(Utils.isSimulator, true)
        XCTAssertEqual(Utils.cameraPermissions(), true)
        XCTAssertEqual("<a>html</a>".lf.matchingStrings(regex: "<a>(\\w+)</a>"), [["<a>html</a>", "html"]])
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testiOSOnMacFunction() {
        XCTAssertFalse(Utils.isMacCatalystApp)
        XCTAssertFalse(Utils.isiOSAppOnMac)
        XCTAssertFalse(Utils.isiOSAppOnMacSystem)
    }

}
