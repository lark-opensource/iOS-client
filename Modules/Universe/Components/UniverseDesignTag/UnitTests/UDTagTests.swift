//
//  UDDialogTests.swift
//  UniverseDesignDialogTests
//
//  Created by 王元洵 on 2020/11/18.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignTag
import UniverseDesignColor

class UDTagTests: XCTestCase {
    let tag = UDTag(text: "a tag", textConfig: .init(padding: .init(top: 1,
                                                                           left: 1,
                                                                           bottom: 1,
                                                                           right: 1),
                                                     font: .systemFont(ofSize: 12, weight: .medium),
                                                     cornerRadius: 2,
                                                     textAlignment: .center,
                                                     textColor: .clear,
                                                     backgroundColor: .clear,
                                                     height: 12,
                                                     maxLenth: 12))

    func testUpdateText() {
        tag.text = "another tag"
        XCTAssertEqual(tag.text, "another tag")
    }

    func testTransformToText() {
        tag.updateUI(textConfig: .init(padding: .init(top: 2,
                                                             left: 2,
                                                             bottom: 2,
                                                             right: 2),
                                       font: .systemFont(ofSize: 13, weight: .regular),
                                       cornerRadius: 3,
                                       textAlignment: .left,
                                       textColor: .blue,
                                       backgroundColor: .red,
                                       height: 15,
                                       maxLenth: 15))

        XCTAssertEqual(tag.label.padding.left, 2)
        XCTAssertEqual(tag.label.padding.right, 2)
        XCTAssertEqual(tag.label.padding.top, 2)
        XCTAssertEqual(tag.label.padding.bottom, 2)
        XCTAssertEqual(tag.label.font, .systemFont(ofSize: 13, weight: .regular))
        XCTAssertEqual(tag.label.layer.cornerRadius, 3)
        XCTAssertEqual(tag.label.textColor, .blue)
        XCTAssertEqual(tag.label.backgroundColor, .red)
        switch tag.config {
        case .text(let textConfig):
            XCTAssertEqual(textConfig.height, 15)
            XCTAssertLessThanOrEqual(textConfig.maxLenth ?? Int.max, 15)
        case .icon:
            XCTAssert(true)
        }
    }

    func testTransformToIcon() {
        tag.icon = UIImage()
        tag.updateUI(iconConfig: .init(cornerRadius: 4,
                                       iconColor: .brown,
                                       backgroundColor: .cyan,
                                       height: 20,
                                       iconSize: 20))

        XCTAssertEqual(tag.imageWrapperView.layer.cornerRadius, 4)
        XCTAssertEqual(tag.imageWrapperView.backgroundColor, .cyan)
        switch tag.config {
        case .icon(let iconConfig):
            XCTAssertEqual(iconConfig.height, 20)
            XCTAssertEqual(iconConfig.iconColor, .brown)
            XCTAssertEqual(iconConfig.iconSize, 20)
        case .text:
            XCTAssert(true)
        }
    }
}
