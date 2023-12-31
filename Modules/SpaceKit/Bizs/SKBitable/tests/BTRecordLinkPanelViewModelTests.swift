//
//  BTRecordLinkPanelViewModelTests.swift
//  SKBitable-Unit-Tests
//
//  Created by yinyuan on 2023/12/4.
//
import XCTest
import HandyJSON
import RxSwift
import UniverseDesignEmpty
@testable import SKBitable
import OHHTTPStubs
import SKInfra

class BTRecordLinkPanelViewModelTests: XCTestCase {
    var dataService = LinkPanelDataService()
//    var sut: BTRecordLinkPanelViewModel?
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCellState() {
        dataService.needFetchTableMeatFail = false
        let sut = BTRecordLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService)
        
        let normalRecord = BTRecordModel(recordID: "mock_normol_id_1")
        let res = sut.cellState(recordModel: normalRecord)
        XCTAssertNotNil(res)
    }
    
    private func async(completion: @escaping() -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: completion)
    }
    
    func testSuccess() {
        stubSuccess()
        let expect = expectation(description: "reloadTable")
        async {
            expect.fulfill()
        }
        
        dataService.needFetchTableMeatFail = false
        let sut = BTRecordLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService)
              
        sut.reloadTable(.linkCardTop)
        
        sut.fetchLinkCardList(.linkCardTop)
        
        sut.fetchLinkCardList(.linkCardBottom)
        
        wait(for: [expect], timeout: 3.0)
        
        XCTAssertTrue(sut.recordModels.count > 2)
        
        sut.updateSelectedRecords([BTRecordModel(recordID: "mock_selected_id", isSelected: true, recordTitle: "111"), BTRecordModel(recordID: "recUsjZJig", isSelected: true, recordTitle: "")])
        XCTAssertTrue(sut.selectedIDs.count == 2)
        
        sut.changeSelectionStatus(id: "recbGirOZ6", isSelected: true, couldSelectMultiple: true)
        XCTAssertTrue(sut.selectedIDs.count == 3)
        
        sut.changeSelectionStatus(id: "recbGirOZ6", isSelected: false, couldSelectMultiple: true)
        XCTAssertTrue(sut.selectedIDs.count == 2)
        
        sut.changeSelectionStatus(id: "recbGirOZ6", isSelected: true, couldSelectMultiple: false)
        XCTAssertTrue(sut.selectedIDs.count == 1)
        
        sut.changeSelectionStatus(id: "xxxxxxxxxx", isSelected: true, couldSelectMultiple: false)
        XCTAssertTrue(sut.selectedIDs.count == 1)
        
        sut.searchText = "1"
        let expectSearch = expectation(description: "search link table")
        async {
            expectSearch.fulfill()
        }
        wait(for: [expectSearch], timeout: 2.0)
        XCTAssertTrue(sut.recordModels.count == 3)  // 001 010 111
        
        sut.searchText = "xxxxx"
        sut.searchText = "xxxxx"
        let expectSearchEmpty = expectation(description: "search link table empty")
        async {
            expectSearchEmpty.fulfill()
        }
        wait(for: [expectSearchEmpty], timeout: 2.0)
        XCTAssertTrue(sut.recordModels.count == 0)
    }
    
    func testEmpty() {
        stubEmpty()
        
        let expect = expectation(description: "reloadTable")
        async {
            expect.fulfill()
        }
        
        dataService.needFetchTableMeatFail = false
        let sut = BTRecordLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService)
              
        sut.reloadTable(.linkCardTop)
        
        wait(for: [expect], timeout: 3.0)
        
        XCTAssertTrue(sut.recordModels.count == 0)
    }
    
    func testException() {
        stubError()
        testException(code: LinkContentResponse.Code.tableNotFound.rawValue)
        testException(code: LinkContentResponse.Code.noTablePermission.rawValue)
        let dataStr0 = """
                        {
                        "code": 0,
                        "msg": ""
                        }
        """
        testException(dataStr: dataStr0)
        let dataStr1 = """
                        {
                        "code": 0,
                        "msg": "",
                        "data": {
                        }
                        }
        """
        testException(dataStr: dataStr1)
    }
    
    func testException(code: Int) {
        let dataStr = """
            {"code": \(code),
            "msg": "",
            "data": {}
            }
"""
        testException(dataStr: dataStr)
    }
    
    func testException(dataStr: String) {
        stubException(dataStr: dataStr)
        
        let expect = expectation(description: "reloadTable")
        async {
            expect.fulfill()
        }
        
        dataService.needFetchTableMeatFail = false
        let sut = BTRecordLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService)
              
        sut.reloadTable(.linkCardTop)
        
        wait(for: [expect], timeout: 3.0)
        
        XCTAssertTrue(sut.recordModels.count == 0)
    }
    
    func stubSuccess() {
        let baseToken = ""
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getBaseLinkContent(baseToken))
            return contain
        }, response: { _ in
            let data = MockJSONDataManager.getJSONData(filePath: "JSONDatas/linkContent")
            return HTTPStubsResponse(data: data, statusCode: 200, headers: ["Content-Type": "application/json"])
        })
    }
    
    func stubEmpty() {
        let dataStr = """
{
"code": 0,
"msg": "",
"data": {
    "linkTableName": "link table",
    "linkContent": "{\"primaryFieldType\":1005,\"recordIDs\":[],\"primaryValue\":{}}",
    "hasMore": false
}
}
"""
        stubException(dataStr: dataStr)
    }
    
    func stubException(dataStr: String) {
        let baseToken = ""
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getBaseLinkContent(baseToken))
            return contain
        }, response: { _ in
            return HTTPStubsResponse(data: dataStr.data(using: .utf8) ?? Data(), statusCode: 200, headers: ["Content-Type": "application/json"])
        })
    }
    
    func stubError() {
        let baseToken = ""
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.getBaseLinkContent(baseToken))
            return contain
        }, response: { _ in
            return HTTPStubsResponse(error: LinkTableError.invalidResponse)
        })
    }
}

