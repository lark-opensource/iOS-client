//
//  DocMenuPluginAPIHandlerTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/7/12.
//  


import UIKit
import WebBrowser
@testable import SKCommon
import XCTest

class DocMenuPluginAPIHandlerTests: XCTestCase {
    
    
    class MyDocMenuPluginConfig: DocMenuPluginConfig {
        
        var blackList: [String] {
            return ["123"]
        }
        
        var clipSpecifyEnable: Bool {
            return true
        }
    }

    let handler = DocMenuPluginAPIHandler(webBrowser: nil, pluginConfig: MyDocMenuPluginConfig())
    
    func testLoadJSString() {
        let expect = expectation(description: "test load clip js resource")
        handler.loadJSString { str in
            expect.fulfill()
            XCTAssertNotNil(str)
        }
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
    
    func testTemplate() {
        var jsString = "a={{ secret_key }},b={{ specify_enable }}"
        jsString = handler.resolveTemplate(jsString: jsString)
        let splits = jsString.split(separator: ",").map { String($0) }
        XCTAssertEqual(splits[0], "a=\(handler.secretKey)")
        XCTAssertEqual(splits[1], "b=\(true)")
    }
}
