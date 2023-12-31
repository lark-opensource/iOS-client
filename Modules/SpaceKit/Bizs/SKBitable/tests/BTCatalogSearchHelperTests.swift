//
//  BTCatalogSearchHelperTests.swift
//  SKBitable-Unit-Tests
//
//  Created by zoujie on 2023/9/23.
//  

import XCTest
@testable import SKBitable

class BTCatalogSearchHelperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSearch() {
        let item = BTCommonDataItem(
            id: "id",
            mainTitle: .init(text: "ceshi")
        )
        
        let data = BTCommonDataGroup(
            groupName: "",
            items: [item]
        )
        
        let result = BTCatalogSearchHelper.getSearchResult(datas: [data], searchKey: "ceshi")
        XCTAssertFalse(result.isEmpty)
    }
}
