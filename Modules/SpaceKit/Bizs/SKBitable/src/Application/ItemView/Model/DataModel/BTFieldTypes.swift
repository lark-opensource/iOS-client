//
//  BTFieldTyps.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/9/22.
//  


import SKFoundation
import UIKit
import HandyJSON
import SKCommon
import UniverseDesignIcon
import UniverseDesignColor
import SKBrowser
import SKInfra

/*
 简要介绍，目前 bitable 涉及的字段相关的有一下 5个类型，
 1.BTFieldType: 基础的字段类型，对于拥有相同数据结构的字段一般共用一个 BTFieldType（多端共用）
 2.BTFieldUIType: 最终显示的字段类型，主要为了 BTFieldType 逻辑复用而生（属于前端通信数据类型，多端共用）
 3.BTFieldCompositeType: 在代码中流转的类型，包含了 BTFieldType + BTFieldUIType 两种类型信息。主要为了避免后续在获取信息和处理判断时会遗漏 BTFieldUIType。
 4.BTFieldExtendedType: 除了业务字段外，还有一些移动端自己构建的字段。例如表单提交字段和删除按钮字段等。
 
 有些规则说明：
 1. 关于 BTFieldCompositeType 的使用
    后续解析所有带有 fieldType 和 fieldUIType 的模型时，统一对外只开放 BTFieldCompositeType，方便统一管理：
    private var fieldType: Int = 0
    private var fieldUIType: String?
    var compositeType: BTFieldCompositeType {
        return BTFieldCompositeType(fieldTypeValue: fieldType, uiTypeValue: fieldUIType)
    }
 
    需要更新时提供一个方法，防止问题遗漏
    mutating func update(fieldType: Int, uiType: String?) {
        self.fieldType = fieldType
        self.fieldUIType = uiType
    }
 
 2. 任何 switch 不要写 default，防止新增遗漏。
 */


// MARK: - BTFieldType 基础的字段类型。
/// 字段类型（对应前端的 `EFieldType`）
enum BTFieldType: Int, Equatable, HandyJSONEnum, Codable, SKFastDecodableEnum {
    case notSupport = 0
    case text = 1
    case number = 2
    case singleSelect = 3
    case multiSelect = 4
    case dateTime = 5
    //    case singleLine = 6
    case checkbox = 7
    //    case percent = 8
    //    case duration = 9
    //    case rating = 10
    case user = 11
    //    case tag = 12
    case phone = 13
    //    case email = 14
    case url = 15
    //    case picture = 16
    case attachment = 17
    case singleLink = 18
    case lookup = 19
    case formula = 20
    case duplexLink = 21
    case location = 22
    case group = 23
    case stage = 24
    
    case createTime = 1001
    case lastModifyTime = 1002
    case createUser = 1003
    case lastModifyUser = 1004
    case autoNumber = 1005
    
    case virtual = 3001
    
    /// 字段作为过滤类型时是否为文本输入型，
    var isInputTypeForFilter: Bool {
        switch self {
        case .text, .url, .number, .location, .phone, .autoNumber, .virtual:
            return true
        case .notSupport, .checkbox, .attachment,
                .user, .createUser, .lastModifyUser,
                .dateTime, .createTime, .lastModifyTime,
                .singleLink, .duplexLink,
                .singleSelect, .multiSelect,
                .lookup, .formula, .group, .stage:
            return false
        }
    }
    
    // 文本输入类型字段
    var isTextInputType: Bool {
        switch self {
        case .text, .url, .number, .phone:
            return true
        default:
            return false
        }
    }
}

// MARK: - BTFieldUIType 字段的辅助类型，为了复用基础字段而诞生。
// 相关上下文： https://bytedance.feishu.cn/wiki/wikcn50QlrUQaxtyjIyb6o4gtob?from=from_lark_index_search
enum BTFieldUIType: String, Equatable, Codable, CaseIterable, HandyJSONEnum, SKFastDecodableEnum {
    case notSupport = "NotSupport"
    case text = "Text"
    case number = "Number"
    case singleSelect = "SingleSelect"
    case multiSelect = "MultiSelect"
    case dateTime = "DateTime"
    case checkbox = "Checkbox"
    case user = "User"
    case phone = "Phone"
    case url = "Url"
    case attachment = "Attachment"
    case singleLink = "SingleLink"
    case lookup = "Lookup"
    case formula = "Formula"
    case duplexLink = "DuplexLink"
    case location = "Location"
    case createTime = "CreatedTime"
    case lastModifyTime = "ModifiedTime"
    case createUser = "CreatedUser"
    case lastModifyUser = "ModifiedUser"
    case autoNumber = "AutoNumber"
    case barcode = "Barcode"
    case currency = "Currency"
    case progress = "Progress"
    case group = "GroupChat"
    case button = "Button"
    case rating = "Rating"
    case stage = "Stage"
    case email = "Email"
    
    /// 根据当前的字段类型进行分类
    enum ValueClassifyType {
        case date //时间
        case user //人员
        case link //关联
        case option //选项
        case group // 群组
        case unclassified //未分类
    }
    
    fileprivate static func downgradeUIType(_ fieldType: BTFieldType) -> BTFieldUIType {
        return .notSupport
    }
}

protocol BTFieldProtocol {
    var fieldType: BTFieldType { get }
    
    var fieldUIType: BTFieldUIType { get }
}

extension BTFieldProtocol {
    var compositeType: BTFieldCompositeType {
        BTFieldCompositeType(fieldType: fieldType, uiType: fieldUIType)
    }
}

// MARK: - BTFieldCompositeType 由 BTFieldType 和 BTFieldUIType 组成真正的业务字段
final class BTFieldCompositeType {
    
    let type: BTFieldType
    
    let uiType: BTFieldUIType
    
    /// 获取字段的埋点名称
    var fieldTrackName: String {
        return uiType.fieldTrackName
    }
    
    var classifyType: BTFieldUIType.ValueClassifyType {
        return uiType.classifyType
    }
    
    /// 获取字段的图标类型
    var iconKey: UDIconType {
        return uiType.iconImage
    }
    /// 是否是计算类型
    var isCalculationType: Bool {
        uiType == .formula || uiType == .lookup
    }
    /// 是否支持扩展（目前只有人员和创建人支持扩展，客户端根据这个值展示扩展字段 new 标签）
    var isSupportFieldExt: Bool {
        uiType == .user || uiType == .createUser
    }
    
    /// 是否在点击时提示特定的提示“”
    var isImmutableType: Bool {
        return type == .createTime
        || type == .lastModifyTime
        || type == .createUser
        || type == .lastModifyUser
    }
    
    /// 获取字段的图标
    func icon(color: UIColor = UDColor.iconN1, size: CGSize? = nil) -> UIImage {
        let image = UDIcon.getIconByKey(iconKey, iconColor: color)
        if let size = size {
            return image.ud.resized(to: size)
        }
        return image
    }
    
    /// 获取对应字段的编辑属性映射的 map
    func getAllowEditModesMap(by allowedEditModes: AllowedEditModes) -> [String: Bool]? {
        return uiType.getAllowEditModesMap(by: allowedEditModes)
    }
    
    // 为了获取唯一标识符
    var typesId: String {
        return "\(type.rawValue)" + "#" + (uiType.rawValue)
    }
    
    static func getTypesFormId(_ id: String) -> (Int, String?)? {
        let values = id.components(separatedBy: "#")
        guard values.count > 0, let fieldTypeValue = Int(values[0]) else {
            spaceAssertionFailure("getTypesFormId id: \(id) parse error")
            return nil
        }
        let fieldUITypeValue = values.count > 1 ? values[1] : nil
        return (fieldTypeValue, fieldUITypeValue)
    }
    
    static var `default`: BTFieldCompositeType {
        return BTFieldCompositeType(fieldType: .notSupport, uiType: .notSupport)
    }
    
    init(fieldType: BTFieldType, uiType: BTFieldUIType) {
        self.type = fieldType
        self.uiType = uiType
    }
    
    convenience init(fieldType: BTFieldType, uiTypeValue: String?) {
        let uiType: BTFieldUIType
        if fieldType == .notSupport {
            // 前端传过来的数据会有问题（一些情况下会出现 fieldType = 403，uiType 为有效值），因此增加校验，当 fieldType == .notSupport 不论 uiType 传啥都是 .notSupport
            uiType = .notSupport
        } else {
            uiType = BTFieldUIType(rawValue: uiTypeValue ?? "") ?? BTFieldUIType.downgradeUIType(fieldType)
        }
        self.init(fieldType: fieldType, uiType: uiType)
    }
    
    convenience init(fieldTypeValue: Int, uiTypeValue: String?) {
        let fieldType = BTFieldType(rawValue: fieldTypeValue) ?? .notSupport
        self.init(fieldType: fieldType, uiTypeValue: uiTypeValue)
    }
}

extension BTFieldCompositeType: Hashable {
    
    static func == (lhs: BTFieldCompositeType, rhs: BTFieldCompositeType) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(uiType)
    }
}

extension BTFieldUIType {

    var iconImage: UDIconType {
        switch self {
        case .notSupport: return .maybeOutlined
        case .text: return .styleOutlined
        case .number: return .numberOutlined
        case .singleSelect: return .downRoundOutlined
        case .multiSelect: return .multipleOutlined
        case .dateTime, .lastModifyTime, .createTime: return .calendarLineOutlined
        case .checkbox: return .todoOutlined
        case .user, .createUser, .lastModifyUser: return .memberOutlined
        case .phone: return .callOutlined
        case .url: return .linkCopyOutlined
        case .attachment: return .attachmentOutlined
        case .singleLink: return .sheetOnedatareferenceOutlined
        case .lookup: return .lookupOutlined
        case .formula: return .formulaOutlined
        case .duplexLink: return .sheetDatareferenceOutlined
        case .autoNumber: return .numberedListNewOutlined
        case .location: return .localOutlined
        case .barcode: return .barcodeOutlined
        case .currency:
            return DocsSDK.currentLanguage == .zh_CN ? .currencyYuanOutlined : .currencyDollarOutlined
        case .progress: return .bitableProgressOutlined
        case .group: return .groupOutlined
        case .button: return .buttonOutlined
        case .rating: return .collectionOutlined
        case .stage: return .dependencyOutlined
        case .email: return .mailOutlined 
        }
    }
    
    var fieldTrackName: String {
        switch self {
        case .notSupport: return "not_support"
        case .text: return "multiline"
        case .number: return "number"
        case .singleSelect: return "single_option"
        case .multiSelect: return "multi_options"
        case .dateTime: return "date"
        case .lastModifyTime: return "update_time"
        case .createTime: return "create_time"
        case .checkbox: return "checkbox"
        case .user: return "person"
        case .createUser: return "created_by"
        case .lastModifyUser: return "modified_by"
        case .phone: return "tel"
        case .url: return "link"
        case .attachment: return "attachment"
        case .singleLink: return "relation"
        case .lookup: return "lookup"
        case .formula: return "formula"
        case .duplexLink: return "duplex_relation"
        case .autoNumber: return "auto_number"
        case .location: return "geography"
        case .barcode: return "scan"
        case .currency: return "currency"
        case .progress: return "progress"
        case .group: return "group"
        case .button: return "button"
        case .rating: return "rating"
        case .stage: return "stage"
        case .email: return "email"
        }
    }
    
    var reusableCellTypeV1: UICollectionViewCell.Type {
        switch self {
        case .notSupport: return BTUnsupportedField.self
        case .text, .barcode, .email: return BTTextField.self
        case .number, .currency: return BTNumberField.self
        case .progress: return BTProgressField.self
        case .singleSelect, .multiSelect: return BTOptionField.self
        case .dateTime, .createTime, .lastModifyTime: return BTDateField.self
        case .checkbox: return BTCheckboxField.self
        case .user, .createUser, .lastModifyUser, .group: return BTChatterField.self
        case .phone: return BTPhoneField.self
        case .url: return BTURLField.self
        case .attachment: return BTAttachmentField.self
        case .singleLink, .duplexLink: return BTLinkField.self
        case .lookup, .formula: return BTFormulaField.self
        case .autoNumber: return BTAutoNumberField.self
        case .location: return BTGeoLocationField.self
        case .button: return BTButtonField.self
        case .rating: return BTRatingField.self
        case .stage: return BTStageField.self
        }
    }
    
    var reusableCellTypeV2: UICollectionViewCell.Type {
        guard UserScopeNoChangeFG.ZYS.recordCardV2 else {
            return reusableCellTypeV1
        }
        switch self {
        case .notSupport: return BTFieldV2Unsupported.self
        case .text, .barcode, .email: return BTFieldV2Text.self
        case .number, .currency: return BTFieldV2Number.self
        case .progress: return BTFieldV2Progress.self
        case .singleSelect, .multiSelect: return BTFieldV2Option.self
        case .dateTime, .createTime, .lastModifyTime: return BTFieldV2Date.self
        case .checkbox: return BTFieldV2Checkbox.self
        case .user, .createUser, .lastModifyUser, .group: return BTFieldV2Chatter.self
        case .phone: return BTFieldV2Phone.self
        case .url: return BTFieldV2URL.self
        case .attachment: return BTFieldV2Attachment.self
        case .singleLink, .duplexLink: return BTFieldV2Link.self
        case .lookup, .formula: return BTFieldV2FormulaAndLookup.self
        case .autoNumber: return BTFieldV2AutoNumber.self
        case .location: return BTFieldV2Location.self
        case .button: return BTFieldV2Button.self
        case .rating: return BTFieldV2Rating.self
        case .stage: return BTFieldV2Stage.self
        }
    }
    
    var reusableCellForNativeRender: UICollectionViewCell.Type {
        switch self {
        case .text: return BTCardRichTextFieldCell.self
        case .barcode, .email, .number, .currency, .phone, .url, .location, .autoNumber: return BTCardSimpleTextFieldCell.self
        case .progress: return BTCardProgressFieldCell.self
        case .singleSelect, .multiSelect: return BTCardOptionFieldCell.self
        case .dateTime, .createTime, .lastModifyTime: return BTCardDateFieldCell.self
        case .checkbox: return BTCardCheckBoxFieldCell.self
        case .user, .createUser, .lastModifyUser, .group: return BTCardChatterFieldCell.self
        case .attachment: return BTCardAttachmentFieldCell.self
        case .singleLink, .duplexLink: return BTCardLinkFieldCell.self
//        case .lookup, .formula: return .self
        case .button: return BTCardButtonFieldCell.self
        case .rating: return BTCardRatingFieldCell.self
        case .stage: return BTCardStageFieldCell.self
        default:
            return BTCardNotSupportField.self
        }
    }
    
    //在编辑过程是否要把协同消息拦截掉 (编辑时该字段内容不协同)
    var interceptUpdateWhileEditing: Bool {
        switch self {
        case .text, .barcode, .url, .number, .phone, .currency, .progress,. email:
            return true
        case .notSupport, .checkbox, .attachment, .location,
                .autoNumber, .rating,
                .dateTime, .createTime, .lastModifyTime,
                .user, .createUser, .lastModifyUser,
                .singleLink, .duplexLink,
                .singleSelect, .multiSelect,
                .lookup, .formula,
                .button,
                .group,
                .stage:
            return false
        }
    }
    
    // 字段的分类，在没有 FieldUItype 之前，承担了现阶段的 FieldType 类似的责任，即对于同一种数据类型的分类
    var classifyType: ValueClassifyType {
        switch self {
        case .dateTime, .createTime, .lastModifyTime:
            return .date
        case .user, .createUser, .lastModifyUser:
            return .user
        case .singleLink, .duplexLink:
            return .link
        case .singleSelect, .multiSelect:
            return .option
        case .group:
            return .group
        case .notSupport, .checkbox, .attachment,
                .text, .url, .location, .barcode,
                .number, .autoNumber, .phone, .currency, .progress, .rating,
                .lookup, .formula,
                .button, .stage, .email:
            return .unclassified
        }
    }
    
    // 编辑模式，理想目标是通过配置化的方式实现字段能力，而编辑能力在充分抽象解耦后可以在此处以配置的方式进入字段能力
    func getAllowEditModesMap(by allowedEditModes: AllowedEditModes) -> [String: Bool]? {
        switch self {
        case .text, .barcode, .email:
            return [
                "scan": allowedEditModes.scan ?? false,
                "manual": allowedEditModes.manual ?? false
            ]
        case .notSupport, .checkbox, .attachment, //其他
                .location, .url, //文本
                .number, .phone, .autoNumber, .currency, .progress, .rating, //号码
                .dateTime, .createTime, .lastModifyTime, //事件
                .user, .createUser, .lastModifyUser, //人员
                .group, // 群组
                .singleLink, .duplexLink, //关联
                .singleSelect, .multiSelect, //选项
                .lookup, .formula, //公式&引用
                .button, .stage:
            return nil
        }
    }
    
    /// 是否允许在 formula / lookup 字段中渲染空值样式
    /// 空值样式：单元格值虽然是 null，但是要渲染一个空样式出来
    var allowEmptyInFormulaOrLookup: Bool {
        switch self {
        case .notSupport, .text, .number, .singleSelect, .multiSelect, .dateTime,
                .checkbox, .user, .phone, .url, .attachment, .singleLink, .duplexLink,
                .lookup, .formula, .location, .createTime, .lastModifyTime,
                .createUser, .lastModifyUser, .autoNumber, .barcode, .currency, .button, .group,
                .stage, .email:
            return false
        case .progress, .rating:
            return true
        }
    }
}

// MARK: - BTFieldExtendedType 除了业务字段类型外还有其他移动端原生构造字段
enum BTFieldExtendedType: Equatable {
    /// 实际字段类型
    case inherent(BTFieldCompositeType)
    /// 表单头图
    case formHeroImage
    /// 自定义表单封面
    case customFormCover
    /// 表单标题
    case formTitle
    /// 表单提交按钮
    case formSubmit
    /// 隐藏字段开关
    case hiddenFieldsDisclosure
    
    case unreadable
    /// 表单数量超限制
    case recordCountOverLimit
    /// 阶段字段详情
    case stageDetail
    /// itemView Tabs
    case itemViewTabs
    /// itemView标题
    case itemViewHeader
    /// 附件封面
    case attachmentCover
    /// 目录条
    case itemViewCatalogue
    
    var mockFieldID: String {
        // 这里不应该把 fieldID 和 reuseIdentifier 耦合起来，但是先保留线上的写法
        switch self {
        case let .inherent(compositeType):
            // inherent 正常会用 field 真正的 fieldID 作为 ID，这个返回什么没有用
            return compositeType.uiType.reusableCellTypeV1.reuseIdentifier
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
    
    var isForm: Bool {
        switch self {
        case .formHeroImage, .customFormCover, .formTitle, .formSubmit, .recordCountOverLimit: return true
        default: return false
        }
    }
    
    //在编辑过程是否要把协同消息拦截掉 (编辑时该字段内容不协同)
    var interceptUpdateWhileEditing: Bool {
        guard case .inherent(let compositeType) = self else { return false }
        return compositeType.uiType.interceptUpdateWhileEditing
    }
    
    var classifyType: BTFieldUIType.ValueClassifyType {
        guard case .inherent(let compositeType) = self else { return .unclassified }
        return compositeType.classifyType
    }
    // user 和 group同构为chatter，后续新增可以归类为chatter的字段，在BTChatterType里定义真实类型后，
    //在这里新增case，返回对应类型，其他字段return nil
    var chatterType: BTChatterType? {
        // 这里得通过extendedType获取真实的type
        guard case .inherent(let compositeType) = self else { return nil }
        switch compositeType.uiType {
        case .user, .lastModifyUser, .createUser:
            return .user
        case .group:
            return .group
        case .lastModifyTime, .attachment, .autoNumber,
                .checkbox, .createTime, .dateTime,
                .duplexLink, .location, .formula,
                .multiSelect ,.url , .singleLink,
                .phone, .notSupport, .text,
                .number, .singleSelect, .lookup,
                .barcode, .currency, .progress,
                .button, .rating, .stage, .email:
            return nil
        }
    }
}
