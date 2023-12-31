//
// Created by duanxiaochen.7 on 2022/3/21.
// Affiliated with SKBitable.
//
// Description:


import UIKit
import SKBrowser
import SKCommon
import RxDataSources
import SKFoundation
import SKResource
import SpaceInterface

enum BTSpecialRecordID: String {
    case initLoading //初始化loading卡片
    case leftLoading //分页请求左边loading卡片
    case rightLoading //分页请求右边loading卡片
}

enum BTBTRecordItemViewType {
    case detail
    case stage
}

struct BTRecordItemViewModel: Equatable {
    var type: BTBTRecordItemViewType
    var id: String
    var name: String
}

/// table meta + record value + other ui models
struct BTRecordModel: Equatable {
    ///非唯一标识ID，获取唯一标识符请用identify
    private(set) var recordID: String = ""
    
    ///唯一标识ID，recordID + groupValue，看板视图下列表中可能会出现多张recordId一样的卡片
    private(set) var identify: String = ""

    ///分组ID，看板视图有用，透传给前端
    private(set) var groupValue: String = ""

    private(set) var size: CGSize = CGSizeMake(0, 0)

    var width: CGFloat {
        return size.width
    }

    /// 当前视图类型
    private(set) var editingFieldID: String?
    /// 卡片顶部颜色条
    private(set) var headerBarColor: String = ""
    /// 选项字段用到的颜色
    private(set) var colors: [BTColorModel] = []
    /// 宿主类型
    private(set) var bizType: String = ""
    /// 视图类型
    private(set) var viewType: String = "grid"
    /// 卡片形态
    private(set) var viewMode: BTViewMode = .card
    /// 关联表格的主键 ID
    private(set) var primaryFieldID: String = ""
    /// Base 名字
    private(set) var baseName: String = ""
    /// Base 名字，适配了未命名的场景
    var baseNameAdaptedForUntitled: String {
        if baseName.isEmpty {
            return DocsType.bitable.untitledString
        } else {
            return baseName
        }
    }
    /// 表格名字
    private(set) var tableName: String = ""
    /// 是否允许添加记录
    private(set) var recordAddable: Bool = false
    /// 表单视图的标题
    private(set) var currentViewName: String = ""
    /// 表单副标题
    private(set) var currentViewDescription: BTDescriptionModel?
    /// 表格是否有查看权限
    private(set) var tableVisible: Bool = true
    /// 卡片是否被筛选掉了
    private(set) var isFiltered: Bool = false
    private(set) var filterTipClosed: Bool = false
    /// 卡片是否可见
    private(set) var visible: Bool = false
    /// 卡片是否可编辑
    private(set) var editable: Bool = false
    //当前卡片的全局index，用来判断是否还有分页数据
    private(set) var globalIndex: Int = 0
    /// 处理过后的字段数据，用于 UI 展示
    private(set) var wrappedFields: [BTFieldModel] = [] {
        didSet {
            guard !UserScopeNoChangeFG.ZJ.btItemViewOriginFieldsFixDisable else { return }
            updateOriginalFields()
        }
    } // 命名参照苹果 PropertyWrapper 里的 wrappedValue
    /// 从前端获取到的原始的 Fields, 不包含客户端添加的自定义 fields
    private(set) var originalFields: [BTFieldModel] = [] // 命名参照苹果 PropertyWrapper 里的 wrappedValue
    /// 是否展示删除按钮
    private(set) var deletable: Bool = false
    /// 是否展示分享按钮
    private(set) var shareable: Bool = false
    /// 表单场景下描述内容是否展开
    private(set) var descriptionLimitStates: [String: Bool] = [:]
    /// 卡片场景下描述ⓘ按钮是否被点亮
    private(set) var descriptionIndicatorSelectionStates: [String: Bool] = [:]
    /// 正在上传的附件，key 是 fieldID
    private(set) var fieldsUploadingAttachments: [String: [BTMediaUploadInfo]] = [:]
    /// 等候上传的附件，key 是 fieldID
    private(set) var fieldsPendingAttachments: [String: [PendingAttachment]] = [:]
    /// 刚上传好的附件的本地地址，用于显示缩略图，key 是 drive token
    private(set) var localStorageURLs: [String: URL] = [:]
    /// 关联编辑面板里的选中态
    private(set) var isSelected: Bool = false
    /// 正在获取当前定位的field
    private(set) var fieldsFetchGeoLocation: Set<String> = []
    /// 记录标题，不带样式
    private(set) var recordTitle: String = ""
    /// 卡片数据状态
    private(set) var dataStatus: BTRecordValueStatus = .success
    private(set) var shouldShowSubmitTopTip: Bool = false
    /// 卡片内按钮字段状态，key为字段ID
    private(set) var buttonFieldStatus: [String: BTButtonFieldStatus] = [:]
    /// 按钮字段颜色配置列表
    private(set) var buttonColors: [BTButtonColorModel] = []
    /// true代表是scheme4新文档
    private(set) var isFormulaServiceSuspend: Bool?
    /// 封面URL
    private(set) var formBannerUrl: String?
    /// 表单模式下CTA提示
    private(set) var topTipType: BTTopTipType = .none
    /// 文档是否开启了高级权限
    private(set) var isPro: Bool = false
    /// itemViewTab index
    private(set) var currentItemViewIndex: Int = 0
    private var _currentItemViewIndex: Int {
        guard currentItemViewIndex < itemViewTabs.count, currentItemViewIndex >= 0 else {
            return 0
        }
        
        return currentItemViewIndex
    }
    /// 阶段字段必填信息
    private(set) var stageRequiredFields: [String: [String: [String]]] = [:]
    /// 当前设置的封面 fieldId
    private(set) var cardCoverId: String = ""
    /// 更换封面的权限
    private(set) var coverChangeAble: Bool = false

    /// 数据变化时只会刷新当前可见的 cell，其他已经加载但不可见的 cell 延迟到 willDisplay 的时候进行刷新
    private(set) var forceUpdateWhenWillDisplay = false
    
    /// 记录分享，记录是否已被归档
    private(set) var isArchvied: Bool = false
    
    private var isFormMode: Bool {
        !viewMode.isIndRecord && viewType == "form"
    }
    
    /// 是否需要显示itemView tab
    var shouldShowItemViewTabs: Bool {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return false
        }
        
        if viewMode == .addRecord {
            return false
        }
        
        if viewMode == .submit, UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            return false
        }
        
        var fields = wrappedFields
        if !UserScopeNoChangeFG.ZJ.btItemViewStageTabsFixDisable {
            fields = originalFields
        }
        
        if !UserScopeNoChangeFG.ZJ.btItemViewProAddStageFieldFixDisable {
            return (fields.contains(where: { model in
                model.shouldShowOnTabs
            }) && viewMode != .submit && viewMode != .form) || viewMode.isStage
        } else {
            return fields.contains(where: { model in
                model.compositeType.uiType == BTFieldUIType.stage
            }) || viewMode.isStage
        }
    }
    
    var shouldShowItemViewCatalogue: Bool {
        guard !UserScopeNoChangeFG.YY.bitableRecordShareCatalogueDisable else {
            return viewMode == .addRecord
        }
        return viewMode.shouldShowItemViewCatalogue
    }
    
    var primaryFieldModel: BTFieldModel? {
        return wrappedFields.first { model in
            model.fieldID == primaryFieldID
        }
    }
    
    // 获取阶段字段名称
    var itemViewTabs: [BTRecordItemViewModel] {
        var tabs = [BTRecordItemViewModel(type: .detail,
                                          id: "detial",
                                          name: BundleI18n.SKResource.Bitable_ItemView_Mobile_Details_Tab)]
        
        var fields = wrappedFields
        if !UserScopeNoChangeFG.ZJ.btItemViewStageTabsFixDisable {
            fields = originalFields
        }
        
        fields.forEach { model in
            var shoulShow = model.compositeType.uiType == BTFieldUIType.stage
            
            if !UserScopeNoChangeFG.ZJ.btItemViewProAddStageFieldFixDisable {
                shoulShow = viewMode != .submit && viewMode != .form && viewMode != .addRecord && model.shouldShowOnTabs
            }
            
            if (shoulShow) {
                tabs.append(BTRecordItemViewModel(type: .stage, id: model.fieldID, name: model.name))
            }
        }

        return tabs
    }
    
    var isInStageTab: Bool {
        guard _currentItemViewIndex < itemViewTabs.count else {
            return false
        }
        
        return itemViewTabs[_currentItemViewIndex].type == .stage
    }
    
    var currentItemViewId: String {
        guard _currentItemViewIndex < itemViewTabs.count else { return "" }
        return itemViewTabs[_currentItemViewIndex].id
    }
    
    /// 是否可以在右上角显示“继续添加记录”菜单
    private(set) var canAddRecord: Bool = false

    mutating func update(meta: BTTableMeta, value: BTRecordValue, mode: BTViewMode, holdDataProvider: BTHoldDataProvider?) {
        recordID = value.recordId
        viewType = meta.viewType
        headerBarColor = value.headerBarColor
        colors = meta.colors
        buttonColors = meta.buttonColors
        bizType = meta.bizType
        viewType = meta.viewType
        viewMode = mode
        primaryFieldID = meta.primaryFieldId
        tableName = meta.tableName
        recordAddable = meta.recordAddable
        currentViewName = meta.currentViewName
        currentViewDescription = meta.currentViewDescription
        tableVisible = meta.tableVisible
        isPro = meta.isPro
        isFiltered = value.isFiltered
        isArchvied = value.isArchived
        visible = value.visible
        editable = value.editable
        groupValue = value.groupValue
        globalIndex = value.globalIndex
        dataStatus = value.dataStatus
        identify = value.identify
        recordTitle = value.recordTitle
        let normalFieldModels = value.fields.compactMap { value -> BTFieldModel? in
            if let fieldMeta = meta.fields[value.id] {
                var fieldModel = BTFieldModel(recordID: recordID)
                if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                    // 顺序需要在下一行设置meta value之前，否则会导致底层拿到的时候是nil
                    fieldModel.update(isFormulaServiceSuspend: meta.isFormulaServiceSuspend)
                }
                fieldModel.update(meta: fieldMeta, value: value, holdDataProvider: holdDataProvider)
                fieldModel.update(isPro: meta.isPro)
                fieldModel.update(mode: mode)
                if viewMode.isStage {
                    fieldModel.update(inStage: true)
                }
                fieldModel.update(optionColors: colors)
                fieldModel.update(buttonColors: buttonColors)
                fieldModel.update(uploadingAttachments: fieldsUploadingAttachments[value.id] ?? [])
                fieldModel.update(pendingAttachments: fieldsPendingAttachments[value.id] ?? [])
                fieldModel.update(localStorageURLs: localStorageURLs)
                fieldModel.update(timeZone: meta.timeZone)
                fieldModel.update(primaryFieldId: primaryFieldID)
                if let oldFieldModel = wrappedFields.first(where: { $0.fieldID == value.id }) {
                    fieldModel.update(fieldPermission: oldFieldModel.fieldPermission)
                }
                if let buttonStatus = buttonFieldStatus[value.id] {
                    fieldModel.update(buttonStatus: buttonStatus)
                }
                return fieldModel
            } else {
                return nil
            }
        }
        originalFields = normalFieldModels
        if isFormMode {
            var fieldModel = BTFieldModel(recordID: recordID)
            fieldModel.update(timeZone: meta.timeZone)
            let formHeroImageModel = fieldModel.updating(formElementType: .formHeroImage)
            var customFormCoverModel = fieldModel.updating(formElementType: .customFormCover)
                customFormCoverModel.update(formBannerUrl: formBannerUrl)
            var formSubmitModel = fieldModel.updating(formElementType: .formSubmit)
            var submitState: Bool = false
            if normalFieldModels.isEmpty {
                submitState = editable
            } else {
                submitState = editable && normalFieldModels.contains { $0.editable }
            }
            formSubmitModel.update(canEditField: submitState && self.topTipType == .none )
            let formRecordCountModel = fieldModel.updating(formElementType: .recordCountOverLimit)
            var formTitleModel = fieldModel.updating(formElementType: .formTitle)
            formTitleModel.update(formTitle: meta.currentViewName)
            formTitleModel.update(formDescription: meta.currentViewDescription)
            if meta.viewUnreadableRequiredField {
                // 包含无阅读权限的field
                let formEmptyModel = fieldModel.updating(formElementType: .unreadable)
                wrappedFields = [formHeroImageModel, formTitleModel, formEmptyModel]
                return
            }
            if value.fields.isEmpty {
                    if self.topTipType == .recordLimit {
                        wrappedFields = [formHeroImageModel, formRecordCountModel, formTitleModel, formSubmitModel]
                    } else {
                wrappedFields = [formHeroImageModel, formTitleModel, formSubmitModel]
                    }
                
            } else {
                    if self.topTipType == .recordLimit {
                        wrappedFields = [formHeroImageModel, formRecordCountModel, formTitleModel] + normalFieldModels + [formSubmitModel]
                    } else {
                wrappedFields = [formHeroImageModel, formTitleModel] + normalFieldModels + [formSubmitModel]
                    }
            }
        } else {
            let hiddenFieldModels = normalFieldModels.filter { $0.isHidden }
            wrappedFields = []
            
            if hiddenFieldModels.isEmpty {
                wrappedFields += normalFieldModels
            } else {
                let showingFieldModels = normalFieldModels.filter { !$0.isHidden }
                let shouldDisclose = meta.shouldDiscloseHiddenFields
                var fieldModel = BTFieldModel(recordID: recordID)
                let disclosureEntryModel = fieldModel.updating(hiddenCount: hiddenFieldModels.count, isDisclosed: shouldDisclose)
                wrappedFields += showingFieldModels
                wrappedFields.append(disclosureEntryModel)
                if shouldDisclose {
                    wrappedFields += hiddenFieldModels
                }
            }

            if UserScopeNoChangeFG.ZJ.btCardReform {
                cardCoverId = meta.cardCoverId
                coverChangeAble = meta.coverChangeAble

                var fields = [BTFieldModel]()

                if let attachmentCoverField = createAttachmentCoverFieldModelIfNeeded() {
                    fields.append(attachmentCoverField)
                }

                var itemViewHeaderModel = BTFieldModel(recordID: recordID)
                itemViewHeaderModel.updating(elementType: .itemViewHeader)
                itemViewHeaderModel.update(formTitle: value.recordTitle)
                itemViewHeaderModel.update(showGradient: !shouldShowAttachmentCoverField())
                fields.append(itemViewHeaderModel)
                
                if shouldShowItemViewCatalogue {
                    var itemViewCatalogueModel = BTFieldModel(recordID: recordID)
                    itemViewCatalogueModel.update(mode: self.viewMode)
                    itemViewCatalogueModel.updating(elementType: .itemViewCatalogue)
                    fields.append(itemViewCatalogueModel)
                }
                
                if shouldShowItemViewTabs {
                    fields.append(newItemViewTabsFieldModel())
                }

                wrappedFields = fields + wrappedFields
            }
        }
        deletable = value.deletable
        shareable = value.shareable
    }
    
    private func newItemViewTabsFieldModel() -> BTFieldModel {
        var itemViewTabsModel = BTFieldModel(recordID: recordID)
        itemViewTabsModel.updating(elementType: .itemViewTabs)
        itemViewTabsModel.update(itemTabs: itemViewTabs)
        itemViewTabsModel.update(currentItemViewIndex: _currentItemViewIndex)
        return itemViewTabsModel
    }

    mutating func update(cardSize: CGSize) {
        size = cardSize
        wrappedFields = wrappedFields.map { model in
            var fieldModel = model
            fieldModel.update(fieldWidth: cardSize.width)
            fieldModel.update(itemViewHeight: cardSize.height)
            return fieldModel
        }
        
        originalFields = originalFields.map({ model in
            var fieldModel = model
            fieldModel.update(fieldWidth: cardSize.width)
            fieldModel.update(itemViewHeight: cardSize.height)
            return fieldModel
        })
    }

    mutating func update(editingField: String?) {
        if let index = getFieldIndex(id: editingField ?? editingFieldID) {
            var editingFieldModel = wrappedFields[index]
            editingFieldModel.update(isEditing: editingField != nil)
            wrappedFields[index] = editingFieldModel
        }
        editingFieldID = editingField
    }

    mutating func update(filtered: Bool) {
        isFiltered = filtered
    }
    
    mutating func update(filterTipClosed: Bool) {
        self.filterTipClosed = filterTipClosed
    }

    mutating func update(errorMsg: String, forFieldID fieldID: String) {
        if let fieldIndex = getFieldIndex(id: fieldID) {
            var fieldModel = wrappedFields[fieldIndex]
            fieldModel.update(errorMsg: errorMsg)
            wrappedFields[fieldIndex] = fieldModel
        }
    }
    
    mutating func update(canDeleteRecord: Bool) {
        deletable = canDeleteRecord
    }
    
    mutating func update(baseName: String) {
        self.baseName = baseName
    }

    mutating func update(canEditRecord: Bool) {
        editable = canEditRecord
    }
    
    mutating func update(canShareRecord: Bool) {
        shareable = canShareRecord
    }

    mutating func update(fieldEditable: Bool, fieldUneditableReason: BTFieldValue.UneditableReason) {
        wrappedFields = wrappedFields.map { fieldModel in
            var newFieldModel = fieldModel
            newFieldModel.update(canEditField: fieldEditable)
            newFieldModel.update(fieldUneditableReason: fieldUneditableReason)
            return newFieldModel
        }
        
        updateItemViewTabs()
    }

    mutating func update(descriptionIsLimited: Bool, forFieldID fieldID: String) {
        descriptionLimitStates[fieldID] = descriptionIsLimited
        if let fieldIndex = getFieldIndex(id: fieldID) {
            var fieldModel = wrappedFields[fieldIndex]
            fieldModel.update(descriptionIsLimited: descriptionIsLimited)
            wrappedFields[fieldIndex] = fieldModel
        }
    }

    mutating func update(descriptionIndicatorIsSelected: Bool, forFieldID fieldID: String) {
        descriptionIndicatorSelectionStates[fieldID] = descriptionIndicatorIsSelected
        if let fieldIndex = getFieldIndex(id: fieldID) {
            var fieldModel = wrappedFields[fieldIndex]
            fieldModel.update(descriptionIndicatorIsSelected: descriptionIndicatorIsSelected)
            wrappedFields[fieldIndex] = fieldModel
        }
    }

    mutating func update(selected: Bool) {
        isSelected = selected
    }

    mutating func update(fields: [BTFieldModel]) {
        wrappedFields = fields
    }
    
    @discardableResult
    mutating func update(_ fieldModel: BTFieldModel, for index: Int) -> Bool {
        var updateOK = false
        if let fieldIndex = wrappedFields.firstIndex(where: { $0.fieldID == fieldModel.fieldID }) {
            self.wrappedFields[fieldIndex] = fieldModel
            DocsLogger.btInfo("updateField wrappedFields")
            updateOK = true
        }
        
        if !UserScopeNoChangeFG.ZJ.btItemViewOriginFieldsFixDisable, let originalFieldIndex = originalFields.firstIndex(where: { $0.fieldID == fieldModel.fieldID }) {
            self.originalFields[originalFieldIndex] = fieldModel
            DocsLogger.btInfo("updateField originalFields")
            updateOK = true
        }
        
        DocsLogger.btError("updateField error index")
        return updateOK
    }

    mutating func update(textSegments: [BTRichTextSegmentModel], forFieldID fieldID: String) {
        if let textFieldIndex = getFieldIndex(id: fieldID) {
            var textFieldModel = wrappedFields[textFieldIndex]
            textFieldModel.update(textSegments: textSegments)
            wrappedFields[textFieldIndex] = textFieldModel
        }
    }
    
    mutating func update(numberValueDraft: String?, fieldID: String) {
        if let index = getFieldIndex(id: fieldID) {
            var field = wrappedFields[index]
            field.update(numberValueDraft: numberValueDraft)
            wrappedFields[index] = field
        }
    }

    mutating func removeAllUploadingAttachments() {
        for (fieldID, _) in fieldsUploadingAttachments {
            if let attachmentFieldIndex = getFieldIndex(id: fieldID) {
                var attachmentFieldModel = wrappedFields[attachmentFieldIndex]
                attachmentFieldModel.update(uploadingAttachments: [])
                wrappedFields[attachmentFieldIndex] = attachmentFieldModel
            }
        }
        fieldsUploadingAttachments.removeAll()
    }

    mutating func update(uploadingAttachments: [BTMediaUploadInfo], forFieldID fieldID: String) {
        fieldsUploadingAttachments[fieldID] = uploadingAttachments
        if let attachmentFieldIndex = getFieldIndex(id: fieldID) {
            var attachmentFieldModel = wrappedFields[attachmentFieldIndex]
            attachmentFieldModel.update(uploadingAttachments: uploadingAttachments)
            wrappedFields[attachmentFieldIndex] = attachmentFieldModel
        }
    }

    mutating func removeAllPendingAttachments() {
        for (fieldID, _) in fieldsPendingAttachments {
            if let attachmentFieldIndex = getFieldIndex(id: fieldID) {
                var attachmentFieldModel = wrappedFields[attachmentFieldIndex]
                attachmentFieldModel.update(pendingAttachments: [])
                wrappedFields[attachmentFieldIndex] = attachmentFieldModel
            }
        }
        fieldsPendingAttachments.removeAll()
    }

    mutating func update(pendingAttachments: [PendingAttachment], forFieldID fieldID: String) {
        fieldsPendingAttachments[fieldID] = pendingAttachments
        if let attachmentFieldIndex = getFieldIndex(id: fieldID) {
            var attachmentFieldModel = wrappedFields[attachmentFieldIndex]
            attachmentFieldModel.update(pendingAttachments: pendingAttachments)
            wrappedFields[attachmentFieldIndex] = attachmentFieldModel
        }
    }

    mutating func update(localStorageURLs: [String: URL]) {
        self.localStorageURLs = localStorageURLs
        wrappedFields = wrappedFields.map { model in
            var fieldModel = model
            fieldModel.update(localStorageURLs: localStorageURLs)
            return fieldModel
        }
    }
    
    mutating func update(phoneValues: [BTPhoneModel], forFieldID fieldID: String) {
        if let fieldIndex = getFieldIndex(id: fieldID) {
            var fieldModel = wrappedFields[fieldIndex]
            fieldModel.update(phoneValues: phoneValues)
            wrappedFields[fieldIndex] = fieldModel
        
        }
    }
    mutating func update(fetchingGeoLoocationFields: Set<String>) {
        let newFetchingFields = fetchingGeoLoocationFields
        let oldFetchingFields = self.fieldsFetchGeoLocation
        let needToggleToTrue = newFetchingFields.subtracting(oldFetchingFields)
        let needToggleToFalse = oldFetchingFields.subtracting(newFetchingFields)
        self.fieldsFetchGeoLocation = fetchingGeoLoocationFields
        needToggleToTrue.forEach {
            if let fieldIndex = getFieldIndex(id: $0) {
                var fieldModel = wrappedFields[fieldIndex]
                fieldModel.update(isFetchingGeoLocation: true)
                wrappedFields[fieldIndex] = fieldModel
            }
        }
        needToggleToFalse.forEach {
            if let fieldIndex = getFieldIndex(id: $0) {
                var fieldModel = wrappedFields[fieldIndex]
                fieldModel.update(isFetchingGeoLocation: false)
                wrappedFields[fieldIndex] = fieldModel
            }
        }
    }
    
    mutating func update(status: BTRecordValueStatus) {
        dataStatus = status
    }

    func getFieldModel(id: String?) -> BTFieldModel? {
        return wrappedFields.first { $0.fieldID == id }
    }

    func getFieldIndex(id: String?) -> Int? {
        return wrappedFields.firstIndex(where: { $0.fieldID == id })
    }
    
    mutating func update(shouldShowSubmitTopTip: Bool) {
        self.shouldShowSubmitTopTip = shouldShowSubmitTopTip
    }
    
    mutating func update(canAddRecord: Bool) {
        self.canAddRecord = canAddRecord
    }
    
    mutating func update(buttonStatus: [String: BTButtonFieldStatus]) {
        self.buttonFieldStatus = buttonStatus
    }
    
    mutating func update(fieldID: String, buttonStatus: BTButtonFieldStatus) {
        if let fieldIndex = getFieldIndex(id: fieldID) {
            var fieldModel = wrappedFields[fieldIndex]
            fieldModel.update(buttonStatus: buttonStatus)
            wrappedFields[fieldIndex] = fieldModel
        }
        
        self.buttonFieldStatus.updateValue(buttonStatus, forKey: fieldID)
    }
    
    mutating func update(buttonColors: [BTButtonColorModel]) {
        self.buttonColors = buttonColors
    }
    
    mutating func update(isFormulaServiceSuspend: Bool?) {
        self.isFormulaServiceSuspend = isFormulaServiceSuspend
    }

    mutating func update(formBannerUrl: String?) {
        self.formBannerUrl = formBannerUrl
    }
    
    mutating func update(recordTitle: String) {
        self.recordTitle = recordTitle
    }
    
    mutating func update(topTip type: BTTopTipType) {
        self.topTipType = type
    }
    
    mutating func update(viewMode: BTViewMode) {
        self.viewMode = viewMode
        wrappedFields = wrappedFields.map({ field in
            var newField = field
            newField.update(mode: viewMode)
            return newField
        })
    }
    
    mutating func update(currentItemViewIndex: Int) {
        self.currentItemViewIndex = currentItemViewIndex
    }
    
    mutating func resetStageFieldType() {
        wrappedFields = wrappedFields.map({ field in
            var newField = field
            if newField.compositeType.uiType == .stage {
                // 初始化阶段字段样式
                newField.updateMockStageField(type: .inherent(field.compositeType))
            }
            newField.update(errorMsg: "")
            return newField
        })
    }
    
    mutating func resetFieldsErrorMsg() {
        wrappedFields = wrappedFields.map({ field in
            var newField = field
            newField.update(errorMsg: "")
            return newField
        })
    }
    
    mutating func update(stageRequiredFields: [String: [String: [String]]]) {
        self.stageRequiredFields = stageRequiredFields
    }
    
    mutating func update(stageFieldId: String, requiredFields: [String: [String]]) {
        self.stageRequiredFields.updateValue(requiredFields, forKey: stageFieldId)
    }

    mutating func update(forceUpdateWhenWillDisplay: Bool) {
        self.forceUpdateWhenWillDisplay = forceUpdateWhenWillDisplay
    }
    
    private mutating func updateOriginalFields() {
        wrappedFields.forEach { field in
            if let index = originalFields.firstIndex(where: { $0.fieldID == field.fieldID }) {
                originalFields[index] = field
            }
        }
    }
    
    private mutating func updateItemViewTabs() {
        guard !UserScopeNoChangeFG.ZJ.btItemViewProAddStageFieldFixDisable else {
            return
        }
        
        if shouldShowItemViewTabs {
            if let oldIndex = wrappedFields.firstIndex(where: { $0.extendedType == .itemViewTabs }) {
                wrappedFields.remove(at: oldIndex)
            }
            
            var itemViewTabsModel = newItemViewTabsFieldModel()
            
            if UserScopeNoChangeFG.YY.bitableRecordShareCatalogueDisable {
                let headerIndex = wrappedFields.firstIndex(where: { $0.extendedType == .itemViewHeader }) ?? 0
                wrappedFields.insert(itemViewTabsModel, at: headerIndex + 1)
            } else {
                let lastIndex = wrappedFields.lastIndex(where: {
                    // 顺序上是否是在 .itemViewTabs 前面
                    switch $0.extendedType {
                    case .inherent(_), .formHeroImage, .customFormCover, .formTitle, .formSubmit,
                            .hiddenFieldsDisclosure, .unreadable, .recordCountOverLimit,
                            .stageDetail, .itemViewTabs:
                        return false
                    case .itemViewHeader:
                        return true
                    case .attachmentCover:
                        return true
                    case .itemViewCatalogue:
                        return true
                    }
                }) ?? 0
                wrappedFields.insert(itemViewTabsModel, at: lastIndex + 1)
            }
        } else {
            wrappedFields.removeAll(where: { $0.extendedType == .itemViewTabs })
        }
    }
}

extension BTRecordModel: AnimatableSectionModelType {

    typealias Identity = String

    typealias Item = BTFieldModel

    var identity: String { isFiltered ? "FILTERED_RECORD" : identify }

    var items: [BTFieldModel] { wrappedFields }

    init(original: Self, items: [Self.Item]) {
        self = original
        wrappedFields = items
    }
}
