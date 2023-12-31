//
//  DocsCreateDirectorV2Test.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huangzhikai on 2022/8/15.

import XCTest
@testable import SKCommon

class DocsCreateDirectorV2Test: XCTestCase {

    func testIsCanLocallyCreate() {
        
        var docsCreate = DocsCreateDirectorV2(type: .doc, ownerType: 1, name: nil, in: "")
        
        //fasle
        var result = docsCreate.isCanLocallyCreate(enableLocallyCreate: false,
                                      protocolEnable: true,
                                      isAgentRepeatModuleEnable: true)
        XCTAssertTrue(!result)
        
        //false
        result = docsCreate.isCanLocallyCreate(enableLocallyCreate: true,
                                      protocolEnable: false,
                                      isAgentRepeatModuleEnable: false)
        XCTAssertTrue(!result)
        
        //true
        result = docsCreate.isCanLocallyCreate(enableLocallyCreate: true,
                                      protocolEnable: false,
                                      isAgentRepeatModuleEnable: true)
        XCTAssertTrue(result)
        
        //true
        result = docsCreate.isCanLocallyCreate(enableLocallyCreate: true,
                                      protocolEnable: true,
                                      isAgentRepeatModuleEnable: false)
        XCTAssertTrue(result)
        
        //true
        docsCreate = DocsCreateDirectorV2(type: .bitable, ownerType: 1, name: nil, in: "")
        
        //false
        result = docsCreate.isCanLocallyCreate(enableLocallyCreate: true,
                                      protocolEnable: true,
                                      isAgentRepeatModuleEnable: true)
        XCTAssertTrue(!result)
        
    }
}
