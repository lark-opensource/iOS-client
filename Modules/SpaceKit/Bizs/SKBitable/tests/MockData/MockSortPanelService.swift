//
//  MockSortPanelService.swift
//  SKBitable_Tests
//
//  Created by zengsenyuan on 2022/8/4.
//  


@testable import SKBitable
import RxSwift
import RxCocoa

class MockSortPanelService: BTSortPanelDataServiceType {
    
    func getSortData() -> Single<BTSortData> {
        let result: BTSortData = MockJSONDataManager.getCodableModelByParseData(filePath: "JSONDatas/" + "sortPanelData")
        return .just(result)
    }
    
    func updateSortData(newSortData: BTSortData, callback: String) -> Single<Bool> {
        return .just(true)
    }
    
    func notifyCloseSortPanel(callback: String) {
        
    }
}
