//
//  DateTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by lijuyou on 2022/11/16.
//  


import XCTest

final class DateTests: XCTestCase {
    
    func testFormatter() throws {
        let date = Date(timeIntervalSince1970: 1668600059)
        let timeString = date.toLocalTime
        XCTAssertTrue(timeString == "2022-11-16 20:00:59.000")
    }
    
}
