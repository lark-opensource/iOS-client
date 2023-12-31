//
//  SubFolderListViewModelV2Tests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/10/8.
//
@testable import SKSpace
import Foundation
import SKFoundation
import SKCommon
import RxSwift
import XCTest

final class SubFolderListViewModelV2Tests: XCTestCase {
    private var bag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        bag = DisposeBag()
    }
    
    static func mockVM() -> SubFolderListViewModelV2 {
        let dm = SubFolderDataModelV2Tests.mockDM()
        let vm = SubFolderListViewModelV2(dataModel: dm)
        return vm
    }
    
    func testGenerateSlideConfig() {
        let vm = Self.mockVM()
        vm.prepare()
        let expect = expectation(description: "subfolder V2 generate slide config")
        let entry = FolderEntry(type: .folder, nodeToken: "folder", objToken: "folder")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let config = vm.generateSlideConfig(for: entry)
        let handler = config?.handler
        let cell = UIView()
        expect.expectedFulfillmentCount = 3
        XCTAssertEqual(config?.actions, [.delete, .share, .more])
        vm.actionSignal.emit { action in
            switch action {
            case .present, .openShare:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        
        handler?(cell, .delete)
        handler?(cell, .share)
        handler?(cell, .more)
        waitForExpectations(timeout: 10)
    }
}
