//
// Created by duanxiaochen.7 on 2022/3/21.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import HandyJSON
import SKCommon
import SKInfra

enum BTRecordValueStatus: Equatable {
    case loading
    case timeOut(request: BTGetCardListRequest)
    case failed
    case success
}

/// 一条记录（即一张卡片）的信息（对应前端的 `IRecordInfo`）
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTRecordValue: HandyJSON, SKFastDecodable {
    var recordId: String = ""
    var isFiltered: Bool = false
    var headerBarColor: String = ""
    var fields: [BTFieldValue] = []
    var deletable: Bool = false
    var visible: Bool = true
    var editable: Bool = false
    var shareable: Bool = false
    var groupValue: String = "" //分组ID，看板视图有用，透传给前端
    var globalIndex: Int = 0 //表示当前卡片基于整表的index
    var dataStatus: BTRecordValueStatus = .success
    var isArchived: Bool = false
    
    //唯一标识ID，看板视图下列表中可能会出现多张recordId一样的卡片
    var identify: String {
        recordId + groupValue
    }
    
    /// 记录标题，不带样式
    var recordTitle: String = ""

    static func deserialized(with dictionary: [String : Any]) -> BTRecordValue {
        var model = BTRecordValue()
        model.recordId <~ (dictionary, "recordId")
        model.isFiltered <~ (dictionary, "isFiltered")
        model.headerBarColor <~ (dictionary, "headerBarColor")
        model.fields <~ (dictionary, "fields")
        model.deletable <~ (dictionary, "deletable")
        model.visible <~ (dictionary, "visible")
        model.editable <~ (dictionary, "editable")
        model.shareable <~ (dictionary, "shareable")
        model.groupValue <~ (dictionary, "groupValue")
        model.globalIndex <~ (dictionary, "globalIndex")
        model.dataStatus <~ (dictionary, "dataStatus")
        model.recordTitle <~ (dictionary, "recordTitle")
        model.isArchived <~ (dictionary, "isArchived")
        return model
    }

}
