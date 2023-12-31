//
//  UDBadgeTests.swift
//  UniverseDesignBadge-Unit-UnitTests
//
//  Created by Meng on 2020/11/30.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignBadge
import UniverseDesignIcon

class UDBadgeTests: XCTestCase {
    private let badge = UDBadge(config: .dot)

    override func setUp() {
        super.setUp()
    }

    func testDot() {
        badge.config.type = .dot
        badge.config.style = .dotBGRed
        badge.config.border = .none
        badge.config.borderStyle = .custom(.clear)
        badge.config.dotSize = .middle
        badge.config.anchor = .topRight
        badge.config.anchorType = .circle
        badge.config.anchorExtendType = .leading
        badge.config.anchorOffset = .zero
        badge.config.text = ""
        badge.config.showEmpty = false
        badge.config.number = 0
        badge.config.showZero = false
        badge.config.maxNumber = UDBadgeConfig.defaultMaxNumber
        badge.config.maxType = .ellipsis
        badge.config.contentStyle = .dotCharacterText
        badge.icon = nil

        XCTAssertEqual(badge.config.type, .dot)
        XCTAssertEqual(badge.config.style, .dotBGRed)
        XCTAssertEqual(badge.config.border, .none)
        XCTAssertEqual(badge.config.borderStyle, .custom(.clear))
        XCTAssertEqual(badge.config.dotSize, .middle)
        XCTAssertEqual(badge.config.anchor, .topRight)
        XCTAssertEqual(badge.config.anchorType, .circle)
        XCTAssertEqual(badge.config.anchorExtendType, .leading)
        XCTAssertEqual(badge.config.anchorOffset, .zero)
        XCTAssertEqual(badge.config.text, "")
        XCTAssertEqual(badge.config.showEmpty, false)
        XCTAssertEqual(badge.config.number, 0)
        XCTAssertEqual(badge.config.showZero, false)
        XCTAssertEqual(badge.config.maxNumber, UDBadgeConfig.defaultMaxNumber)
        XCTAssertEqual(badge.config.maxType, .ellipsis)
        XCTAssertEqual(badge.config.contentStyle, .dotCharacterText)
        XCTAssertEqual(badge.icon, nil)

        let oldRefreshId = badge.config.refreshId
        badge.config.style = .dotBGGrey
        XCTAssertNotEqual(oldRefreshId, badge.config.refreshId)
    }

    func testText() {
        badge.config.type = .text
        badge.config.style = .dotBGRed
        badge.config.border = .none
        badge.config.borderStyle = .custom(.clear)
        badge.config.dotSize = .small
        badge.config.anchor = .topLeft
        badge.config.anchorType = .rectangle
        badge.config.anchorExtendType = .trailing
        badge.config.anchorOffset = CGSize(width: 10.0, height: 10.0)
        badge.config.text = "text"
        badge.config.showEmpty = true
        badge.config.number = 0
        badge.config.showZero = false
        badge.config.maxNumber = UDBadgeConfig.defaultMaxNumber
        badge.config.maxType = .ellipsis
        badge.config.contentStyle = .dotCharacterText
        badge.icon = nil

        XCTAssertEqual(badge.config.type, .text)
        XCTAssertEqual(badge.config.style, .dotBGRed)
        XCTAssertEqual(badge.config.border, .none)
        XCTAssertEqual(badge.config.borderStyle, .custom(.clear))
        XCTAssertEqual(badge.config.dotSize, .small)
        XCTAssertEqual(badge.config.anchor, .topLeft)
        XCTAssertEqual(badge.config.anchorType, .rectangle)
        XCTAssertEqual(badge.config.anchorExtendType, .trailing)
        XCTAssertEqual(badge.config.anchorOffset, CGSize(width: 10.0, height: 10.0))
        XCTAssertEqual(badge.config.text, "text")
        XCTAssertEqual(badge.config.showEmpty, true)
        XCTAssertEqual(badge.config.number, 0)
        XCTAssertEqual(badge.config.showZero, false)
        XCTAssertEqual(badge.config.maxNumber, UDBadgeConfig.defaultMaxNumber)
        XCTAssertEqual(badge.config.maxType, .ellipsis)
        XCTAssertEqual(badge.config.contentStyle, .dotCharacterText)
        XCTAssertEqual(badge.icon, nil)

        let oldRefreshId = badge.config.refreshId
        badge.config.text = "newText"
        XCTAssertNotEqual(oldRefreshId, badge.config.refreshId)
    }

    func testNumber() {
        badge.config.type = .number
        badge.config.style = .dotBGRed
        badge.config.border = .outer
        badge.config.borderStyle = .custom(.systemRed)
        badge.config.dotSize = .small
        badge.config.anchor = .topLeft
        badge.config.anchorType = .rectangle
        badge.config.anchorExtendType = .trailing
        badge.config.anchorOffset = CGSize(width: 10.0, height: 10.0)
        badge.config.text = ""
        badge.config.showEmpty = false
        badge.config.number = 99
        badge.config.showZero = false
        badge.config.maxNumber = 999
        badge.config.maxType = .plus
        badge.config.contentStyle = .dotCharacterText
        badge.icon = nil

        XCTAssertEqual(badge.config.type, .number)
        XCTAssertEqual(badge.config.style, .dotBGRed)
        XCTAssertEqual(badge.config.border, .outer)
        XCTAssertEqual(badge.config.borderStyle, .custom(.systemRed))
        XCTAssertEqual(badge.config.dotSize, .small)
        XCTAssertEqual(badge.config.anchor, .topLeft)
        XCTAssertEqual(badge.config.anchorType, .rectangle)
        XCTAssertEqual(badge.config.anchorExtendType, .trailing)
        XCTAssertEqual(badge.config.anchorOffset, CGSize(width: 10.0, height: 10.0))
        XCTAssertEqual(badge.config.text, "text")
        XCTAssertEqual(badge.config.showEmpty, true)
        XCTAssertEqual(badge.config.number, 99)
        XCTAssertEqual(badge.config.showZero, false)
        XCTAssertEqual(badge.config.maxNumber, 999)
        XCTAssertEqual(badge.config.maxType, .plus)
        XCTAssertEqual(badge.config.contentStyle, .dotCharacterText)
        XCTAssertEqual(badge.icon, nil)

        let oldRefreshId = badge.config.refreshId
        badge.config.number = 9
        XCTAssertNotEqual(oldRefreshId, badge.config.refreshId)
    }

    func testIcon() {
        badge.config.type = .icon
        badge.config.style = .dotBGRed
        badge.config.border = .outer
        badge.config.borderStyle = .custom(.systemRed)
        badge.config.dotSize = .small
        badge.config.anchor = .topLeft
        badge.config.anchorType = .rectangle
        badge.config.anchorExtendType = .trailing
        badge.config.anchorOffset = CGSize(width: 10.0, height: 10.0)
        badge.config.text = ""
        badge.config.showEmpty = false
        badge.config.number = 0
        badge.config.showZero = false
        badge.config.maxNumber = UDBadgeConfig.defaultMaxNumber
        badge.config.maxType = .plus
        badge.config.contentStyle = .dotCharacterText
        badge.icon = UDIcon.addFilled

        XCTAssertEqual(badge.config.type, .icon)
        XCTAssertEqual(badge.config.style, .dotBGRed)
        XCTAssertEqual(badge.config.border, .outer)
        XCTAssertEqual(badge.config.borderStyle, .custom(.systemRed))
        XCTAssertEqual(badge.config.dotSize, .small)
        XCTAssertEqual(badge.config.anchor, .topLeft)
        XCTAssertEqual(badge.config.anchorType, .rectangle)
        XCTAssertEqual(badge.config.anchorExtendType, .trailing)
        XCTAssertEqual(badge.config.anchorOffset, CGSize(width: 10.0, height: 10.0))
        XCTAssertEqual(badge.config.text, "")
        XCTAssertEqual(badge.config.showEmpty, false)
        XCTAssertEqual(badge.config.number, 0)
        XCTAssertEqual(badge.config.showZero, false)
        XCTAssertEqual(badge.config.maxNumber, UDBadgeConfig.defaultMaxNumber)
        XCTAssertEqual(badge.config.maxType, .plus)
        XCTAssertEqual(badge.config.contentStyle, .dotCharacterText)
        XCTAssertEqual(badge.icon, UDIcon.addFilled)

        let oldRefreshId = badge.config.refreshId
        badge.config.icon = UDIcon.addOutlined
        XCTAssertNotEqual(oldRefreshId, badge.config.refreshId)
    }
}
