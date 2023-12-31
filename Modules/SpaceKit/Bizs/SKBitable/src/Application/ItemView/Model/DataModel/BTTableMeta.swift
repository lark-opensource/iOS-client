//
// Created by duanxiaochen.7 on 2022/3/22.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import HandyJSON
import SKCommon
import SKBrowser
import SKInfra
import SKFoundation

enum CardCloseReason: String, HandyJSONEnum, SKFastDecodableEnum {
    case stageFieldInvalid // 在阶段详情页因为字段被删需要关闭
    case other
}

// MARK: - 获取卡片结构
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTTableMeta: HandyJSON, Equatable, SKFastDecodable {
    var timestamp: Double = 0
    var timeZone: String = ""
    var colors: [BTColorModel] = []
    var buttonColors: [BTButtonColorModel] = []
    var bizType: String = ""
    var viewType: String = "grid"
    var fields: [String: BTFieldMeta] = [:]
    var primaryFieldId: String = ""  // 关联表格的主键 ID
    var tableName: String = ""
    var recordAddable: Bool = false
    var currentViewName: String = "" // 表单视图的标题
    var currentViewDescription: BTDescriptionModel? // 表单副标题
    var tableVisible: Bool = true // 表格是否有查看权限
    var shouldDiscloseHiddenFields: Bool = false // 隐藏字段是否应该展开显示
    var submitTopTipShowed: Bool = false // 先填写再提交tip是否显示过了
    var viewUnreadableRequiredField: Bool = false // 是否包含无阅读权限的field
    var isFormulaServiceSuspend: Bool? // true代表是scheme4新文档
    var cardCloseReason: CardCloseReason? // 因为一些原因需要关闭卡片
    var stackViewId: String? // 规则为$stackType_$tableId_$fieldId? 用来标记卡片或者阶段详情
    var isPro: Bool = false // 表格是否开启了高级权限
    var cardCoverId: String = ""
    var coverChangeAble: Bool = false
    var isPartial: Bool = false

    static func deserialized(with dictionary: [String : Any]) -> BTTableMeta {
        var model = BTTableMeta()
        model.timestamp <~ (dictionary, "timestamp")
        model.timeZone <~ (dictionary, "timeZone")
        model.colors <~ (dictionary, "colors")
        model.buttonColors <~ (dictionary, "buttonColors")
        model.bizType <~ (dictionary, "bizType")
        model.viewType <~ (dictionary, "viewType")
        model.fields <~ (dictionary, "fields")
        model.primaryFieldId <~ (dictionary, "primaryFieldId")
        model.tableName <~ (dictionary, "tableName")
        model.recordAddable <~ (dictionary, "recordAddable")
        model.currentViewName <~ (dictionary, "currentViewName")
        model.currentViewDescription <~ (dictionary, "currentViewDescription")
        model.tableVisible <~ (dictionary, "tableVisible")
        model.shouldDiscloseHiddenFields <~ (dictionary, "shouldDiscloseHiddenFields")
        model.submitTopTipShowed <~ (dictionary, "submitTopTipShowed")
        model.viewUnreadableRequiredField <~ (dictionary, "viewUnreadableRequiredField")
        model.isFormulaServiceSuspend <~ (dictionary, "isFormulaServiceSuspend")
        model.cardCloseReason <~ (dictionary, "cardCloseReason")
        model.stackViewId <~ (dictionary, "stackViewId")
        model.isPro <~ (dictionary, "isPro")
        model.cardCoverId <~ (dictionary, "cardCoverId")
        model.coverChangeAble <~ (dictionary, "coverChangeAble")
        model.isPartial <~ (dictionary, "isPartial")

        if !UserScopeNoChangeFG.LYL.enableAttachmentCover {
            model.cardCoverId = ""
            model.coverChangeAble = false
        }

        return model
    }
}
