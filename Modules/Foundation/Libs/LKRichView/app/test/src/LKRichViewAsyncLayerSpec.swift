//
//  LKRichViewAsyncLayerLayerSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2021/8/16.
//

import UIKit
import Foundation
import XCTest
@testable import LKRichView

class LKRichViewAsyncLayerSpec: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCALyaerAPIs() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let v = UIView()
        let l1 = CALayer()
        l1.name = "1"
        v.layer.insertSublayer(l1, below: nil)
        v.layer.insertSublayer(CALayer(), above: nil)
        let l2 = CALayer()
        l2.name = "2"
        v.layer.addSublayer(l2)
        let l3 = CALayer()
        l3.name = "3"
        v.layer.insertSublayer(l3, below: nil)
        let l4 = CALayer()
        l4.name = "4"
        v.layer.insertSublayer(l4, below: l2)
        let l5 = CALayer()
        l5.name = "5"
        v.layer.insertSublayer(l5, above: l2)

        let expect = ["3", "1", "", "4", "2", "5"]
        XCTAssertEqual((v.layer.sublayers ?? []).compactMap({ $0.name ?? "" }), expect, "")
    }

    func testLKRichViewTiledLayerAPIs() throws {
        let v = UIView()
        let l1 = LKRichViewAsyncLayer()
        l1.name = "1"
        v.layer.insertSublayer(l1, below: nil)
        v.layer.insertSublayer(CALayer(), above: nil)
        let l2 = CALayer()
        l2.name = "2"
        v.layer.addSublayer(l2)
        let l3 = CALayer()
        l3.name = "3"
        v.layer.insertSublayer(l3, below: nil)
        let l4 = CALayer()
        l4.name = "4"
        v.layer.insertSublayer(l4, below: l2)
        let l5 = CALayer()
        l5.name = "5"
        v.layer.insertSublayer(l5, above: l2)

        let expect = ["3", "1", "", "4", "2", "5"]
        XCTAssertEqual((v.layer.sublayers ?? []).compactMap({ $0.name ?? "" }), expect, "")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
