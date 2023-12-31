//
//  DocGlobalTimerTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/9/27.
//  


import UIKit
@testable import SKCommon
import XCTest
import SKInfra

class DocGlobalTimerTests: XCTestCase {
    
    class TestObj: NSObject, DocTimerObserverProtocol {
        var destroy: (() -> Void)?
        
        var tiktoked = false
        deinit {
            destroy?()
        }
        
        var timeInterval: TimeInterval { return 30 }

        func tiktok() {
            tiktoked = true
        }
    }
    
    func testRelease() {
        var obj: TestObj? = TestObj()
        
        let expect = expectation(description: "test obj release")
        obj?.destroy = {
            expect.fulfill()
        }
        DocGlobalTimer.shared.add(observer: obj!)
        obj = nil
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
}
