//
//  TemplateRouterTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/10/12.
//  


import XCTest
@testable import SKCommon
import SKFoundation

class TemplateRouterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    

    override func tearDown() {
        super.tearDown()
        
    }
    
    func testTargetVCForCollectionPreviewViewController() {
        let router = TemplateCenterRouter()
        let url = URL(string: "https://bytedance.feishu.cn/drive/template-center?action=preview&templateType=4&from=templateSource&id=1234")!
        let vc = router.targetVC(resource: url, params: [:])
        
        XCTAssertNotNil(vc)
        let collectionPreviewViewController = vc as? TemplateCollectionPreviewViewController
        XCTAssertNotNil(collectionPreviewViewController)
    }
}
