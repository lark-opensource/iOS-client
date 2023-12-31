//
//  UDInputTests.swift
//  UniverseDesignInput-Unit-UnitTests
//
//  Created by 姚启灏 on 2020/11/24.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignInput

class UDInputTests: XCTestCase {

    let textField = UDTextField()

    let multilineTextField = UDMultilineTextField()

    func testTextField() throws {
        textField.setStatus(.error)

        XCTAssert(textField.status == .error)

        textField.becomeFirstResponder()

        XCTAssert(textField.isFirstResponder)
    }

    func testTextFieldInput() {
        XCTAssert(textField.isEditing == textField.input.isEditing)

        textField.isEnable = false

        XCTAssert(!textField.input.isEnabled)

        XCTAssert(textField.canBecomeFirstResponder == textField.input.canBecomeFirstResponder)
    }

    func testTextFieldConfig() {
        textField.config.isShowTitle = true

        XCTAssert(!textField.titleLabel.isHidden)

        textField.title = "测试"
        XCTAssert(textField.titleLabel.text == "测试")

        textField.config.errorMessege = "Error"

        XCTAssert(textField.errorLabel.text == "Error")
    }

    func testTextFieldAddViews() {
        textField.setLeftView(UIView())
        textField.setRightView(UIView())

        XCTAssert(textField.leftView != nil && textField.rightView != nil)
    }

    func testMultilineTextField() throws {
        multilineTextField.setStatus(.error)

        XCTAssert(multilineTextField.status == .error)

        multilineTextField.becomeFirstResponder()

        XCTAssert(multilineTextField.input.isFirstResponder)
    }

    func testMultilineTextFieldInput() {
        XCTAssert(multilineTextField.isEditable == multilineTextField.input.isEditable)

        multilineTextField.isEditable = false

        XCTAssert(multilineTextField.isEditable == multilineTextField.input.isEditable)

        XCTAssert(multilineTextField.isFirstResponder == multilineTextField.input.isFirstResponder)
    }

    func testMultilineTextFieldConfig() {

        multilineTextField.config.errorMessege = "Error"

        XCTAssert(multilineTextField.errorLabel.text == "Error")
    }
}
