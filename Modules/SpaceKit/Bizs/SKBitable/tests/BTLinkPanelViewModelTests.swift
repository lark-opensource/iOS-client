//
//  BTLinkPanelViewModelTests.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by zoujie on 2022/8/30.
//

import XCTest
import HandyJSON
import RxSwift
import UniverseDesignEmpty
@testable import SKBitable

class LinkPanelDelegate: BTLinkPanelDelegate {
    func startLoadingTimer() {}
    
    func showTryAgainEmptyView(text: String, type: UniverseDesignEmpty.UDEmptyType, tryAgainBlock: (() -> Void)?) {}
    
    func scrollToIndex(index: Int, animated: Bool, needFixOffest: Bool) {}
    
    func startLoadingTimer(hideSearchView: Bool) {}
    
    func showTryAgainEmptyView(text: String, type: UniverseDesignEmpty.UDEmptyType, hideSearchView: Bool, tryAgainBlock: (() -> Void)?) {}
    
    func updateLinkedRecords(recordIDs: [String], recordTitles: [String : String]) {}

    func trackOpenLinkPanel(currentLinkageCount: Int, fieldModel: BTFieldModel) {}

    func trackUpdatedLinkage(selectionStatus: Bool) {}

    func beginSearching() {}

    func createAndLinkNewRecord(primaryText: String?) {}

    func finishLinking(_ panel: BTLinkPanel) {}
}

class LinkPanelDataService: BTLinkPanelDataSource {
    var linkFiledContext: (dataProvider: BTLinkTableDataProvider, viewMode: BTViewMode) = (BTLinkTableDataProvider(baseToken: "", tableID: "", fieldID: ""), BTViewMode.addRecord)
    
    var filterInfoValidMock: (isValid: Bool, errorMsg: String) = (true, "")
    var needFetchTableMeatFail = false
    
    
    func constructCardRequest(_ type: SKBitable.BTCardFetchType, completionBlock: ((Bool) -> Void)?, searchKey: String?) -> SKBitable.BTGetCardListRequest? {
        let requestModel = BTGetCardListModel(startFromLeft: type.offset(fromCurrentIndex: 0,
                                                                         currentCount: 10),
                                              fetchCount: type.preloadSize(currentCount: 10),
                                              recordIds: [],
                                              fieldIds: [],
                                              searchKey: searchKey)

        let request = BTGetCardListRequest(requestId: String(Date().timeIntervalSince1970),
                                           requestType: type,
                                           requestStatus: .start,
                                           requestModel: requestModel,
                                           overTimeInterval: 0,
                                           completionBlock: completionBlock)

        return request
    }
    
    func fetchLinkCardList(_ request: SKBitable.BTGetCardListRequest?, successBlock: @escaping (SKBitable.BTTableValue) -> Void, failedBlock: @escaping (Error?) -> Void) {
        var mockRecords = [BTRecordValue(recordId: "mock_1", recordTitle: "mock_1"),
                           BTRecordValue(recordId: "mock_2", recordTitle: "mock_2"),
                           BTRecordValue(recordId: "mock_3", recordTitle: "mock_3")]
        var result = BTTableValue()
        result.loaded = true
        if request?.requestType == .linkCardTop {
            mockRecords.insert(BTRecordValue(recordId: "mock_0"), at: 0)
        } else if request?.requestType == .linkCardBottom {
            mockRecords.append(BTRecordValue(recordId: "mock_4"))
        } else if request?.requestType == .linkCardSearch {
            failedBlock(nil)
        } else if request?.requestType == .linkCardUpdate {
            result.loaded = false
            mockRecords = []
        }
        result.records = mockRecords
        
        successBlock(result)
    }
    
    func constructCardRequest(_ type: SKBitable.BTCardFetchType, searchKey: String?) -> SKBitable.BTGetCardListRequest? {
        return BTGetCardListRequest(requestType: type, requestModel: BTGetCardListModel(searchKey: searchKey))
    }
    
    var nextMode: BTViewMode {
        return .card
    }

    func fetchTableMeta() -> Single<BTTableMeta> {
        return Single<BTTableMeta>.create { [weak self] single in
            if self?.needFetchTableMeatFail == true {
                single(.error(NSError(domain: "bitable", code: 1003, userInfo: nil)))
            } else {
                single(.success(BTTableMeta()))
            }
            return Disposables.create()
        }
    }
    
    func isFilterInfoValid() -> (isValid: Bool, errorMsg: String) {
        return self.filterInfoValidMock
    }
}

class BTLinkPanelViewModelTests: XCTestCase {
    var dataService = LinkPanelDataService()
    var sut: BTLinkPanelViewModel?
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFetchTableMeta() {
        sut = BTLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService, mode: .card)
        sut?.reloadTable(.linkCardUpdate)
        XCTAssertNotNil(sut?.tableMeta)
        
        dataService.needFetchTableMeatFail = true
        sut?.reloadTable(.linkCardUpdate)
        XCTAssertTrue(sut?.linkFieldMetaEmpty ?? false)
    }
    
    func testCellState() {
        dataService.needFetchTableMeatFail = false
        sut = BTLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService, mode: .card)
        
        let normalRecord = BTRecordModel(recordID: "mock_normol_id_1")
        let res = sut?.cellState(recordModel: normalRecord)
        XCTAssertNotNil(res)
    }
    
    func testApplySelection() {
        dataService.needFetchTableMeatFail = false
        sut = BTLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService, mode: .card)
        
        let normalRecord = BTRecordModel(recordID: "mock_normol_id_1")
        sut?.applySelection(to: [normalRecord], selectedIDs: [], isNeedSetOldRecordTop: true)
        
        let selectedRecord = BTRecordModel(recordID: "mock_selected_id", isSelected: true)
        sut?.applySelection(to: [selectedRecord], selectedIDs: [], isNeedSetOldRecordTop: true)
        sut?.updateSelectedRecords([selectedRecord])
        XCTAssertTrue((sut?.recordModels?.count ?? 0) == 1)
        
        let normalRecord2 = BTRecordModel(recordID: "mock_normol_id_2")
        sut?.applySelection(to: [normalRecord2], selectedIDs: [], isNeedSetOldRecordTop: true)
        XCTAssertTrue((sut?.recordModels?.count ?? 0) == 2)
    }
    
    func testFetchLinkCardList() {
        dataService.needFetchTableMeatFail = false
        sut = BTLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService, mode: .card)
        
        sut?.reloadTable(.linkCardInitialize)
        
        sut?.fetchLinkCardList(.linkCardInitialize)
        
        sut?.fetchLinkCardList(.linkCardOnlyData)
        
        XCTAssertTrue(sut?.recordModels?.count == 3)
        
        sut?.fetchLinkCardList(.linkCardTop)
        XCTAssertTrue(sut?.recordModels?.first?.recordID == "mock_0")
        
        sut?.fetchLinkCardList(.linkCardBottom)
        XCTAssertTrue(sut?.recordModels?.last?.recordID == "mock_4")
    }
    
    func testSearch() {
        dataService.needFetchTableMeatFail = false
        sut = BTLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService, mode: .card)
        sut?.search("mock_1")
        
        XCTAssertTrue(sut?.fetchDataManager.cardListRequestWaitingQueue.count == 0)
    }
    
    func testHandleDataLoaded() {
        dataService.needFetchTableMeatFail = false
        sut = BTLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService, mode: .card)
        sut?.fetchLinkCardList(.linkCardSearch)

        sut?.handleDataLoaded(router: .getLinkCardList)
        XCTAssertTrue(sut?.fetchDataManager.cardListRequestWaitingQueue.count == 0)
    }
    
    func testLoading() {
        dataService.needFetchTableMeatFail = false
        sut = BTLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService, mode: .card)
        sut?.reloadTable(.linkCardInitialize)
        
        sut?.fetchLinkCardList(.linkCardUpdate)
        XCTAssertTrue(sut?.fetchDataManager.cardListRequestWaitingQueue.count == 1)
    }
    
    func testChangeSelection() {
        dataService.needFetchTableMeatFail = false
        sut = BTLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService, mode: .card)
        
        sut?.applySelection(to: [BTRecordModel(recordID: "mock1"), BTRecordModel(recordID: "mock2")], selectedIDs: [])
        
        sut?.changeSelectionStatus(id: "mock1", isSelected: true, couldSelectMultiple: true)
        
        XCTAssertTrue(sut?.selectedIDs.count == 1)
    }
    
    
    func testGetNextMode() {
        
        dataService.needFetchTableMeatFail = false
        let viewModel = BTLinkPanelViewModel(delegate: LinkPanelDelegate(), dataSource: dataService, mode: .card)
        // check meta is nil，linkFieldMetaEmpty is false
        viewModel.linkFieldMetaEmpty = false
        let nextMode1 = viewModel.getNextMode(by: nil, records: [])
        XCTAssertTrue(nextMode1 == nil)
        
        // check meta is nil，linkFieldMetaEmpty is true
        viewModel.linkFieldMetaEmpty = true
        let nextMode2 = viewModel.getNextMode(by: nil, records: [])
        if case .tableDeleted = nextMode2 {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        
        // check meta is not nil, but no permission
        var meta = BTTableMeta()
        meta.tableVisible = false
        let nextMode3 = viewModel.getNextMode(by: meta, records: [])
        if case .noPermission = nextMode3 {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        
        // check meta is not nil, has permission, but filterInfo invalid
        meta.tableVisible = true
        (viewModel.dataSource as? LinkPanelDataService)?.filterInfoValidMock = (false, "errorMsg")
        let nextMode4 = viewModel.getNextMode(by: meta, records: [])
        if case .filterInfoError(let msg) = nextMode4 {
            XCTAssertTrue(msg == "errorMsg")
        } else {
            XCTAssertTrue(false)
        }
        
        // check meta is not nil, has permission, record is not Empty
        (viewModel.dataSource as? LinkPanelDataService)?.filterInfoValidMock = (true, "")
        let records = [BTRecordModel(recordID: "record1", visible: true), BTRecordModel(recordID: "record2")]
        let nextMode5 = viewModel.getNextMode(by: meta, records: records)
        if case let .showData(_, visiableRecords) = nextMode5 {
            XCTAssertTrue(visiableRecords.count == 1)
        } else {
            XCTAssertTrue(false)
        }
        
        // check meta is not nil, has permission, record is Empty, searchText is not Empty
        viewModel.searchText = "searchKey"
        let nextMode6 = viewModel.getNextMode(by: meta, records: nil)
        if case .searchEmpty = nextMode6 {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        
        // check meta is not nil, has permission, record is Empty, searchText is Empty
        viewModel.searchText = ""
        let nextMode7 = viewModel.getNextMode(by: meta, records: nil)
        if case .listEmpty = nextMode7 {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
}
