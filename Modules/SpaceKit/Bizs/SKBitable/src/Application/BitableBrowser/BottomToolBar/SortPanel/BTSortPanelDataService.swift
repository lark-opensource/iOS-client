//
//  BTSortDataService.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/21.
//  

import SKFoundation
import SKResource
import SKCommon
import RxSwift

struct BTSortData: Codable {
    
    struct OrderOption: Codable {
        var desc: Bool = false //是否是倒序
        var text: String = "" //对应文案
    }
    
    struct SortFieldOption: Codable {
        var id: String //field id
        var name: String //field name
        var type: Int //field type
        var fieldUIType: String? //fieldUIType
        var isSync: Bool?
        var compositeType: BTFieldCompositeType {
            return BTFieldCompositeType(fieldTypeValue: type, uiTypeValue: fieldUIType)
        }
        var invalidType: BTFieldInvalidType? = .other
        var orders: [OrderOption] = []
    }
    
    struct SortFieldInfo: Codable {
        var fieldId: String
        var desc: Bool
    }
    
    var fieldOptions: [SortFieldOption] = []
    var sortInfo: [SortFieldInfo] = []
    var autoSort: Bool = false
    
    /// 是否是按需文档
    var isPartial: Bool = false
    
    /// 顶部提示
    var notice: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case sortInfo, autoSort, fieldOptions, isPartial, notice
    }
    
    init() {}
    
    /// 因为 sortInfo 和 autoSort 可能为空，所以需要特殊处理
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fieldOptions = try values.decode([SortFieldOption].self, forKey: .fieldOptions)
        sortInfo = try values.decodeIfPresent([SortFieldInfo].self, forKey: .sortInfo) ?? []
        autoSort = try values.decodeIfPresent(Bool.self, forKey: .autoSort) ?? false
        isPartial = try values.decodeIfPresent(Bool.self, forKey: .isPartial) ?? false
        notice = try values.decodeIfPresent(String.self, forKey: .notice) ?? nil
    }
    
    func getOrderText(by fieldInfo: SortFieldInfo) -> String {
        let fieldOption = fieldOptions.first(where: { $0.id == fieldInfo.fieldId })
        return fieldOption?.orders.first(where: { $0.desc == fieldInfo.desc })?.text ?? ""
    }
}

protocol BTSortPanelDataServiceType {
    func getSortData() -> Single<BTSortData>
    func updateSortData(newSortData: BTSortData, callback: String) -> Single<Bool>
    func notifyCloseSortPanel(callback: String)
}

final class BTSortPanelDataService: BTSortPanelDataServiceType {

    enum QueryType: String {
        case getSortData
    }
    
    private var jsService: SKExecJSFuncService
    
    private var baseData: BTBaseData
    
    private var baseDataParams: [String: Any] {
        var params: [String: Any] = [:]
        params["baseId"] = baseData.baseId
        params["tableId"] = baseData.tableId
        params["viewId"] = baseData.viewId
        return params
    }
    
    init(baseData: BTBaseData, jsService: SKExecJSFuncService) {
        self.baseData = baseData
        self.jsService = jsService
    }
    /// 获取当前排序条件
    func getSortData() -> Single<BTSortData> {
        let params: [String: Any] = [
            "type": QueryType.getSortData.rawValue,
            "params": baseDataParams
        ]
        return jsService.rxCallFuctionWithCodable(DocsJSCallBack.btQuery, params: params).asSingle()
    }
    /// 更新当前排序条件
    func updateSortData(newSortData: BTSortData, callback: String) -> Single<Bool> {
        let params: [String: Any] = [
            "action": "SortRecord",
            "payload": [
                "autoSort": newSortData.autoSort,
                "sortInfo": newSortData.sortInfo.map { ["fieldId": $0.fieldId, "desc": $0.desc] }
            ]
        ]
        return jsService.rxCallFuction(DocsJSCallBack(callback),
                                       params: params,
                                       parseData: { _ in true },
                                       defaultValueWhenDataNil: true).asSingle()
    }
    /// 通知前端关闭排序面板
    func notifyCloseSortPanel(callback: String) {
        jsService.callFunction(DocsJSCallBack(callback),
                               params: ["action": "CloseSortPanel"],
                               completion: nil)
    }
}
