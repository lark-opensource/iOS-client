//
//  DictionaryTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by zengsenyuan on 2022/12/12.
//  


import XCTest
@testable import SKFoundation

class DictionaryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    
    func testConvertable() {
        let model = DemoModel(value: "value", optionalValue: nil)
        XCTAssertTrue((model.dictionary?["value"] as? String) == "value")
        XCTAssertTrue(model.dictionary?["optionalValue"] == nil)
        
        let model2 = DemoModel(value: "value", optionalValue: 10)
        XCTAssertTrue((model2.dictionary?["value"] as? String) == "value")
        XCTAssertTrue((model2.dictionary?["optionalValue"] as? Int) == 10)
    }
}


struct DemoModel: DictionaryConvertable {
    var value: String
    var optionalValue: Int?
}
