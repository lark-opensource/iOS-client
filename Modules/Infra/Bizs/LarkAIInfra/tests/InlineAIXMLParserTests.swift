//
//  InlineAIXMLParserTests.swift
//  LarkAIInfra-Unit-Tests
//
//  Created by huayufan on 2023/12/18.
//  


import XCTest
@testable import LarkAIInfra

final class InlineAIXMLParserTests: XCTestCase {

    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testParser() {
        let parser = AIMentionParser()
        let content = "hello<at type=\"22\" href=\"https://bytedance.larkoffice.com/docx/doxcnAQYYrxqeuaW9cuWDXN0QBf\" token=\"doxcnAQYYrxqeuaW9cuWDXN0QBf\">1234</at><at type=\"8\" href=\"https://bytedance.larkoffice.com/docx/doxcnAQYYrxqeuaW4cuDDXN0QBf\" token=\"doxcnAQYYrxqeuaW4cuDDXN0QBf\">5678</at> 2‌3333‌ ‌"

        let result = parser.parseContent(text: content)

        guard result.count == 2 else {
            XCTFail("result count id error")
            return
        }
        
        XCTAssertEqual(result[0].type, 22)
        XCTAssertEqual(result[0].token, "doxcnAQYYrxqeuaW9cuWDXN0QBf")
        XCTAssertEqual(result[0].content, "1234")
        
        XCTAssertEqual(result[1].type, 8)
        XCTAssertEqual(result[1].token, "doxcnAQYYrxqeuaW4cuDDXN0QBf")
        XCTAssertEqual(result[1].content, "5678")
    }
    

}
