//
//  CatalogManagerTests.swift
//  SKDoc_Tests-Unit-_Tests
//
//  Created by chensi(陈思) on 2022/7/1.
//  


import Foundation
import UIKit
@testable import SKDoc
@testable import SKCommon
@testable import SKBrowser
@testable import SKUIKit
import XCTest

class CatalogManagerTests: XCTestCase {
    
    private var manager: CatalogManager!
    
    private let displayer = FakeDisplayer()
    
    private let catalogData: [CatalogItemDetail] = [CatalogItemDetail(title: "H1标题1", level: 1, yOffset: 20),
                                            CatalogItemDetail(title: "H2标题2", level: 2, yOffset: 40)]
    
    private let scrollProxy = WebViewNoZoomScrollViewProxyImpl()
    
    override func setUp() {
        super.setUp()
        manager = CatalogManager(attach: displayer, proxy: scrollProxy, toolBar: nil, jsEngine: nil, navigator: nil)
        manager.prepareCatalog(catalogData)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPrepareCatalog() {
        let result = manager.catalogDetails()
        XCTAssertTrue(result?.first?.title == catalogData.first?.title)
        XCTAssertTrue(result?.last?.title == catalogData.last?.title)
    }
    
    func testConfigIPadCatalog() {
        manager.configIPadCatalog(true, autoPresentInEmbed: false, complete: { mode in
            XCTAssert(mode == .covered)
        })
    }
    
    func testIndicatorDidMovedVertical() {
        manager.indicatorDidMovedVertical(indicator: BrowseCatalogIndicator())
        XCTAssert(manager.timer == nil)
    }
    
    func testShowCatalogDetails() {
        manager.showCatalogDetails()
        let result = manager.catalogDetails()
        XCTAssertTrue(result?.first?.title == catalogData.first?.title)
    }
    
    func testPutSideAndBottomEntry() {
        manager.indicatorDidClicked(indicator: BrowseCatalogIndicator())
        XCTAssert(manager.catalogSideView != nil)
    }
    
    func testOnCopyPermissionUpdated() {
        manager.onCopyPermissionUpdated(canCopy: true)
        XCTAssertTrue(manager.catalogViewAllowCapture)
    }
    
    func testCloseCatalog() {
        manager.closeCatalog()
        let catalogDatas = manager.catalogDetails()
        XCTAssert(manager.catalogSideView == nil)
        XCTAssert(catalogDatas == nil)
    }
    
    func testCatalogDidReceivedScroll() {
        manager.catalogDidReceiveBeginDragging(info: nil)
        manager.catalogDidReceivedScroll(isEditPool: false, hideCatalog: true, isOpenSDK: false, info: DocsInfo(type: .docX, objToken: "doxcn123456789"))
        XCTAssert(manager.catalogSideView == nil)
        XCTAssert(manager.catalogBottomEntry == nil)
    }
    
    func testHideCatalog() {
        manager.hideCatalog()
        let expect = expectation(description: "test hide catalog")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            expect.fulfill()
            XCTAssert(self.manager.catalogSideView == nil)
            XCTAssert(self.manager.catalogBottomEntry == nil)
        }
        
        waitForExpectations(timeout: 6) { error in
            XCTAssertNil(error)
        }
        
    }
    
    func testSetCatalogOrentations() {
        manager.setCatalogOrentations(.landscape)
        XCTAssert(manager.supportOrentations == .landscape)
    }
    
    func testCatalogReadyToDisplay() {
        manager.catalogDidReceiveBeginDragging(info: DocsInfo(type: .sheet, objToken: "shtcn123456789"))
        let ready = manager.catalogReadyToDisplay()
        XCTAssert(ready == false)
    }
    
    func testSetCurDocsType() {
        manager.setCurDocsType(type: .doc)
        XCTAssert(manager.docsType == .doc)
        manager.setCurDocsType(type: .docX)
        XCTAssert(manager.docsType == .docX)
        
    }
    
}

private class FakeDisplayer: UIView, CatalogPadDisplayer {
    func presentCatalogSideView(catalogSideView: IPadCatalogSideView, autoPresentInEmbed: Bool, complete: ((_ mode: IPadCatalogMode) -> Void)?) {
        complete?(.covered)
    }
    func dismissCatalogSideView(complete: @escaping () -> Void) {
        complete()
    }
    func dismissCatalogSideViewByTapContent(complete: @escaping () -> Void) {
        complete()
    }
}
