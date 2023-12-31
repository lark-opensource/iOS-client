//
//  BTSortPanelViewModelTests.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/8/2.
//  


import XCTest
@testable import SKBitable
import RxSwift
import RxCocoa
@testable import SKFoundation

class BTSortPanelViewModelTests: XCTestCase {
    
    var sortViewModel: BTSortPanelViewModel!
    
    override func setUp() {
        super.setUp()
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.nopermission", value: true)
        sortViewModel = BTSortPanelViewModel(dataService: MockSortPanelService(), callback: "callback")
        sortViewModel.getSortModel(completion: nil)
    }

    override func tearDown() {
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.nopermission")
        super.tearDown()
    }
    
    func testGetSortModel() {
        let expect = expectation(description: "testGetSortModel")
        sortViewModel.getSortModel { model in
            XCTAssertNotNil(model)
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.05) { error in
            XCTAssertNil(error)
        }
    }
    
    func testUpdateSortInfos() {
        let expect = expectation(description: "testUpdateSortInfos")
        sortViewModel.updateSortInfos(action: .updateAutoSort(true), completion: { sortInfo in
            guard let sortInfo = sortInfo else {
                XCTAssertTrue(false)
                return 
            }
            expect.fulfill()
            XCTAssertTrue(sortInfo.autoSort)
        })
        waitForExpectations(timeout: 0.05) { error in
            XCTAssertNil(error)
        }
    }
    
    func testGetAddNewInfo() {
        let newInfo = sortViewModel.getAddNewInfo()
        XCTAssertNotNil(newInfo)
    }
    
    func testGetSortOption() {
        let sortOption = sortViewModel.getSortOption(by: "fldpkA8AkJ")
        XCTAssertTrue(sortOption?.name == "公式")
    }
    
    func testGetSortInfo() {
        let info = sortViewModel.getSortInfo(at: 1)
        XCTAssertTrue(info?.fieldId == "fldR7ruaLR")
        let info2 = sortViewModel.getSortInfo(by: "fldL3P4nfs")
        XCTAssertTrue(info2?.fieldId == "fldL3P4nfs")
    }
    
    func testGetFieldCommonListData() {
        let result = sortViewModel.getFieldCommonListData(with: 0)
        XCTAssertFalse(result.datas.isEmpty)
    }
    
    func testCovertJSDataToSortPanelModel() {
        guard let jsData = sortViewModel.cacheJSData else {
            XCTAssertTrue(false)
            return
        }
        let expect = expectation(description: "testCovertJSDataToSortPanelModel")
        sortViewModel.covertJSDataToSortPanelModel(with: jsData, completion: { model in
            XCTAssertNotNil(model)
            expect.fulfill()
        })
        waitForExpectations(timeout: 0.05) { error in
            XCTAssertNil(error)
        }
    }
}
