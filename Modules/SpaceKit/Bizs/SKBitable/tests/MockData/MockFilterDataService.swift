//
//  MockFilterService.swift
//  SKBitable_Tests
//
//  Created by zengsenyuan on 2022/8/4.
//  


@testable import SKBitable
import RxSwift
import RxCocoa

let mockFilterPrefixPath = "JSONDatas/filterJson/"


class MockFilterDataService: BTFilterDataServiceType {
    
    func getFieldOptions(by fieldId: String,
                         with keywords: String?,
                         router: SKBitable.BTAsyncRequestRouter,
                         responseHandler: @escaping (Result<SKBitable.BTAsyncResponseModel, SKBitable.BTAsyncRequestError>) -> Void,
                         resultHandler: ((Result<Any?, Error>) -> Void)?) {
        var model = BTAsyncResponseModel()
        model.data = [
            "data": [["id": "chatterId", "name": "name", "avatarUrl": "avatarUrl", "linkToken": "linkToken"]]
        ]
        model.result = 0
        let result = Result<BTAsyncResponseModel, BTAsyncRequestError>.success(model)
        responseHandler(result)
    }
    
    
    func getFieldLinkOptionsByIds(byFieldId fieldId: String,
                                  recordIds slectedIds: [String],
                                  responseHandler: @escaping (Result<SKBitable.BTAsyncResponseModel, SKBitable.BTAsyncRequestError>) -> Void,
                                  resultHandler: ((Result<Any?, Error>) -> Void)?) {
    }
    
    func getNewConditionIds(ids: [String], total: Int) -> RxSwift.Single<[String]> {
        var mockConditionIds: [String] = []
        var i = 0
        while i < total {
            mockConditionIds.append("mock_conditionId_" + String(i))
            i += 1
        }
        return .just(mockConditionIds)
    }
    
    
    func getFilterInfo() -> Single<BTFilterInfos> {
        let result: BTFilterInfos = MockJSONDataManager.getHandyJSONModelByParseData(filePath: mockFilterPrefixPath + "filterInfos_tbldye4HEEJhjb5k")
        return .just(result)
    }
    
    func getFieldFilterOptions() -> Single<BTFilterOptions> {
        let result: BTFilterOptions = MockJSONDataManager.getCodableModelByParseData(filePath: mockFilterPrefixPath + "filterOptions")
        return .just(result)
        
    }
    
    func getFieldLinkOptions(byFieldId fieldId: String) -> Single<BTFilterLinkOptions> {
        let result: BTFilterLinkOptions = MockJSONDataManager.getCodableModelByParseData(filePath: mockFilterPrefixPath + "filterLinks_fld9wXa0A6")
        return .just(result)
        
    }
    
    func getFieldUserOptions(byFieldId fieldId: String) -> Single<BTFilterUserOptions> {
        return .just(BTFilterUserOptions())
    }
    
    func getFieldDurations(byRule rule: String) -> Single<BTFilterDurations> {
        let result: BTFilterDurations = MockJSONDataManager.getCodableModelByParseData(filePath: mockFilterPrefixPath + "filterDurations")
        return .just(result)
        
    }
    
    func getColorList(byFieldId fieldId: String) -> Single<BTColorLists> {
        let result: BTColorLists = MockJSONDataManager.getHandyJSONModelByParseData(filePath: mockFilterPrefixPath + "filterColorList")
        return .just(result)
        
    }
}
