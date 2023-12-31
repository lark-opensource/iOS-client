//
//  BrowserViewLifeCycleTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/4/8.
//  


import XCTest
@testable import SKCommon

class BrowserViewLifeCycleTests: XCTestCase {

    
    func testNotification() {
        let lifeCycle = BrowserViewLifeCycle()
        let disposeAble = lifeCycle.addLifeCycleNotification(level: .high, noti: {  stage in
            if case .browserDidAppear = stage {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        })
        lifeCycle.browserDidAppear()
        XCTAssertTrue(lifeCycle.notifications[.high]?.isEmpty == false)
        disposeAble.dispose()
        XCTAssertTrue(lifeCycle.notifications[.high]?.isEmpty == true)
    }

}
