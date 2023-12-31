//
//  DriveScrollTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by chensi(陈思) on 2022/9/21.
//  


import Foundation
import XCTest
@testable import SKDrive

class DriveScrollTests: XCTestCase {
    
    private let scrollView = UIScrollView(frame: .init(x: 0, y: 0, width: 50, height: 100))
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testScroll() {
        
        let scrollExpectation = XCTestExpectation(description: "scroll happend")
        let stopExpectation = XCTestExpectation(description: "stop happend")
        
        scrollView.setupScrollObserver(tolerance: 1, onStart: {
            scrollExpectation.fulfill()
        }, onStop: {
            stopExpectation.fulfill()
        })
        
        scrollView.setContentOffset(CGPoint(x: 0, y: 50), animated: true)
        
        wait(for: [scrollExpectation, stopExpectation], timeout: 1.5, enforceOrder: true)
    }

}
