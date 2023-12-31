//
//  UDProgressViewTests.swift
//  UniversalDesignProgressViewTests
//
//  Created by CJ on 2020/11/19.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignProgressView
import UniverseDesignColor

class UDProgressViewTests: XCTestCase {

    let udProgressView: UDProgressView = UDProgressView()

    override class func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    /// Test Progress
    func testSetProgress() {
        udProgressView.setProgress(1, animated: true)
        XCTAssertEqual(udProgressView.progressingView.backgroundColor, UIColor.ud.B200)
        XCTAssertEqual(udProgressView.contentView.backgroundColor, UIColor.ud.N00)
    }
    /// Test Progress load failed
    func testSetProgressLoadFailed() {
        udProgressView.setProgressLoadFailed()
        XCTAssertEqual(udProgressView.progressingView.backgroundColor, UIColor.ud.B200)
        XCTAssertEqual(udProgressView.contentView.backgroundColor, UIColor.ud.N00)
    }
}
