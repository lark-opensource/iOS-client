//
//  DocsUrlUtilTest.swift
//  LarkDocsIcon-Unit-Tests
//
//  Created by huangzhikai on 2023/12/11.
//

import Foundation
import XCTest
import LarkDocsIcon
import LarkContainer
class DocsUrlUtilTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        LarkDocsIconAssembly().registContainer(container: Container.shared)
    }
    
    override func tearDown() {
        super.tearDown()
    }
 

    func testGetFileInfoNewFrom() {
//        let docsUrl = try? Container.shared.getCurrentUserResolver().resolve(type: DocsUrlUtil.self)
//        
//        var restult = docsUrl?.getFileInfoNewFrom(URL(string: "https://bytedance.larkoffice.com/wiki/wikcnxLaaeQU5z6Etw7eWhBwo6c")!)
//        XCTAssertEqual(restult!.token, "wikcnxLaaeQU5z6Etw7eWhBwo6c")
//        XCTAssertTrue(restult!.type == .wiki)
//
//        restult = docsUrl?.getFileInfoNewFrom(URL(string: "https://bytedance.us.larkoffice.com/docx/P1hsdu9F3o9xsCxxfIDuxpfLsif")!)
//        XCTAssertEqual(restult!.token, "P1hsdu9F3o9xsCxxfIDuxpfLsif")
//        XCTAssertTrue(restult!.type == .docX)
    }
    
}
