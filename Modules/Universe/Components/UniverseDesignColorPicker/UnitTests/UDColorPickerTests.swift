//
//  UDColorPickerTests.swift
//  UniverseDesignToastTests
//
//  Created by panzaofeng on 2020/11/17.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignColorPicker

class UDColorPickerTests: XCTestCase {

    var colorPicker: UDColorPickerPanel?

    override func setUp() {
        super.setUp()
        let model1 = UDColorPickerConfig.defaultModel(category: .basic, title: "选择颜色")
        let model2 = UDColorPickerConfig.defaultModel(category: .text, title: "字体颜色")
        let model3 = UDColorPickerConfig.defaultModel(category: .background, title: "字体背景颜色")
        let config = UDColorPickerConfig(models: [model1, model2, model3])
        colorPicker = UDColorPickerPanel(config: config)
    }

    override func tearDown() {
        super.tearDown()

        colorPicker = nil
    }

    /// Test color picker title
    func testSetTitle() {
        if let models = self.colorPicker?.paletteData() {
            XCTAssertEqual(models[0].title, "选择颜色")
            XCTAssertEqual(models[1].title, "字体颜色")
            XCTAssertEqual(models[2].title, "字体背景颜色")
        }
    }

    /// Test color picker catefory
    func testSetCategory() {
        if let models = self.colorPicker?.paletteData() {
            XCTAssertEqual(models[0].category, .basic)
            XCTAssertEqual(models[1].category, .text)
            XCTAssertEqual(models[2].category, .background)
        }
    }

    /// Test color picker colorItem
    func testSetFirstColorItem() {
        if let models = self.colorPicker?.paletteData() {
            XCTAssertEqual(models[0].items[0].color, UIColor.ud.colorfulCarmine)
            XCTAssertEqual(models[1].items[0].color, UIColor.ud.R600)
            XCTAssertEqual(models[2].items[0].color, UIColor.ud.R200)
        }
    }
}
