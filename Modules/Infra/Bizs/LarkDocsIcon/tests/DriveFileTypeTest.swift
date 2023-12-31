//
//  DriveFileTypeTest.swift
//  LarkDocsIcon-Unit-Tests
//
//  Created by huangzhikai on 2023/12/11.
//

import Foundation
import XCTest
import LarkDocsIcon
class DriveFileTypeTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDriveFileType() {
        var type = DriveFileType(fileExtension: "png")
        XCTAssertTrue(type == .png)
        
        type = DriveFileType(fileExtension: "bbb")
        XCTAssertTrue(type == .unknown)
        
        
        type = DriveFileType(fileExtension: "pdf")
        XCTAssertTrue(type == .pdf)
        XCTAssertTrue(type.rawValue == "pdf")
        
    }
    
}
