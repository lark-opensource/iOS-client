//
//  BTFieldModel.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/17.
//  swiftlint:disable cyclomatic_complexity

import Foundation
import UIKit
import SKFoundation
import SKBrowser
import HandyJSON
import SwiftyJSON
import RxDataSources
import SKCommon
import SKResource
import UniverseDesignColor

/// formula and lookup field calculate state
enum BTFormulaCalcState: Int {
  case pending = 0 // 计算中
  case success = 1 // 计算成功
  case failed = 2 // 计算失败
}

/// field meta + field value + other ui models
struct BTFieldModel: Equatable {

    let recordID: String

    private(set) var width: CGFloat = 0

    private(set) var itemViewHeight: CGFloat = 0

    private(set) var fieldID: String = ""
    /// 字段是否正在被编辑
    private(set) var isEditing: Bool = false
    /// 字段是否支持编辑
    private(set) var editable: Bool = false
    /// 按钮字段点击是否可以触发
    private(set) var triggerAble: Bool = false
    /// 不可编辑字段的原因
    private(set) var uneditableReason: BTFieldValue.UneditableReason = .others
    /// 字段是否被隐藏
    private(set) var isHidden: Bool = false

    // MARK: 由于存在 formula、lookup 等引用类型，会分本质类型和表结构类型两种概念
    /// 最终显示在界面上的、只关乎内容的、本质上的字段类型
    /// 如果想要表结构中的类型，见下面的 `compositeType`
    private(set) var extendedType: BTFieldExtendedType = .inherent(.default)
    /// 最终显示在界面上的、只关乎内容的、本质上的字段属性
    private(set) var property: BTFieldProperty = BTFieldProperty()
    /// 编辑能力
    private(set) var allowedEditModes: AllowedEditModes = AllowedEditModes()
    /// 表结构中该字段的类型，并不一定对应内容的真实类型。如果当前是公式或引用字段，那么这里就是所引用的字段。
    /// 如果想要内容类型，见上面的 `extendedType`
    private(set) var compositeType: BTFieldCompositeType = BTFieldCompositeType.default

    // MARK: 实际字段类型 cell 所用到的 UI data
    /// mode
    private(set) var mode: BTViewMode = .card
    /// 是否在表单视图中
    var isInForm: Bool {
        get {
            mode == .form
        }
    }
    /// 是否在Stage视图中
    private(set) var isInStage: Bool = false
    /// 选项字段用到的颜色数组
    private(set) var colors: [BTColorModel] = []
    /// 字段名字 / 问题名字 / 表单名字
    private(set) var name: String = ""
    /// 表单里是否为必填字段
    private(set) var required: Bool = false
    /// 表单里的错误信息
    private(set) var errorMsg: String = ""
    /// 字段警告信息
    private(set) var fieldWarning: String = ""
    /// 字段描述 / 表单问题描述 / 表单副标题
    private(set) var description: BTDescriptionModel?
    /// 是否为同步字段
    private(set) var isSync: Bool = false
    /// 涉及到 BTTextView / BTReadOnlyTextView 的
    private(set) var textValue: [BTRichTextSegmentModel] = []
    /// 多行文本字段禁用的编辑能力
    var forbiddenTextCapabilities: BTTextCapabilityOptions {
        if compositeType.uiType == .barcode {
            return [.activeAtInfoWhenInput]
        } else if compositeType.uiType == .email {
            //如果是 email 类型，禁用 @ 圈人组件和粘贴URL解析
            return [.activeAtInfoWhenInput, .parseAtInfoWhenPaste]
        } else {
            return []
        }
    }
    /// 被选中选项的 optionID，从 meta 里去找， 阶段字段也会用这个
    private(set) var optionIDs: [String] = []
    /// 级联选项被选中选项的 options
    private(set) var dynamicOptions: [BTOptionModel] = []
    /// 上传附件仅支持拍照
    private(set) var onlyCamera: Bool = false
    /// 已经落盘的附件的信息，对应前端的 IAttachmentInfo
    private(set) var attachmentValue: [BTAttachmentModel] = []
    /// 正在上传的附件信息
    private(set) var uploadingAttachments: [BTMediaUploadInfo] = []
    /// 等待上传的附件信息（表单、高级表格新建场景）
    private(set) var pendingAttachments: [PendingAttachment] = []
    /// 本地附件的存储地址
    private(set) var localStorageURLs: [String: URL] = [:]
    /// 数字字段内容
    private(set) var numberValue: [BTNumberModel] = []
    
    /// date、lastModifyTime、createTime 都用这一个
    private(set) var dateValue: [BTDateModel] = []
    /// checkbox 字段
    private(set) var selectValue: [Bool] = []
    
    /// user、lastModifyUser、createUser 都用这一个
    private(set) var users: [BTUserModel] = []
    /// Chatter类型，现在暂时只针对group
    private(set) var groups: [BTGroupModel] = []
    /// 关联字段的被关联记录数组（不一定属于本 table，也可能是本 base 的其他 table）
    private(set) var linkedRecords: [BTRecordModel] = []
    /// 自动编号字段内容
    private(set) var autoNumberValue: [BTAutoNumberModel] = []
    /// 电话号码字段内容
    private(set) var phoneValue: [BTPhoneModel] = []
    /// 地理位置字段
    private(set) var geoLocationValue: [BTGeoLocationModel] = []
    /// 是否正在定位/逆地址
    private(set) var isFetchingGeoLocation: Bool = false

    // MARK: 特殊类型 cell 所用到的 UI data
    // 当 type 不为 .inherent 时，上面所有与实际字段类型 cell 相关的变量都无效

    /// 卡片场景下描述ⓘ按钮是否被点亮
    private(set) var isDescriptionIndicatorSelected: Bool = false
    /// 表单场景下描述内容是否展开
    private(set) var isDescriptionTextLimited: Bool = true
    /// 隐藏字段折叠开关上的数字，是该视图中被隐藏的字段的个数
    private(set) var hiddenFieldsCount: Int = 0
    /// 是否显露被隐藏的字段，该值继承于 table meta
    private(set) var isHiddenFieldsDisclosed: Bool = false
    /// 文档时区
    private(set) var timeZone: String = ""
    /// 查找引用和公式字段类型的计算状态
    private(set) var calcState: BTFormulaCalcState?
    /// 按钮字段属性
    private(set) var buttonConfig: BTButtonModel = BTButtonModel()
    /// 按钮字段颜色配置列表
    private(set) var buttonColors: [BTButtonColorModel] = []
    /// true代表是scheme4新文档
    private(set) var isFormulaServiceSuspend: Bool?
    /// 封面URL，只有放在这里，才能在协同的时候，触发diff更新封面URL
    private(set) var formBannerUrl: String?
    /// 关联表过滤信息
    private(set) var filterInfo: BTFilterInfos?
    /// 被关联记录所在的子表
    private(set) var tableId: String = ""
    /// 所在Record的主键ID
    private(set) var primaryFieldId: String = ""
    // 是否是阶段字段关联字段
    private(set) var isStageLinkField: Bool = false
    private(set) var fieldPermission: BTFieldValue.FieldPermission? = nil // 字段某些权限控制，目前阶段字段在用后需要其他字段需要可进行扩展
    private(set) var isStageCancel: Bool = false
    private(set) var currentStageOptionId: String = ""
    
    /// 所在文档是否开启了高级权限
    private(set) var isPro: Bool = false
    
    // MARK: - UIModel
    
    // 根据 meta 和 value 中的值，解析出布局计算和渲染都需要用的一些公用数据，避免前后不一致
    
    /// 字段名
    private(set) var nameUIData = BTFieldUIDataName()
    
    /// number & currency
    private(set) var numberUIData = BTFieldUIDataNumber()
    
    /// autoNumber
    private(set) var autoNumberUIData = BTFieldUIDataAutoNumber()
    
    // MARK: --
    
    // 判断是否是Stage下的PrimaryField
    var isPrimaryFieldInStage: Bool {
        return !isStageLinkField && isInStage &&
            fieldID == primaryFieldId &&
            (compositeType.uiType == .text ||
             compositeType.uiType == .number ||
             compositeType.uiType == .dateTime ||
             compositeType.uiType == .formula ||
             compositeType.uiType == .autoNumber)
    }
    
    private(set) var itemViewTabs: [BTRecordItemViewModel] = []
    
    private(set) var currentItemViewIndex: Int = 0

    private(set) var showGradient: Bool = false

    // 判断是否是PrimaryField
    var isPrimaryField: Bool {
        if UserScopeNoChangeFG.ZJ.btCardReform {
            return false
        }
        return isPrimaryFieldInStage
    }
    
    var isStageFieldInDetailView: Bool {
        if compositeType.uiType != .stage || extendedType == .stageDetail {
            return false
        }
        
        return true
    }
    
    // 是否应该显示在itemView tab上
    var shouldShowOnTabs: Bool {
        return compositeType.uiType == BTFieldUIType.stage &&
               !compositeType.isCalculationType &&
               uneditableReason != .drillDown &&
               uneditableReason != .notSupported &&
               uneditableReason != .bitableNotReady &&
               uneditableReason != .isExtendField &&
               uneditableReason != .proAdd
    }
    
    init(recordID: String) {
        self.recordID = recordID
    }
    
    mutating func update(isPro: Bool) {
        self.isPro = isPro
    }
    
    mutating func update(formBannerUrl: String?) {
        self.formBannerUrl = formBannerUrl
    }

    mutating func update(fieldWidth: CGFloat) {
        width = fieldWidth
    }

    mutating func update(itemViewHeight: CGFloat) {
        self.itemViewHeight = itemViewHeight
    }

    mutating func updating(hiddenCount: Int, isDisclosed: Bool) -> BTFieldModel {
        fieldID = BTFieldExtendedType.hiddenFieldsDisclosure.mockFieldID
        extendedType = .hiddenFieldsDisclosure
        hiddenFieldsCount = hiddenCount
        isHiddenFieldsDisclosed = isDisclosed
        return self
    }

    mutating func updating(formElementType: BTFieldExtendedType) -> BTFieldModel {
        updating(elementType: formElementType)
        mode = .form
        return self
    }
    
    mutating func updating(elementType: BTFieldExtendedType) {
        fieldID = elementType.mockFieldID
        extendedType = elementType
    }
    
    mutating func update(meta: BTFieldMeta, value: BTFieldValue, holdDataProvider: BTHoldDataProvider?) {
        fieldID = value.id
        var tempType = meta.compositeType
        var tempValue = value.value
        
        if let referencedFieldMeta = meta.property.referencedFieldMeta.first {
            if [.formula, .lookup].contains(where: { $0 == tempType.type }) {
                if let val = value.value as? [[String: Any]],
                   let v = val.first {
                    if let unwrappedPayload = BTFieldValue.deserialize(from: v["payload"] as? [String: Any]) {
                        tempType = referencedFieldMeta.compositeType
                        tempValue = unwrappedPayload.value
                    }
                    if let stateValue = v["state"] as? Int, let state = BTFormulaCalcState(rawValue: stateValue) {
                        calcState = state
                    } else {
                        calcState = .success
                    }
                } else if referencedFieldMeta.compositeType.uiType.allowEmptyInFormulaOrLookup {
                    // 这类字段支持引用/公式空值带样式渲染
                    tempType = referencedFieldMeta.compositeType
                }
            }
            property = referencedFieldMeta.property
            allowedEditModes = referencedFieldMeta.allowedEditModes
        } else {
            property = meta.property
            allowedEditModes = meta.allowedEditModes
        }
        
        extendedType = .inherent(tempType)
        isHidden = meta.hidden
        compositeType = meta.compositeType
        editable = value.editable
        triggerAble = value.triggerAble
        uneditableReason = value.uneditableReason
        name = meta.title.isEmpty ? meta.name : meta.title
        required = meta.required
        errorMsg = meta.errorMsg
        description = meta.description
        isSync = meta.isSync
        fieldWarning = meta.fieldWarning
        onlyCamera = !property.capture.isEmpty
        tableId = property.tableId
        filterInfo = property.filterInfo
        fieldPermission = value.fieldPermission
        resolveUIData(inherentType: tempType.type, meta: meta, value: tempValue, holdDataProvider: holdDataProvider)
    }

    mutating func update(mode: BTViewMode) {
        self.mode = mode
        if mode == .addRecord || (mode == .submit && UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable) {
            // 新建记录模式下不支持点击
            buttonConfig.status = .disable
        }
    }

    mutating func update(formTitle: String) {
        name = formTitle // 表单名字复用 name 字段，减少冗余
    }

    mutating func update(formDescription: BTDescriptionModel?) {
        description = formDescription // 表单副标题复用 description 字段，减少冗余
    }

    mutating func update(descriptionIsLimited: Bool) {
        isDescriptionTextLimited = descriptionIsLimited
    }

    mutating func update(descriptionIndicatorIsSelected: Bool) {
        isDescriptionIndicatorSelected = descriptionIndicatorIsSelected
    }

    mutating func update(optionColors: [BTColorModel]) {
        colors = optionColors
    }

    mutating func update(localStorageURLs: [String: URL]) {
        self.localStorageURLs = localStorageURLs
    }

    mutating func update(uploadingAttachments: [BTMediaUploadInfo]) {
        self.uploadingAttachments = uploadingAttachments
    }

    mutating func update(pendingAttachments: [PendingAttachment]) {
        self.pendingAttachments = pendingAttachments
    }
    
    mutating func update(isFetchingGeoLocation: Bool) {
        self.isFetchingGeoLocation = isFetchingGeoLocation
    }

    mutating func update(isEditing: Bool) {
        self.isEditing = isEditing
    }

    mutating func update(errorMsg: String) {
        self.errorMsg = errorMsg
    }

    mutating func update(canEditField: Bool) {
        editable = canEditField
    }

    mutating func update(fieldUneditableReason: BTFieldValue.UneditableReason) {
        uneditableReason = fieldUneditableReason
    }

    mutating func update(textSegments: [BTRichTextSegmentModel]) {
        textValue = textSegments
    }
    
    mutating func update(phoneValues: [BTPhoneModel]) {
        phoneValue = phoneValues
    }
    
    mutating func update(buttonStatus: BTButtonFieldStatus) {
        if mode == .addRecord || (mode == .submit && UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable) {
            // 新建记录模式下不支持点击
            buttonConfig.status = .disable
            return
        }
        buttonConfig.status = buttonStatus
    }
    
    mutating func update(numberValueDraft: String?) {
        numberUIData.draftValue = numberValueDraft
    }
    
    mutating func update(itemTabs: [BTRecordItemViewModel]) {
        self.itemViewTabs = itemTabs
    }
    
    mutating func update(currentItemViewIndex: Int) {
        self.currentItemViewIndex = currentItemViewIndex
        updateUIModel()
    }
    
    mutating func update(currentStageOptionId: String) {
        self.currentStageOptionId = currentStageOptionId
        updateUIModel()
    }

    private mutating func resolveUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) {
        switch inherentType {
        case .text:
            guard resolveTextUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .number:
            guard resolveNumberUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .singleSelect, .multiSelect:
            guard resolveSelectUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .dateTime:
            guard resolveDateTimeUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .lastModifyTime, .createTime:
            guard resolveTimeUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .checkbox:
            guard resolveCheckboxUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .user, .lastModifyUser, .createUser:
            guard resolveUserUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .url:
            guard resolveUrlUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .phone:
            guard resolvePhoneUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .attachment:
            guard resolveAttachmentUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .singleLink, .duplexLink:
            guard resolveLinkUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .lookup: // 当判断到这一层的时候，肯定已经不是原样引用了，而是用公式计算的结果
            guard resolveLookupUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .formula:
            guard resolveFormulaUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .autoNumber:
            guard resolveAutoNumberUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .location:
            guard resolveLocationUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .group:
            guard resolveGroupUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .virtual: //按钮字段不存储value值
            guard resolveVirtualUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .stage:
            guard resolveStageUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        case .notSupport: ()
            guard resolveNotSupportUIData(inherentType: inherentType, meta: meta, value: value, holdDataProvider: holdDataProvider) else {
                return
            }
        }
        
        updateUIModel()
        
    }
    
    // lookup 和 formula 的解析逻辑应该一致，和其它两端对齐
    // 这里临时抽个函数，FG 删除后可移入 switch 里面
    private mutating func updateTextValueForCalcType(value: Any?) {
        if let val = value as? [[String: Any]], let v = val.first {
            if let payloadText = JSON(v)["payload"].string, !payloadText.isEmpty {
                textValue = [BTRichTextSegmentModel(type: .text, text: payloadText)]
            } else if let arr = JSON(v)["payload"].array, !arr.isEmpty {
                textValue = arr.compactMap { BTRichTextSegmentModel.deserialize(from: $0.rawString()) }
            }
        }
    }
    
    private mutating func resolveTextUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value, !isEditing {
            textValue = JSON(val).arrayValue.compactMap {
                BTRichTextSegmentModel.deserialize(from: $0.rawString())
            }
        }
        return true
    }
    
    private mutating func resolveNumberUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [[String: Any]], !isEditing {
            numberValue = JSON(val).arrayValue.compactMap {
                BTNumberModel.deserialize(from: $0.rawString())
            }
        }
        return true
    }
    
    private mutating func resolveSelectUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if property.optionsType == .dynamicOption {
            if let val = value as? [[String: Any]] {
                dynamicOptions = JSON(val).arrayValue.compactMap {
                    BTOptionModel.deserialize(from: $0.rawString())
                }
            } else if let val = value as? [String],
                        let holdDataProvider = holdDataProvider {
                // Base 外添加记录模式，不加载关联表，前端没有关联表上下文，这里只返回 id 列表，option 其他数据从 holdDataProvider 中获得
                let dynamicOptionsFieldData = holdDataProvider.getDynamicOptionsFieldData(filedId: fieldID)
                dynamicOptions = JSON(val).arrayValue.compactMap {
                    dynamicOptionsFieldData[$0.rawString() ?? ""]
                }
            }
        } else {
            if let val = value as? [String] {
                optionIDs = val
            }
        }
        return true
    }
    
    private mutating func resolveDateTimeUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [[String: Any]] {
            dateValue = JSON(val).arrayValue.compactMap {
                BTDateModel.deserialize(from: $0.rawString())
            }
        }
        return true
    }
    
    private mutating func resolveTimeUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [TimeInterval] {
            dateValue = val.map {
                BTDateModel(value: $0 / 1000, reminder: nil)
            }
        }
        return true
    }
    
    private mutating func resolveCheckboxUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [Bool] {
            selectValue = val
        }
        return true
    }
    
    private mutating func resolveUserUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [[String: Any]], let v = val.first {
            users = JSON(v)["users"].arrayValue.compactMap {
                BTUserModel.deserialize(from: $0.rawString())
            }
        }
        return true
    }
    
    private mutating func resolveUrlUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [[String: Any]] {
            textValue = JSON(val).arrayValue.compactMap {
                guard let model = BTRichTextSegmentModel.deserialize(from: $0.rawString()) else { return nil }
                return model
            }
        }
        return true
    }
    
    private mutating func resolvePhoneUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [[String: Any]], !isEditing {
            phoneValue = JSON(val).arrayValue.compactMap {
                BTPhoneModel.deserialize(from: $0.rawString())
            }
        }
        return true
    }
    
    private mutating func resolveAttachmentUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value {
            attachmentValue = JSON(val).arrayValue.compactMap {
                BTAttachmentModel.deserialize(from: $0.rawString())
            }
        }
        return true
    }
    
    private mutating func resolveLinkUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value {
            let linkedRecordValues = JSON(val).arrayValue
                .compactMap { (v) -> BTRecordValue? in
                    BTRecordValue.deserialize(from: v.rawString())
                }
                .filter {
                    if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                        if isFormulaServiceSuspend == true {
                            // 新文档不再筛选无权限的关联cell
                            return true
                        } else {
                            return $0.visible
                        }
                    } else {
                        return $0.visible
                    }
                }
            var linkedTableMeta = BTTableMeta()
            linkedTableMeta.primaryFieldId = meta.property.primaryFieldId
            linkedTableMeta.fields = meta.property.fields
            linkedTableMeta.shouldDiscloseHiddenFields = true
            let linkFieldHoldData = holdDataProvider?.getLinkFieldData(filedId: fieldID)
            linkedRecords = linkedRecordValues.map { v in
                var linkedRecordModel = v
                if let linkFieldHoldData = linkFieldHoldData, linkedRecordModel.recordTitle.isEmpty, let recordTitle = linkFieldHoldData[linkedRecordModel.recordId], !recordTitle.isEmpty {
                    linkedRecordModel.recordTitle = recordTitle  // 本地 hold data 注入
                }
                var recordModel = BTRecordModel()
                recordModel.update(meta: linkedTableMeta, value: linkedRecordModel, mode: .card, holdDataProvider: holdDataProvider)
                return recordModel
            }

        }
        return true
    }
    
    private mutating func resolveLookupUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if UserScopeNoChangeFG.ZYS.formSupportFormula {
            updateTextValueForCalcType(value: value)
            return true
        }
        if let val = value as? [[String: Any]], let v = val.first {
            textValue = [BTRichTextSegmentModel(type: .text, text: JSON(v)["payload"].string ?? "0")]
        }
        return true
    }
    
    private mutating func resolveFormulaUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if UserScopeNoChangeFG.ZYS.formSupportFormula {
            updateTextValueForCalcType(value: value)
            return true
        }
        if let val = value as? [[String: Any]], let v = val.first {
            if let payloadText = JSON(v)["payload"].string {
                textValue = [BTRichTextSegmentModel(type: .text, text: payloadText)]
            } else {
                textValue = JSON(v)["payload"].arrayValue.compactMap {
                    BTRichTextSegmentModel.deserialize(from: $0.rawString())
                }
                if textValue.isEmpty {
                    textValue = [BTRichTextSegmentModel(type: .text, text: "0")]
                }
            }
        }
        return true
    }
    
    private mutating func resolveAutoNumberUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [[String: Any]] {
            autoNumberValue = JSON(val).arrayValue.compactMap {
                BTAutoNumberModel.deserialize(from: $0.rawString())
            }
        }
        return true
    }
    
    private mutating func resolveLocationUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [[String: Any]], let location = val.first?["locations"] {
            geoLocationValue = JSON(location).arrayValue.compactMap {
                BTGeoLocationModel.deserialize(from: $0["poiInfo"].rawString())
            }
        }
        return true
    }
    
    private mutating func resolveGroupUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        // model遵循Chatter协议
        if let val = value as? [[String: Any]], let v = val.first {
            groups = JSON(v)["groups"].arrayValue.compactMap {
                let model = BTGroupModel.deserialize(from: $0.rawString())
                return model
            }
        }
        return true
    }
    
    private mutating func resolveVirtualUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        guard meta.compositeType.uiType == .button, let button = meta.property.button else {
            return false
        }
        
        buttonConfig.title = button.title
        buttonConfig.color = button.color
        if !(meta.property.isTriggerEnabled ?? false) {
            // 按钮字段按钮是否置灰只跟按钮是否绑定了trigger有关
            buttonConfig.status = .disable
        }
        if mode == .addRecord || (mode == .submit && UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable) {
            // 新建记录模式下不支持点击
            buttonConfig.status = .disable
        }
        return true
    }
    
    private mutating func resolveStageUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        if let val = value as? [String] {
            optionIDs = val
        }
        return true
    }
    
    private mutating func resolveNotSupportUIData(inherentType: BTFieldType, meta: BTFieldMeta, value: Any?, holdDataProvider: BTHoldDataProvider?) -> Bool {
        // 目前什么也不做
        return true
    }
    
    private mutating func updateUIModel() {
        guard usingLayoutV2 else {
            return
        }
        nameUIData = BTFieldUIDataName(
            name: name,
            shouldShowDescIcon: shouldShowDescIcon,
            shouldShowWarnIcon: shouldShowWarnIcon,
            shouldShowRequire: shouldShowRequire
        )
        switch extendedType {
        case .inherent(let cmpType):
            let type = cmpType.uiType
            switch type {
            case .number, .currency:
                numberUIData = BTFieldUIDataNumber(numbers: numberValue, draftValue: nil)
            case .autoNumber:
                autoNumberUIData = BTFieldUIDataAutoNumber(autoNumberValue: autoNumberValue)
            case .notSupport, .text, .singleSelect, .multiSelect, .dateTime, .checkbox, .user, .phone, .url, .attachment, .singleLink, .lookup, .formula, .duplexLink, .location, .createTime, .lastModifyTime, .createUser, .lastModifyUser, .barcode, .progress, .group, .button, .rating, .stage, .email:
                break
            }
        case .formHeroImage, .customFormCover, .formTitle, .formSubmit, .hiddenFieldsDisclosure, .unreadable, .recordCountOverLimit, .stageDetail, .itemViewTabs, .itemViewHeader, .attachmentCover, .itemViewCatalogue:
            break
        }
    }
    
    mutating func update(timeZone: String) {
        self.timeZone = timeZone
    }
    
    mutating func update(buttonColors: [BTButtonColorModel]) {
        self.buttonColors = buttonColors
    }
    mutating func update(isFormulaServiceSuspend: Bool?) {
        self.isFormulaServiceSuspend = isFormulaServiceSuspend
    }
    
    mutating func update(primaryFieldId: String) {
        self.primaryFieldId = primaryFieldId
    }
    
    mutating func updateMockStageField(type: BTFieldExtendedType) {
        guard type == .stageDetail else {
            assert(true, "only stage mock field cant call this function")
            return
        }
        self.extendedType = type
    }
    
    mutating func update(optionIDs: [String]) {
        self.optionIDs = optionIDs
    }
    
    mutating func update(inStage: Bool) {
        self.isInStage = inStage
    }
    
    mutating func update(property: BTFieldProperty) {
        self.property = property
    }
    
    mutating func update(isStageLinkField: Bool) {
        self.isStageLinkField = isStageLinkField
    }
    
    mutating func update(isStageCanceled: Bool) {
        self.isStageCancel = isStageCanceled
    }
    
    mutating func update(fieldPermission: BTFieldValue.FieldPermission?) {
        self.fieldPermission = fieldPermission
    }
    
    mutating func update(stageConvert: [String: Bool]) {
        if self.fieldPermission == nil {
            self.fieldPermission = BTFieldValue.FieldPermission()
        }
        self.fieldPermission?.stageConvert = stageConvert
    }
    
    mutating func update(isRequired: Bool) {
        self.required = isRequired
    }

    mutating func update(attachmentValue: [BTAttachmentModel]) {
        self.attachmentValue = attachmentValue
    }

    mutating func update(showGradient: Bool) {
        self.showGradient = showGradient
    }
}

extension BTFieldModel: IdentifiableType {

    typealias Identity = String

    /// fieldID | special strings // 阶段字段下可能出现fieldID相同的情况，这里加上另外的标记
    ///  阶段字段需要区分在itemView页面和详情页面
    var identity: String {
        if isInForm {
            return fieldID
        }
        
        if isStageLinkField || isStageFieldInDetailView {
            return fieldID + "_\(isStageLinkField)" + "_\(currentStageOptionId)"
        }
        
        return fieldID
    }
}

extension BTFieldModel {
    /// 字段名是否应该 字段描述 icon
    var shouldShowDescIcon: Bool {
        !isInForm && description?.content?.isEmpty == false
    }
    
    /// 字段名是否应该 字段异常 icon
    var shouldShowWarnIcon: Bool {
        !isInForm && !fieldWarning.isEmpty
    }
    
    /// 字段名是否应该 字段必填标识
    var shouldShowRequire: Bool {
        self.required && (isInForm || (isInStage && self.isStageLinkField))
    }
    
    /// 是否显示字段错误提示信息
    var shouldShowErrorMsg: Bool {
        !errorMsg.isEmpty
    }
    
    var usingLayoutV2: Bool {
        guard UserScopeNoChangeFG.ZYS.recordCardV2 && !isInForm else {
            return false
        }
        switch extendedType {
        case .inherent(let cmpType):
            return cmpType.uiType.reusableCellTypeV1 != cmpType.uiType.reusableCellTypeV2
        default:
            return false
        }
    }
    
    var placeHolderAttrText: NSAttributedString? {
        guard editable && !isInForm else {
            return nil
        }
        
        switch extendedType {
        case .inherent(let cmpType):
            if cmpType.type.isTextInputType {
                if cmpType.uiType == .barcode, allowedEditModes.scan == true, allowedEditModes.manual == false {
                    // 扫码字段仅支持扫码输入
                    return nil
                }
                let placeHolderAttrString = NSAttributedString(string: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer, attributes: [.font: BTFV2Const.Font.fieldValue])
                return placeHolderAttrString
            }
            
            return nil
        default:
            return nil
        }
    }
    
    var cellReuseID: String {
        switch extendedType {
        case .inherent(let cmpType):
            if usingLayoutV2 {
                return cmpType.uiType.reusableCellTypeV2.reuseIdentifier
            } else {
                return cmpType.uiType.reusableCellTypeV1.reuseIdentifier
            }
        case .formHeroImage:
            return BTFormHeroImageCell.reuseIdentifier
        case .customFormCover:
            return BTCustomFormCoverCell.reuseIdentifier
        case .formTitle:
            return BTFormTitleCell.reuseIdentifier
        case .formSubmit:
            return BTFormSubmitCell.reuseIdentifier
        case .hiddenFieldsDisclosure:
            return BTHiddenFieldsDisclosureCell.reuseIdentifier
        case .unreadable:
            return BTFormUnreadableCell.reuseIdentifier
        case .recordCountOverLimit:
            return BTFormRecordOverLimitCell.reuseIdentifier
        case .stageDetail:
            return BTStageDetailInfoCell.reuseIdentifier
        case .itemViewTabs:
            return BTItemViewListHeaderCell.reuseIdentifier
        case .itemViewHeader:
            return BTItemViewTiTleCell.reuseIdentifier
        case .attachmentCover:
            return BTAttachmentCoverCell.reuseIdentifier
        case .itemViewCatalogue:
            return BTItemViewCatalogueCell.reuseIdentifier
        }
    }
}
