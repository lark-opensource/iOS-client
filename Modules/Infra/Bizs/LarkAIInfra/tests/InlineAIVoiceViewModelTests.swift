//
//  InlineAIVoiceViewModelTests.swift
//  LarkAIInfra-Unit-Tests
//
//  Created by huayufan on 2023/11/27.
//  


import XCTest
@testable import LarkAIInfra

final class InlineAIVoiceViewModelTests: XCTestCase {


    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
    }

    
    func testModelCache() {
        let viewModel = InlineAIVoiceViewModel()
        let model = InlineAIPanelModel(show: true, conversationId: "1", taskId: "testId")
        viewModel.saveResult(model: model, for: "key")
        XCTAssertEqual(viewModel.getModelCache(key: "key")?.taskId ?? "", "testId")
        
        viewModel.resetCache()
        XCTAssertNil(viewModel.getModelCache(key: "key"))
    }
}
