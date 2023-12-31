//
//  StyleTest.swift
//  LarkTagDevEEUnitTest
//
//  Created by Crazy凡 on 2020/2/19.
//

import UIKit
import Foundation
import XCTest
@testable import LarkTag
@testable import UniverseDesignColor

extension Style: Equatable {
    public static func == (lhs: Style, rhs: Style) -> Bool {
        lhs.textColor.hex8 == rhs.textColor.hex8 && lhs.backColor.hex8 == rhs.backColor.hex8
    }
}

class StyleTest: XCTestCase {
    func testInit() {
        XCTAssertEqual(Style.clear, .init(textColor: UIColor.clear, backColor: UIColor.clear))

        XCTAssertEqual(Style.blue, .init(textColor: UIColor.ud.udtokenTagTextSBlue, backColor: UIColor.ud.udtokenTagBgBlue))

        XCTAssertEqual(Style.purple, .init(textColor: UIColor.ud.udtokenTagTextSPurple, backColor: UIColor.ud.udtokenTagBgPurple))

        XCTAssertEqual(Style.orange, .init(textColor: UIColor.ud.udtokenTagTextSRed, backColor: UIColor.ud.udtokenTagBgRed))

        XCTAssertEqual(Style.red, .init(textColor: UIColor.ud.udtokenTagTextSRed, backColor: UIColor.ud.udtokenTagBgRed))

        XCTAssertEqual(Style.yellow, .init(textColor: UIColor.ud.udtokenTagTextSYellow, backColor: UIColor.ud.udtokenTagBgYellow))

        XCTAssertEqual(Style.darkGrey, .init(textColor: UIColor.ud.udtokenTagNeutralTextInverse, backColor: UIColor.ud.udtokenTagNeutralBgInverse))

        XCTAssertEqual(Style.lightGrey, .init(textColor: UIColor.ud.udtokenTagNeutralTextNormal, backColor: UIColor.ud.udtokenTagNeutralBgNormal))

        XCTAssertEqual(Style.white, .init(textColor: UIColor.ud.primaryOnPrimaryFill, backColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.2)))

        XCTAssertEqual(Style.turquoise, .init(textColor: UIColor.ud.udtokenTagTextSTurquoise, backColor: UIColor.ud.udtokenTagBgTurquoise))

        XCTAssertEqual(Style.secretColor, .init(textColor: UIColor.ud.N700.nonDynamic, backColor: UIColor.white))

        XCTAssertEqual(Style.readColor, .init(textColor: UIColor.ud.udtokenTagTextSGreen, backColor: UIColor.ud.udtokenTagBgGreen))

        XCTAssertEqual(Style.unreadColor, .init(textColor: UIColor.ud.udtokenTagNeutralTextNormal, backColor: UIColor.ud.udtokenTagNeutralBgNormal))

        XCTAssertEqual(Style.adminColor, .init(textColor: UIColor.ud.udtokenTagTextSPurple, backColor: UIColor.ud.udtokenTagBgPurple))
    }

    func testColorWithAlpha() {
//        XCTAssertEqual(UIColor.white.withAlphaComponent(0.1), UIColor.white * 0.1)
    }
}
