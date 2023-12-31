//
//  BTTableValue.swift
//  SKBitable
//
//  Created by linxin on 2020/3/23.
//


import Foundation
import HandyJSON
import SKCommon
import SKInfra

// MARK: - 某张表格指定视图的全部 record ID 列表
struct BTTableRecordIDList: HandyJSON, Equatable {
    var baseId: String = ""
    var tableId: String = ""
    var recordIds: [String] = []
    var timestamp: Double = 0
}


// MARK: - 获取卡片数据
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTTableValue: HandyJSON, SKFastDecodable {
    var baseId: String = ""
    var tableId: String = ""
    var loaded: Bool = true //数据是否加载完成
    var total: Int = 0 //总卡片数量
    var activeIndex: Int = 0
    var records: [BTRecordValue] = []
    var timestamp: Double = 0
    var formBannerUrl: String? // 平铺处理，非json解的字段

    static func deserialized(with dictionary: [String : Any]) -> BTTableValue {
        var model = BTTableValue()
        model.baseId <~ (dictionary, "baseId")
        model.tableId <~ (dictionary, "tableId")
        model.loaded <~ (dictionary, "loaded")
        model.total <~ (dictionary, "total")
        model.activeIndex <~ (dictionary, "activeIndex")
        model.records <~ (dictionary, "records")
        model.timestamp <~ (dictionary, "timestamp")
        return model
    }

}
