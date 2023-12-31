//
//  PaddingUILabelTest.swift
//  LarkTagDevEEUnitTest
//
//  Created by Aslan on 2021/5/17.
//

import Foundation
import UIKit
import XCTest
@testable import LarkTag

class PaddingUILabelTest: XCTestCase {
    func testPaddingUILabel() {
        let label: PaddingUILabel = PaddingUILabel.init(frame: CGRect(x: 10, y: 10, width: 100, height: 100))
        label.cornerRadius = 3
        label.color = UIColor.black
        label.backgroundColor = UIColor.red
        label.paddingTop = 5
        label.paddingRight = 5
        label.paddingBottom = 5
        label.paddingLeft = 5
        label.drawText(in: CGRect(x: 10, y: 10, width: 100, height: 100))
        XCTAssertEqual(label.cornerRadius, 3)
        XCTAssertNotNil(label.backgroundColor)
        XCTAssertEqual(label.paddingTop, 5)
        XCTAssertEqual(label.paddingRight, 5)
        XCTAssertEqual(label.paddingBottom, 5)
        XCTAssertEqual(label.paddingLeft, 5)
        XCTAssertNotEqual(label.textRect(forBounds: CGRect(x: 20, y: 20, width: 120, height: 120), limitedToNumberOfLines: 4), CGRect.zero)
    }
}
