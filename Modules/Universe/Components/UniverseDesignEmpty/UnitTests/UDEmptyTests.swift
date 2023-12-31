//
//  UDDialogTests.swift
//  UniverseDesignDialogTests
//
//  Created by 王元洵 on 2020/11/18.
//

import Foundation
import XCTest
@testable import UniverseDesignEmpty
import UniverseDesignColor

class UDEmptyTests: XCTestCase {
    let empty = UDEmpty(config: .init(title: .init(titleText: "a title"),
                                      description: .init(descriptionText: "a descripiton"),
                                      range: NSRange(location: 0, length: 1),
                                      imageSize: 200,
                                      spaceBelowImage: 10,
                                      spaceBelowTitle: 20,
                                      spaceBelowDescription: 30,
                                      spaceBetweenButtons: 40,
                                      type: .PIN,
                                      labelHandler: {},
                                      primaryButtonConfig: ("primary1", {}),
                                      secondaryButtonConfig: ("secondary1", {})))

    ///测试update接口
    func testEmptyUpdate() {
        empty.update(config: .init(title: .init(titleText: "another title"),
                                   description: .init(descriptionText: "another descripiton"),
                                   range: NSRange(location: 1, length: 2),
                                   imageSize: 300,
                                   spaceBelowImage: 15,
                                   spaceBelowTitle: 25,
                                   spaceBelowDescription: 35,
                                   spaceBetweenButtons: 45,
                                   type: .noFile,
                                   labelHandler: nil,
                                   primaryButtonConfig: nil,
                                   secondaryButtonConfig: nil))

        XCTAssertEqual(empty.titleLabel.text, "another title")
        XCTAssertEqual(empty.descriptionLabel.text, "another descripiton")
        XCTAssertEqual(empty.config.imageSize, 300)
        XCTAssertEqual(empty.config.spaceBelowImage, 15)
        XCTAssertEqual(empty.config.spaceBelowTitle, 25)
        XCTAssertEqual(empty.config.spaceBelowDescription, 35)
        XCTAssertEqual(empty.config.spaceBetweenButtons, 45)
        XCTAssertEqual(empty.config.type, .noFile)
        XCTAssertNil(empty.config.labelHandler)
        XCTAssertNil(empty.config.primaryButtonConfig)
        XCTAssertNil(empty.config.secondaryButtonConfig)
    }
}

