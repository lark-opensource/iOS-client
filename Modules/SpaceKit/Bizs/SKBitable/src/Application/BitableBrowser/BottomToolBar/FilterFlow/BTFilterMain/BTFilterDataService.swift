//
//  BTFilterDataService.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/6/22.
//


import SKFoundation
import SKResource
import SKCommon
import SwiftyJSON
import HandyJSON
import SKBrowser
import RxSwift


final class BTFilterDataService {

    enum QueryType: String {
        case getFilterInfo
        case getFilterOptions
        case getFieldUserOptions
        case getFieldLinkOptions
        case getFilterDurations
        case getFieldLinkByRecordIds
    }
    
    private var jsService: SKExecJSFuncService
    
    private weak var dataService: BTDataService?
    
    private var baseData: BTBaseData
    
    private var baseDataParams: [String: Any] {
        var params: [String: Any] = [:]
        params["baseId"] = baseData.baseId
        params["tableId"] = baseData.tableId
        params["viewId"] = baseData.viewId
        return params
    }
    
    init(baseData: BTBaseData, jsService: SKExecJSFuncService, dataService: BTDataService?) {
        self.baseData = baseData
        self.jsService = jsService
        self.dataService = dataService
    }
    
    func updateBaseData(_ baseData: BTBaseData) {
        self.baseData = baseData
    }
    
    func getQueryParams(type: QueryType, fieldId: String? = nil, rule: String? = nil) -> [String: Any] {
        var _params = baseDataParams
        if let fieldId = fieldId {
            _params.updateValue(fieldId, forKey: "fieldId")
        }
        if let rule = rule {
            _params.updateValue(rule, forKey: "operator")
        }
        return [
            "type": type.rawValue,
            "params": _params
        ]
    }
}

struct BTColorLists: HandyJSON {
    var ColorList: [BTColorModel] = []
}

protocol BTFilterDataServiceType {
    func getFilterInfo() -> Single<BTFilterInfos>
    func getFieldFilterOptions() -> Single<BTFilterOptions>
    func getFieldLinkOptionsByIds(byFieldId fieldId: String,
                                  recordIds: [String],
                                  responseHandler: @escaping(Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                                  resultHandler: ((Result<Any?, Error>) -> Void)?)
    /// 根据关键词获取FieldOptions
    func getFieldOptions(by fieldId: String,
                         with keywords: String?,
                         router: BTAsyncRequestRouter,
                         responseHandler: @escaping (Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                         resultHandler: ((Result<Any?, Error>) -> Void)?)
    func getNewConditionIds(ids: [String], total: Int) -> Single<[String]>
    func getFieldDurations(byRule rule: String) -> Single<BTFilterDurations>
    func getColorList(byFieldId fieldId: String) -> Single<BTColorLists>
}

// MARK: jsInterface
extension BTFilterDataService: BTFilterDataServiceType {
    
    var funcName: DocsJSCallBack {
        return .asyncJsRequest
    }

    /// 获取当前筛选条件
    func getFilterInfo() -> Single<BTFilterInfos> {
        let params = getQueryParams(type: .getFilterInfo)
        return jsService.rxCallFuctionWithHandyJSON(DocsJSCallBack.btQuery,
                                                    params: params,
                                                    defaultValueWhenDataNil: BTFilterInfos()).asSingle()
    }
    /// 获取字段数据
    func getFieldFilterOptions() -> Single<BTFilterOptions> {
        let params = getQueryParams(type: .getFilterOptions)
        return jsService.rxCallFuctionWithCodable(DocsJSCallBack.btQuery, params: params).asSingle()
    }
    
    /// 根据fieldId关键词获取FieldOptions
    func getFieldOptions(by fieldId: String,
                         with keywords: String?,
                         router: BTAsyncRequestRouter,
                         responseHandler: @escaping (Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                         resultHandler: ((Result<Any?, Error>) -> Void)?) {
        var params: [String: Any] = [:]
        params["data"] = baseDataParams
        params["tableId"] = baseData.tableId
        params["router"] = router.rawValue
        if var p = params["data"] as? [String: Any] {
            p["keywords"] = keywords
            p["fieldId"] = fieldId
            params["data"] = p
        }
        dataService?.asyncJsRequest(biz: .toolBar,
                                    funcName: funcName,
                                    baseId: baseData.baseId,
                                    tableId: baseData.tableId,
                                    params: params,
                                    overTimeInterval: nil,
                                    responseHandler: responseHandler,
                                    resultHandler: resultHandler)
    }
    
    /// 根据ID获取关联记录数据
    func getFieldLinkOptionsByIds(byFieldId fieldId: String,
                                  recordIds: [String],
                                  responseHandler: @escaping(Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                                  resultHandler: ((Result<Any?, Error>) -> Void)?) {
        var params: [String: Any] = [:]
        params["data"] = baseDataParams
        params["tableId"] = baseData.tableId
        params["router"] = QueryType.getFieldLinkByRecordIds.rawValue
        
        if var p = params["data"] as? [String: Any] {
            p["recordIds"] = recordIds
            p["fieldId"] = fieldId
            params["data"] = p
        }
        
        dataService?.asyncJsRequest(biz: .toolBar,
                                    funcName: funcName,
                                    baseId: baseData.baseId,
                                    tableId: baseData.tableId,
                                    params: params,
                                    overTimeInterval: nil,
                                    responseHandler: responseHandler,
                                    resultHandler: resultHandler)
    }
    
    /// 获取日期数据
    func getFieldDurations(byRule rule: String) -> Single<BTFilterDurations> {
        let params = getQueryParams(type: .getFilterDurations, rule: rule)
        return jsService.rxCallFuctionWithCodable(DocsJSCallBack.btQuery, params: params).asSingle()
    }
    /// 获取选项的颜色列表
    func getColorList(byFieldId fieldId: String) -> Single<BTColorLists> {
        var _params = baseDataParams
        _params.updateValue(fieldId, forKey: "fieldId")
        let params: [String: Any] = [
            "type": BTEventType.colorList.rawValue,
            "params": _params
        ]
        return jsService.rxCallFuctionWithHandyJSON(DocsJSCallBack.btGetBitableCommonData, params: params).asSingle()
    }
    
    func getNewConditionIds(ids: [String], total: Int) -> Single<[String]> {
        var _params = baseDataParams
        _params["total"] = total
        _params["ids"] = ids
        let params: [String: Any] = [
            "type": BTEventType.getNewConditionIds.rawValue,
            "params": _params
        ]
        
        return jsService.rxCallFuction(DocsJSCallBack.btGetBitableCommonData, params: params, parseData: { result in
            return result as? [String]
        }).asSingle()
    }
}
