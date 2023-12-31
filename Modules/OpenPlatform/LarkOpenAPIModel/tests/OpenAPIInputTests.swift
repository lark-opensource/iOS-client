//
//  OpenAPIInputTests.swift
//  LarkOpenAPIModel-Unit-Tests
//
//  Created by Meng on 2022/1/6.
//

import XCTest
@testable import LarkOpenAPIModel

class InputTypes {
    /// required value
    class OpenAPIInput1: OpenAPIBaseParams {
        @OpenAPIRequiredParam(userRequiredWithJsonKey: "value")
        var value: String

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }

    /// optional with default
    class OpenAPIInput2: OpenAPIBaseParams {
        @OpenAPIRequiredParam(
            userOptionWithJsonKey: "value",
            defaultValue: "value_default"
        )
        var value: String

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }
    
    /// required value + validChecker
    class OpenAPIInput3: OpenAPIBaseParams {
        @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "value",
            validChecker: OpenAPIValidChecker.notEmpty
        )
        var value: String

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }

    /// optional with default + validChecker
    class OpenAPIInput4: OpenAPIBaseParams {
        @OpenAPIRequiredParam(
            userOptionWithJsonKey: "value",
            defaultValue: "value_default",
            validChecker: OpenAPIValidChecker.notEmpty
        )
        var value: String

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }

    /// optional
    class OpenAPIInput5: OpenAPIBaseParams {
        @OpenAPIOptionalParam(jsonKey: "value")
        var value: String?

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }

    /// optional + validChecker
    class OpenAPIInput6: OpenAPIBaseParams {
        @OpenAPIOptionalParam(
            jsonKey: "value",
            validChecker: OpenAPIValidChecker.notEmpty
        )
        var value: String?

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }

    /// required type
    class OpenAPIInput7: OpenAPIBaseParams {
        @OpenAPIRequiredParam(userRequiredWithJsonKey: "value")
        var value: Int

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }

    /// optional with default type
    class OpenAPIInput8: OpenAPIBaseParams {
        @OpenAPIRequiredParam(userOptionWithJsonKey: "value", defaultValue: 1)
        var value: Int

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }

    /// optional type
    class OpenAPIInput9: OpenAPIBaseParams {
        @OpenAPIOptionalParam(jsonKey: "value")
        var value: Int?

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }
    
    /// optional with default and gray default, string
    class OpenAPIInput10: OpenAPIBaseParams {
        @OpenAPIRequiredParam(
            userOptionWithJsonKey: "value",
            defaultValue: "value_default",
            grayDefaultValue: .grayDefaultValue(
                defaultValue: "gray_value_default",
                featureKey: "test_gray_default_value_feature_key"
            )
        )
        var value: String

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }
    
    /// optional with default type and gray default, int
    class OpenAPIInput11: OpenAPIBaseParams {
        @OpenAPIRequiredParam(
            userOptionWithJsonKey: "value",
            defaultValue: 1,
            grayDefaultValue: .grayDefaultValue(
                defaultValue: 2,
                featureKey: "test_gray_default_value_feature_key"
            )
        )
        var value: Int

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_value]
        }
    }

    /// required with OpenAPIEnum
    class OpenAPIInput12: OpenAPIBaseParams {
        enum EnumValue: String, OpenAPIEnum {
            case value1, value2, value3, value4

            static var allowArrayParamEmpty: Bool {
                return true
            }
        }

        @OpenAPIRequiredParam(userRequiredWithJsonKey: "v1")
        var v1: EnumValue
        @OpenAPIRequiredParam(userRequiredWithJsonKey: "v2")
        var v2: [EnumValue]

        @OpenAPIRequiredParam(userOptionWithJsonKey: "v3", defaultValue: .value1)
        var v3: EnumValue
        @OpenAPIRequiredParam(userOptionWithJsonKey: "v4", defaultValue: [.value1])
        var v4: [EnumValue]

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_v1, _v2, _v3, _v4]
        }
    }

    /// optional with OpenAPIEnum
    class OpenAPIInput13: OpenAPIBaseParams {
        enum EnumValue: String, OpenAPIEnum {
            case value1, value2
            static var allowArrayParamEmpty: Bool {
                return false
            }
        }

        @OpenAPIOptionalParam(jsonKey: "v1")
        var v1: EnumValue?
        @OpenAPIOptionalParam(jsonKey: "v2")
        var v2: [EnumValue]?

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_v1, _v2]
        }
    }
}

class OpenAPIInputTests: XCTestCase {
    func testRequiredValue() {
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput1(with: ["value": "value"])
            XCTAssertTrue(input.value == "value")
        }(), "should not throw error")

        /// js undefined
        XCTAssertThrowsError(try InputTypes.OpenAPIInput1(with: [:]), "should throw error") { error in
            XCTAssertTrue(error is OpenAPIError)
            XCTAssertTrue((error as! OpenAPIError).code.rawValue == OpenAPICommonErrorCode.invalidParam.rawValue)
        }

        /// js null
        XCTAssertThrowsError(try InputTypes.OpenAPIInput1(with: ["value": NSNull()]), "should throw error") { error in
            XCTAssertTrue(error is OpenAPIError)
            XCTAssertTrue((error as! OpenAPIError).code.rawValue == OpenAPICommonErrorCode.invalidParam.rawValue)
        }
    }

    func testOptionalWithDefault() {
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput2(with: ["value": "value"])
            XCTAssertTrue(input.value == "value")
        }(), "should not throw error")

        /// js undefined
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput2(with: [:])
            XCTAssertTrue(input.value == "value_default")
        }(), "should not throw error")

        /// js null
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput2(with: ["value": NSNull()])
            XCTAssertTrue(input.value == "value_default")
        }(), "should not throw error")
    }
    
    func testRequiredWithValidChecker() {
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput3(with: ["value": "value"])
            XCTAssertTrue(input.value == "value")
        }(), "should not throw error")

        XCTAssertThrowsError(try InputTypes.OpenAPIInput3(with: ["value": ""]), "should throw error") { error in
            XCTAssertTrue(error is OpenAPIError)
            XCTAssertTrue((error as! OpenAPIError).code.rawValue == OpenAPICommonErrorCode.invalidParam.rawValue)
        }
    }

    func testOptionalWithDefaultAndValidChecker() {
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput4(with: ["value": "value"])
            XCTAssertTrue(input.value == "value")
        }(), "should not throw error")

        XCTAssertThrowsError(try InputTypes.OpenAPIInput4(with: ["value": ""]), "should throw error") { error in
            XCTAssertTrue(error is OpenAPIError)
            XCTAssertTrue((error as! OpenAPIError).code.rawValue == OpenAPICommonErrorCode.invalidParam.rawValue)
        }
    }

    func testOptional() {
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput5(with: ["value": "value"])
            XCTAssertTrue(input.value == "value")
        }(), "should not throw error")

        /// js undefined
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput5(with: [:])
            XCTAssertTrue(input.value == nil)
        }(), "should not throw error")

        /// js null
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput5(with: ["value": NSNull()])
            XCTAssertTrue(input.value == nil)
        }(), "should not throw error")
    }

    func testOptionalWithValidChecker() {
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput6(with: ["value": "value"])
            XCTAssertTrue(input.value == "value")
        }(), "should not throw error")

        XCTAssertThrowsError(try InputTypes.OpenAPIInput6(with: ["value": ""]), "should throw error") { error in
            XCTAssertTrue(error is OpenAPIError)
            XCTAssertTrue((error as! OpenAPIError).code.rawValue == OpenAPICommonErrorCode.invalidParam.rawValue)
        }
    }

    func testRequiredType() {
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput7(with: ["value": 1])
            XCTAssertTrue(input.value == 1)
        }(), "should not throw error")

        XCTAssertThrowsError(try InputTypes.OpenAPIInput7(with: ["value": "value"]), "should throw error") { error in
            XCTAssertTrue(error is OpenAPIError)
            XCTAssertTrue((error as! OpenAPIError).code.rawValue == OpenAPICommonErrorCode.invalidParam.rawValue)
        }
    }

    func testOptionalType() {
        XCTAssertNoThrow(try {
            let input = try InputTypes.OpenAPIInput9(with: ["value": 1])
            XCTAssertTrue(input.value == 1)
        }(), "should not throw error")

        XCTAssertThrowsError(try InputTypes.OpenAPIInput9(with: ["value": "value"]), "should throw error") { error in
            XCTAssertTrue(error is OpenAPIError)
            XCTAssertTrue((error as! OpenAPIError).code.rawValue == OpenAPICommonErrorCode.invalidParam.rawValue)
        }
    }

    func testRequiredWithOpenAPIEnum() {
        XCTAssertNoThrow(try {
            typealias EnumValue = InputTypes.OpenAPIInput12.EnumValue
            let input = try InputTypes.OpenAPIInput12(with: [
                "v1": "value1",
                "v2": ["value2"],
                "v3": "value3",
                "v4": ["value4"]
            ])
            XCTAssertTrue(input.v1 == EnumValue.value1)
            XCTAssertTrue(input.v2 == [EnumValue.value2])
            XCTAssertTrue(input.v3 == EnumValue.value3)
            XCTAssertTrue(input.v4 == [EnumValue.value4])
        }(), "should not throw error")

        /// null & empty
        XCTAssertNoThrow(try {
            typealias EnumValue = InputTypes.OpenAPIInput12.EnumValue
            let input = try InputTypes.OpenAPIInput12(with: [
                "v1": "value1",
                "v2": [], // allowArrayParamEmpty == true
                "v3": NSNull(),
                "v4": NSNull()
            ])
            XCTAssertTrue(input.v1 == EnumValue.value1)
            XCTAssertTrue(input.v2 == [])
            XCTAssertTrue(input.v3 == EnumValue.value1)
            XCTAssertTrue(input.v4 == [EnumValue.value1])
        }(), "should not throw error")

        /// undefined
        XCTAssertNoThrow(try {
            typealias EnumValue = InputTypes.OpenAPIInput12.EnumValue
            let input = try InputTypes.OpenAPIInput12(with: [
                "v1": "value1",
                "v2": [], // allowArrayParamEmpty == true
                // "v3": "value3",
                // "v4": ["value4"]
            ])
            XCTAssertTrue(input.v1 == EnumValue.value1)
            XCTAssertTrue(input.v2 == [])
            XCTAssertTrue(input.v3 == EnumValue.value1)
            XCTAssertTrue(input.v4 == [EnumValue.value1])
        }(), "should not throw error")
    }

    func testOptionalWithOpenAPIEnum() {
        XCTAssertNoThrow(try {
            typealias EnumValue = InputTypes.OpenAPIInput13.EnumValue
            let input = try InputTypes.OpenAPIInput13(with: [
                "v1": "value1",
                "v2": ["value2"]
            ])
            XCTAssertTrue(input.v1 == EnumValue.value1)
            XCTAssertTrue(input.v2 == [EnumValue.value2])
        }(), "should not throw error")

        /// null
        XCTAssertNoThrow(try {
            typealias EnumValue = InputTypes.OpenAPIInput13.EnumValue
            let input = try InputTypes.OpenAPIInput13(with: [
                "v1": NSNull(),
                "v2": ["value2"]
            ])
            XCTAssertTrue(input.v1 == nil)
            XCTAssertTrue(input.v2 == [EnumValue.value2])
        }(), "should not throw error")

        /// empty
        XCTAssertThrowsError(try {
            typealias EnumValue = InputTypes.OpenAPIInput13.EnumValue
            _ = try InputTypes.OpenAPIInput13(with: [
                "v1": "value1",
                "v2": [] // allowArrayParamEmpty == false
            ])
        }(), "should throw error")

        /// undefined
        XCTAssertNoThrow(try {
            typealias EnumValue = InputTypes.OpenAPIInput13.EnumValue
            let input = try InputTypes.OpenAPIInput13(with: [
                // "v1": "value1",
                "v2": ["value2"]
            ])
            XCTAssertTrue(input.v1 == nil)
            XCTAssertTrue(input.v2 == [EnumValue.value2])
        }(), "should not throw error")
    }
}
