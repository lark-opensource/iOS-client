//
//  DocsIconInfoTest.swift
//  LarkDocsIcon-Unit-Tests
//
//  Created by huangzhikai on 2023/12/5.
//

import Foundation
import XCTest
import LarkDocsIcon
class DocsIconInfoTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCreateDocsIconInfo() {
        let iconInfo = DocsIconInfo.createDocsIconInfo(json: "{\"type\":1,\"key\":\"1f42f\",\"obj_type\":12,\"file_type\":\"json\",\"token\":\"HNjUbQGvGoBNcsx6jtXbeexfc0g\",\"version\":3}")
        
        XCTAssertTrue(iconInfo != nil)
        XCTAssertTrue(iconInfo!.type == .unicode)
        XCTAssertTrue(iconInfo!.key == "1f42f")
        XCTAssertTrue(iconInfo!.token == "HNjUbQGvGoBNcsx6jtXbeexfc0g")
    }
    
    func testGetFileExtension() {
        var ext = DocsIconInfo.getFileExtension(from: "aaa.bbb.png")
        XCTAssertEqual(ext, "png")
        
        ext = DocsIconInfo.getFileExtension(from: ".png")
        XCTAssertEqual(ext, "png")
        
        ext = DocsIconInfo.getFileExtension(from: "bbb.mp4")
        XCTAssertEqual(ext, "mp4")
        
        ext = DocsIconInfo.getFileExtension(from: "bbbmp4")
        XCTAssertEqual(ext, "")
        
    }
    
}
