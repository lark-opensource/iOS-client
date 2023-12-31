//
//  BTActionModel.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/17.
//  


import UIKit
import HandyJSON
import SpaceInterface
import SKCommon
import SKFoundation
import SKInfra
import SKBrowser

// MARK: - 卡片操作
/// JS Bridge `performCardAction` 的传参
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTActionParamsModel: HandyJSON, SKFastDecodable {
    var action: BTActionFromJS = .showCard
    var data: BTPayloadModel = BTPayloadModel()
    var callback: String = ""
    var timestamp: Double = 0
    var transactionId: String = ""
    // 第 0 层卡片的信息
    var originBaseID: String = ""
    var originTableID: String = ""

    static func deserialized(with dictionary: [String : Any]) -> BTActionParamsModel {
        var model = BTActionParamsModel()
        model.action <~ (dictionary, "action")
        model.data <~ (dictionary, "data")
        model.callback <~ (dictionary, "callback")
        model.timestamp <~ (dictionary, "timestamp")
        model.transactionId <~ (dictionary, "transactionId")
        model.originBaseID <~ (dictionary, "originBaseID")
        model.originTableID <~ (dictionary, "originTableID")
        return model
    }

}

protocol BTActionTask: CustomStringConvertible {
    func completedBlock()
    func setCompleted(block: @escaping () -> Void)
}

class BTBaseActionTask: BTActionTask {
    
    private var _completedBlock: () -> Void = {
        DocsLogger.btInfo("[BTTaskQueueManager] BTActionTask default completedBlock exec")
    }
    private var hasCompleted: Bool = false
    private var initTime: Date = Date()
    
    deinit {
        if !UserScopeNoChangeFG.YY.bitableCardQueueBlockedFixDisable, !hasCompleted {
            // 增加兜底保护逻辑，避免出现忘记调用 completedBlock 导致阻塞问题
            DocsLogger.btError("[BTTaskQueueManager] BTActionTask has not Completed!!!")
            completedBlock()
        }
    }
    
    var description: String {
        "baseAction"
    }
    
    func setCompleted(block: @escaping () -> Void) {
        _completedBlock = block
    }
    
    func completedBlock() {
        DocsLogger.btInfo("[BTTaskQueueManager] BTActionTask completedBlock exec. costTime: \(Date().timeIntervalSince(initTime))")
        hasCompleted = true
        _completedBlock()
    }
}

final class BTCardActionTask: BTBaseActionTask {
    var actionParams: BTActionParamsModel = BTActionParamsModel()
    
    override var description: String {
        "cardAction \(actionParams.action)"
    }
}

final class BTGroupingActionTask: BTBaseActionTask {
    var groupingModel: BTGroupingStatisticsModel = BTGroupingStatisticsModel()
    
    override var description: String {
        "groupingAction \(groupingModel.type)"
    }
}
    
/// 前端通过biz.bitable.preformNotifyAction 通知native的事件类型
enum BTPerformNotifyAction: String {
    case tableSwitched // 切换table事件
}

/// 前端通过 JSBridge 通知 Native 进行的卡片操作（对应前端的 `ESetCardsAction`）
enum BTActionFromJS: String, HandyJSONEnum, SKFastDecodableEnum {
    case showCard                   // 打开第 0 层卡片（关联卡片不通过这个打开）
    case tableRecordsDataLoaded     // 打开第 >0 层卡片（通知关联数据已到达，可以 kickoff 了）
    case updateRecord               // 字段值发生了变更
    case updateField                // 表格结构（例如字段类型 字段名）发生了变更
    case recordFiltered             // 当前记录被远端筛选掉了
    case linkTableChanged           // 所有涉及到关联记录的修改，包括 关联字段被删、关联关系变更、关联记录变更。因此只作用到第 1 层及以上的记录卡片
    case deleteRecord               // 当前记录被删除（然后就会退出这层卡片）
    case closeCard                  // 退出卡片视图
    case formFieldsValidate         // 提交表单出错误
    case showManualSubmitCard       // 高级权限表格新加记录
    case switchCard                 // 滚动到指定card
    case scrollCard                 // 滚动卡片内容到指定field
    case submitResult               // 表单/提交模式的提交结果
    case bitableIsReady             // table数据已经加载完成
    case showLinkCard               // 新增关联记录后直接打开关联卡片
    case setCardHidden              // 强制隐藏当前 card（如果有）举报申诉页面场景会被用到
    case setCardVisible             // 恢复显示当前被强制隐藏的 card（如果有）举报申诉页面场景会被用到
    case showIndRecord              // 打开独立的记录卡片
    case fieldsValidate             // 阶段字段详情流转，必填字段没填
    case showAddRecord              // 打开快捷新建记录页
    case addRecordResult            // 快捷新建记录页提交结果
}

enum BTSubmitResultCode: Int, HandyJSONEnum, SKFastDecodableEnum {
    case successed = 0
    case unknown = 1
    case canceled = 2
}

enum BTCardOpenSource: String, HandyJSONEnum, SKFastDecodableEnum {
    case normal = "normal" // 普通文档
    case templatePreview = "template_preview" // 模版预览
}

/// 前端传过来的卡片数据（对应前端的 `IShowCardPayload`）
/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTPayloadModel: HandyJSON, SKFastDecodable {
    var baseId: String = ""
    /// 不建议直接使用这个值，对于未命名的情况会显示异常，建议使用 baseNameAdaptedForUntitled
    var baseName: String = ""
    /// Base 名字，适配了未命名的场景
    var baseNameAdaptedForUntitled: String {
        if baseName.isEmpty {
            return DocsType.bitable.untitledString
        } else {
            return baseName
        }
    }
    var tableId: String = ""
    var viewId: String = ""
    var recordId: String = ""
    var groupValue: String = ""
    var bizType: String = ""
    var fieldId: String = ""
    var topFieldId: String = ""
    var highLightType: BTFieldHighlightMode = .none
    var colors: [String] = []
    var showConfirm: Bool = false
    var showCancel: Bool = false
    var forbiddenSubmit: Bool = false
    var forbiddenSubmitReason: ForbiddenSubmitReason = ForbiddenSubmitReason()
    var fields: [String: BTFormSubmitCellError] = [:]
    var bitableIsReady: Bool = true // 默认值为true，因为showCard不会传viewMode
    /// 顶部提示类型
    var topTipType: BTTopTipType = .none
    var stackViewId: String = "" // 规则为$stackType_$tableId_$fieldId?
    /// 卡片打开来源
    var openSource: BTCardOpenSource = .normal
    var viewType: ViewType = .grid
    
    /// 支持卡片数据直出的数据（加速卡片加载，一次渲染完成）
    var tableMeta: BTTableMeta?
    var recordsData: BTTableValue?
    var preMockRecordId: String?
    var addRecordResult: BTAddRecordResult?
    var submitResultCode: BTSubmitResultCode?
    
    var logString: String {
        return """
                baseId:\(baseId) tableId:\(tableId) viewId:\(viewId) recordId:\(recordId) 
                groupValue:\(groupValue) bizType:\(bizType) fieldId:\(fieldId)
                topFieldId:\(topFieldId) bitableIsReady:\(bitableIsReady)
                openSource:\(openSource) viewType:\(viewType)
               """
    }

    static func deserialized(with dictionary: [String : Any]) -> BTPayloadModel {
        var model = BTPayloadModel()
        model.baseId <~ (dictionary, "baseId")
        model.baseName <~ (dictionary, "baseName")
        model.tableId <~ (dictionary, "tableId")
        model.viewId <~ (dictionary, "viewId")
        model.recordId <~ (dictionary, "recordId")
        model.groupValue <~ (dictionary, "groupValue")
        model.bizType <~ (dictionary, "bizType")
        model.fieldId <~ (dictionary, "fieldId")
        model.topFieldId <~ (dictionary, "topFieldId")
        model.highLightType <~ (dictionary, "highLightType")
        model.colors <~ (dictionary, "colors")
        model.showConfirm <~ (dictionary, "showConfirm")
        model.showCancel <~ (dictionary, "showCancel")
        model.forbiddenSubmit <~ (dictionary, "forbiddenSubmit")
        model.forbiddenSubmitReason <~ (dictionary, "forbiddenSubmitReason")
        model.submitResultCode <~ (dictionary, "submitResultCode")
        model.fields <~ (dictionary, "fields")
        model.bitableIsReady <~ (dictionary, "bitableIsReady")
        model.topTipType <~ (dictionary, "topTipType")
        model.stackViewId <~ (dictionary, "stackViewId")
        model.openSource <~ (dictionary, "openSource")
        model.viewType <~ (dictionary, "viewType")
        model.tableMeta <~ (dictionary, "tableMeta")
        model.recordsData <~ (dictionary, "recordsData")
        model.preMockRecordId <~ (dictionary, "preMockRecordId")
        model.addRecordResult <~ (dictionary, "addRecordResult")
        return model
    }
    
    mutating func updateField(field: String, highLightType: BTFieldHighlightMode) {
        self.fieldId = field
        self.highLightType = highLightType
    }
}

enum AddRecordResultType: Int, HandyJSONEnum, SKFastDecodableEnum {
    case successed = 0
    case failed = 1
}

struct AddRecordSubmitResult: HandyJSON, SKFastDecodable, CustomStringConvertible {
    
    enum ErrorCode: Int {
        /// 提交失败，Base 不存在
        case baseNotFound = 3
        /// 提交失败，Base 无权限
        case baseNoPerm = 4
        /// 提交失败，Base 被删除
        case baseIsDeleted = 1002
        /// 提交失败，数据表找不到（不存在/被删除）
        case tableNotExist = 800004000
        /// 提交失败，没有记录添加权限
        case noRecordAddPerm = 800004011
        /// 超过权益行数限制
        case errOverRowQuotaLimit = 800004333
        /// 超过系统行数限制
        case errExceedMaxRecord = 800004024
    }
    
    var errorCode: Int?
    var recordId: String?
    var unpermittedFields: [String]?
    var submitSuccessTime: Int?
    
    static func deserialized(with dictionary: [String : Any]) -> Self {
        var model = Self.init()
        model.errorCode <~ (dictionary, "errorCode")
        model.recordId <~ (dictionary, "recordId")
        model.unpermittedFields <~ (dictionary, "unpermittedFields")
        model.submitSuccessTime <~ (dictionary, "submitSuccessTime")
        return model
    }
    
    public var description: String {
        "AddRecordSubmitResult:{errorCode:\(errorCode ?? 0),recordId:\(recordId ?? "nil"),unpermittedFields:\(unpermittedFields ?? []),submitSuccessTime:\(submitSuccessTime ?? 0)}"
    }
}

struct AddRecordApplyResult: HandyJSON, SKFastDecodable, CustomStringConvertible {
    
    enum Status: Int, HandyJSONEnum, SKFastDecodableEnum {
        case pending    = 0
        case done       = 1
    }
    
    enum ErrorCode: Int {
        /// 提交成功，结果轮询超时
        case timeout    = 110110
        /// 提交成功，没有查看权限
        case noViewPerm = 120120
    }

    var errorCode: Int?
    var status: Status?
    var recordShareToken: String?
    
    static func deserialized(with dictionary: [String : Any]) -> Self {
        var model = Self.init()
        model.errorCode <~ (dictionary, "errorCode")
        model.status <~ (dictionary, "status")
        model.recordShareToken <~ (dictionary, "recordShareToken")
        return model
    }
    
    public var description: String {
        "AddRecordApplyResult:{errorCode:\(errorCode ?? 0),status:\(String(describing: status)),recordShareToken:\(recordShareToken ?? "nil")}"
    }
}

struct BTAddRecordResult: HandyJSON, SKFastDecodable, CustomStringConvertible {
    var result: AddRecordResultType = .failed
    var submitResult: AddRecordSubmitResult?
    var applyResult: AddRecordApplyResult?
    
    static func deserialized(with dictionary: [String : Any]) -> Self {
        var model = Self.init()
        model.result <~ (dictionary, "result")
        model.submitResult <~ (dictionary, "submitResult")
        model.applyResult <~ (dictionary, "applyResult")
        return model
    }
    
    public var description: String {
        "BTAddRecordResult:{result:\(result),submitResult:\(submitResult?.description ?? "nil"),applyResult:\(applyResult?.description ?? "nil")}"
    }
}

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct BTFormSubmitCellError: HandyJSON, SKFastDecodable {
    var errorMsg: String = ""
    var errorCode: Int = 0
    
    static func deserialized(with dictionary: [String : Any]) -> BTFormSubmitCellError {
        var model = BTFormSubmitCellError()
        model.errorCode <~ (dictionary, "errorCode")
        model.errorMsg <~ (dictionary, "errorMsg")
        return model
    }
}

/// 后续新增属性需要在deserialized(with dictionary: [String : Any])里添加对应属性
struct ForbiddenSubmitReason: HandyJSON, SKFastDecodable {
    var title: String = ""
    var reason: String = ""
    var icon: String = ""
    
    static func deserialized(with dictionary: [String : Any]) -> ForbiddenSubmitReason {
        var model = ForbiddenSubmitReason()
        model.title <~ (dictionary, "title")
        model.reason <~ (dictionary, "reason")
        model.icon <~ (dictionary, "icon")
        return model
    }
}

enum BTFieldHighlightMode: Int, HandyJSONEnum, SKFastDecodableEnum {
    case none = 0
    case temporary = 1
}

/// 用户对卡片的操作类型（对应前端的 `ECardAction`）
enum BTActionFromUser: String, HandyJSONEnum {
    case open
    case `switch`
    case forwardLinkTable  // 进入新的关联记录卡片（新建一层）
    case backwardLinkTable // 从关联记录卡片回到刚刚的卡片
    case cancel
    case exit
    case confirm
    case confirmForm
    case editRecord
    case addLinkedRecord // 新建卡片并建立关联关系
    case toggleHiddenFieldsDisclosure
    case deleteRecord
    case submitResult // 表单再填一次
    case setSubmitTopTipShow // 先填写记录再添加记录提示
    case clickTip // CTA收费提示回调
    case createGroup
    case continueSubmit // 继续创建下一条记录
}

struct BTMediaUploadInfo: Equatable {
    let jobKey: String
    let progress: Float
    let fileToken: String
    let status: DocCommonUploadStatus
    let mediaInfo: BTUploadMediaHelper.MediaInfo
    var mountPoint: String {
        get {
            mediaInfo.mountPoint.rawValue
        }
    }

    var attachmentModel: BTAttachmentModel {
        return BTAttachmentModel(attachmentToken: fileToken,
                                 id: fileToken,
                                 mimeType: mediaInfo.driveType.mimeType,
                                 name: mediaInfo.name,
                                 size: mediaInfo.byteSize,
                                 timeStamp: 0,
                                 width: mediaInfo.width,
                                 height: mediaInfo.height,
                                 category: mediaInfo.driveType.isImage ? 1 : 2,
                                 mountPointType: mountPoint,
                                 mountToken: mediaInfo.destinationBaseID)
    }
}

struct BTFieldLocation: Hashable, CustomStringConvertible {
    let originBaseID: String // 第 0 层卡片
    let originTableID: String // 第 0 层卡片

    let baseID: String // 多维表格
    let tableID: String // 子表
    let viewID: String // 视图
    let recordID: String // 记录
    let fieldID: String // 字段

    var description: String {
        "baseID \(DocsTracker.encrypt(id: baseID)) table \(tableID) record \(recordID) field \(fieldID)"
    }
}

public enum BTTopTipType: Int, Equatable, HandyJSONEnum, SKFastDecodableEnum {
    case none = 0
    case recordLimit = 1
}
