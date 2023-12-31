//
//  BTGeoLocationModelTest.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/7/7.
//

import XCTest
@testable import SKBitable
import SKFoundation

class BTGeoLocationModelTest: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testLocationValid() {
        _ = {
            let model = BTGeoLocationModel(
                location: (0, 0), pname: "", cityname: "",
                adname: "", name: "", address: "", fullAddress: ""
            )
            XCTAssertTrue(model.isLocationValid)
        }()
        _ = {
            let model = BTGeoLocationModel(
                location: (-180, 0), pname: "", cityname: "",
                adname: "", name: "", address: "", fullAddress: ""
            )
            XCTAssertTrue(model.isLocationValid)
        }()
        _ = {
            let model = BTGeoLocationModel(
                location: (180, 0), pname: "", cityname: "",
                adname: "", name: "", address: "", fullAddress: ""
            )
            XCTAssertTrue(model.isLocationValid)
        }()
        _ = {
            let model = BTGeoLocationModel(
                location: (0, -90), pname: "", cityname: "",
                adname: "", name: "", address: "", fullAddress: ""
            )
            XCTAssertTrue(model.isLocationValid)
        }()
        _ = {
            let model = BTGeoLocationModel(
                location: (0, 90), pname: "", cityname: "",
                adname: "", name: "", address: "", fullAddress: ""
            )
            XCTAssertTrue(model.isLocationValid)
        }()
        _ = {
            let model = BTGeoLocationModel(
                location: (181, 0), pname: "", cityname: "",
                adname: "", name: "", address: "", fullAddress: ""
            )
            XCTAssertFalse(model.isLocationValid)
        }()
        _ = {
            let model = BTGeoLocationModel(
                location: (-181, 0), pname: "", cityname: "",
                adname: "", name: "", address: "", fullAddress: ""
            )
            XCTAssertFalse(model.isLocationValid)
        }()
        _ = {
            let model = BTGeoLocationModel(
                location: (0, 91), pname: "", cityname: "",
                adname: "", name: "", address: "", fullAddress: ""
            )
            XCTAssertFalse(model.isLocationValid)
        }()
        _ = {
            let model = BTGeoLocationModel(
                location: (0, -91), pname: "", cityname: "",
                adname: "", name: "", address: "", fullAddress: ""
            )
            XCTAssertFalse(model.isLocationValid)
        }()
    }
}
