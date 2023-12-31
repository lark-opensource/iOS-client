//
//  BTUserViewModelTests.swift
//  SKBrowser_Tests-Unit-_Tests
//
//  Created by zoujie on 2022/9/20.
//  


import XCTest
import SKFoundation
@testable import SKBrowser

class BTUserViewModelTests: XCTestCase {
    
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }
    
    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    
    func testChangeSelectStatus() {
        let viewModel = BTChatterPanelViewModel(nil, chatId: nil, openSource: BTChatterPanelViewModel.OpenSource.record(chatterType: .user), lastSelectNotifies: true, chatterType: .user)
        XCTAssertTrue(viewModel.notifyMode.notifiesEnabled)
        
        let models = [BTCapsuleModel(id: "1", text: "1", color: BTColorModel(), isSelected: true),
                      BTCapsuleModel(id: "2", text: "2", color: BTColorModel(), isSelected: true),
                      BTCapsuleModel(id: "3", text: "3", color: BTColorModel(), isSelected: true),
                      BTCapsuleModel(id: "4", text: "4", color: BTColorModel(), isSelected: true),
                      BTCapsuleModel(id: "5", text: "5", color: BTColorModel(), isSelected: true)]
        viewModel.updateSelected(models)
        XCTAssertTrue(viewModel.selectedData.value.count == 5)
        
        viewModel.deselect(at: 1)
        XCTAssertTrue(viewModel.selectedData.value.count == 4)
        
        XCTAssertTrue(viewModel.notifyMode == .enabled(notifies: true))
    }
}
