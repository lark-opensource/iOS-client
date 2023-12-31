//
// Created by duanxiaochen.7 on 2022/3/22.
// Affiliated with SKBitable.
//
// Description:

import SKFoundation
import RxDataSources
import SKBrowser
import SKCommon

struct BTTableModel: Equatable {

    private(set) var baseID: String = ""
    
    private(set) var baseName: String = ""

    private(set) var tableID: String = ""
    
    //记录卡片总数
    private(set) var total: Int = 0

    private var lock = NSLock()
    
    private var _records: [BTRecordModel] = []

    private(set) var records: [BTRecordModel] {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _records
        }

        set {
            lock.lock()
            defer {
                lock.unlock()
            }
            _records = newValue
        }
    }

    private(set) var mode: BTViewMode = .card

    private(set) var bizType: String = ""

    private(set) var viewType: String = "grid"

    private(set) var editingRecordID: String?

    private(set) var editingFieldID: String?
    /// 表单场景下描述内容是否展开
    private(set) var descriptionLimitStates: [String: Bool] = [:]
    /// 卡片场景下描述ⓘ按钮是否被点亮
    private(set) var descriptionIndicatorSelectionStates: [String: Bool] = [:]
    /// 正在上传的附件
    private(set) var uploadingAttachments: [BTFieldLocation: [BTMediaUploadInfo]] = [:]
    /// 等候上传的附件
    private(set) var pendingAttachments: [BTFieldLocation: [PendingAttachment]] = [:]
    /// 刚上传好的附件的本地地址，用于显示缩略图
    /// key 是 drive token
    private(set) var localStorageURLs: [String: URL] = [:]
    /// 该值的优先级高于 BTRecordValue 里的配置，用于处理用户手动点击 x 的场景
    private(set) var isFiltered: Bool?
    /// 记录被过滤的提示是否被用户关闭
    private(set) var filterTipClosed: Bool?
    /// 该值的优先级高于 BTTableMeta 里的配置，用于处理用户手动点击开关的场景
    private(set) var shouldDiscloseHiddenFields: Bool?
    /// 正在获取当前地理位置的field
    private(set) var fetchingGeoLocations: Set<BTFieldLocation> = []
    /// 是否显示过先填写后添加
    private(set) var submitTopTipShowed: Bool = false
    /// 是否在右上角显示“继续添加记录”菜单
    private(set) var canAddRecord: Bool = false
    /// true代表是scheme4新文档
    private(set) var isFormulaServiceSuspend: Bool?
    /// 表单下行数超限提示
    private(set) var topTipType: BTTopTipType = .none
    /// 卡片需要关闭的原因
    private(set) var cardCloseReason: CardCloseReason?

    var shouldShowAttachmentCover: Bool {
        return records.first?.shouldShowAttachmentCoverField() ?? false
    }

    mutating func update(meta: BTTableMeta, value: BTTableValue, mode: BTViewMode, holdDataProvider: BTHoldDataProvider?) {
        baseID = value.baseId
        tableID = value.tableId
        total = value.total
        submitTopTipShowed = meta.submitTopTipShowed
        cardCloseReason = meta.cardCloseReason
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            isFormulaServiceSuspend = meta.isFormulaServiceSuspend
        }
        var updatedMeta = meta
        if let shouldDiscloseHiddenFields = shouldDiscloseHiddenFields {
            updatedMeta.shouldDiscloseHiddenFields = shouldDiscloseHiddenFields
        }
        records = value.records.map { val in
            var updatedVal = val
            if let isFiltered = isFiltered {
                updatedVal.isFiltered = isFiltered
            }
            var recordModel = BTRecordModel()
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                recordModel.update(isFormulaServiceSuspend: meta.isFormulaServiceSuspend)
            }
            var viewMode = mode
            if let record = records.first(where: { $0.recordID == val.recordId }) {
                recordModel.update(buttonStatus: record.buttonFieldStatus)
                recordModel.update(currentItemViewIndex: record.currentItemViewIndex)
                recordModel.update(stageRequiredFields: record.stageRequiredFields)
                if UserScopeNoChangeFG.ZJ.btCardReform {
                    viewMode = record.viewMode
                }
            }
            recordModel.update(baseName: baseName)
            recordModel.update(shouldShowSubmitTopTip: !meta.submitTopTipShowed && meta.isPro)
            recordModel.update(canAddRecord: canAddRecord)
            recordModel.update(topTip: topTipType)
            recordModel.update(meta: updatedMeta, value: updatedVal, mode: viewMode, holdDataProvider: holdDataProvider)
            for (location, infos) in uploadingAttachments where location.recordID == val.recordId {
                recordModel.update(uploadingAttachments: infos, forFieldID: location.fieldID)
            }
            for (location, infos) in pendingAttachments where location.recordID == val.recordId {
                recordModel.update(pendingAttachments: infos, forFieldID: location.fieldID)
            }
            recordModel.update(localStorageURLs: localStorageURLs)
            for (fieldID, limited) in descriptionLimitStates {
                recordModel.update(descriptionIsLimited: limited, forFieldID: fieldID)
            }
            for (fieldID, selected) in descriptionIndicatorSelectionStates {
                recordModel.update(descriptionIndicatorIsSelected: selected, forFieldID: fieldID)
            }
            return recordModel
        }
        update(editingRecord: editingRecordID, editingField: editingFieldID)
        self.mode = mode
        self.bizType = meta.bizType
        self.viewType = meta.viewType
    }

    mutating func update(descriptionIsLimited: Bool, forFieldID fieldID: String) {
        descriptionLimitStates[fieldID] = descriptionIsLimited
        records = records.map { model in
            var recordModel = model
            recordModel.update(descriptionIsLimited: descriptionIsLimited, forFieldID: fieldID)
            return recordModel
        }
    }

    mutating func update(descriptionIndicatorIsSelected: Bool, forFieldID fieldID: String, recordID: String) {
        descriptionIndicatorSelectionStates[fieldID] = descriptionIndicatorIsSelected
        if let index = records.firstIndex(where: { $0.recordID == recordID }) {
            var recordModel = records[index]
            recordModel.update(descriptionIndicatorIsSelected: descriptionIndicatorIsSelected, forFieldID: fieldID)
            records[index] = recordModel
        }
    }

    mutating func update(errorMsg: String, forFieldID fieldID: String) {
        records = records.map { model in
            var recordModel = model
            recordModel.update(errorMsg: errorMsg, forFieldID: fieldID)
            return recordModel
        }
    }
    
    mutating func updateAndReset(errorMsg: String, forFieldID fieldID: String) {
        // 重置过往数据
        records = records.map { model in
            var recordModel = model
            let newFields = recordModel.wrappedFields.map {
                var field = $0
                field.update(errorMsg: $0.fieldID == fieldID ? errorMsg : "")
                return field
            }
            recordModel.update(fields: newFields)
            return recordModel
        }
    }
    
    mutating func update(baseName: String) {
        self.baseName = baseName
        records = records.map { model in
            var recordModel = model
            recordModel.update(baseName: baseName)
            return recordModel
        }
    }
    
    mutating func update(submitTopTipShowed: Bool) {
        self.submitTopTipShowed = submitTopTipShowed
        records = records.map({ record in
            var copyRecord = record
            copyRecord.update(shouldShowSubmitTopTip: !submitTopTipShowed)
            return copyRecord
        })
    }
    
    mutating func update(canAddRecord: Bool) {
        self.canAddRecord = canAddRecord
        records = records.map({ record in
            var copyRecord = record
            copyRecord.update(canAddRecord: canAddRecord)
            return copyRecord
        })
    }

    mutating func update(isFiltered: Bool) {
        self.isFiltered = isFiltered
        records = records.map { model in
            var recordModel = model
            recordModel.update(filtered: isFiltered)
            return recordModel
        }
    }
    
    mutating func update(filterTipClosed: Bool) {
        self.filterTipClosed = filterTipClosed
        records = records.map { model in
            var recordModel = model
            recordModel.update(filterTipClosed: filterTipClosed)
            return recordModel
        }
    }

    mutating func update(uploadingAttachments: [BTFieldLocation: [BTMediaUploadInfo]]) {
        self.uploadingAttachments = uploadingAttachments
        records = records.map { model in
            var recordModel = model
            recordModel.removeAllUploadingAttachments()
            for (location, infos) in uploadingAttachments where location.recordID == model.recordID {
                recordModel.update(uploadingAttachments: infos, forFieldID: location.fieldID)
            }
            return recordModel
        }
    }

    mutating func update(pendingAttachments: [BTFieldLocation: [PendingAttachment]]) {
        self.pendingAttachments = pendingAttachments
        records = records.map { model in
            var recordModel = model
            recordModel.removeAllPendingAttachments()
            for (location, infos) in pendingAttachments where location.recordID == model.recordID {
                recordModel.update(pendingAttachments: infos, forFieldID: location.fieldID)
            }
            return recordModel
        }
    }

    mutating func update(localStorageURLs: [String: URL]) {
        self.localStorageURLs = localStorageURLs
        records = records.map { model in
            var recordModel = model
            recordModel.update(localStorageURLs: localStorageURLs)
            return recordModel
        }
    }

    mutating func update(editingRecord: String?, editingField: String?) {
        if let index = records.firstIndex(where: { $0.recordID == (editingRecord ?? editingRecordID) }) {
            var editingRecordModel = records[index]
            editingRecordModel.update(editingField: editingField)
            records[index] = editingRecordModel
        }
        editingRecordID = editingRecord
        editingFieldID = editingField
    }

    mutating func update(shouldDiscloseHiddenFields: Bool) {
        self.shouldDiscloseHiddenFields = shouldDiscloseHiddenFields
    }

    mutating func update(textSegments: [BTRichTextSegmentModel], forRecordID recordID: String, fieldID: String) {
        if let recordIndex = records.firstIndex(where: { $0.recordID == recordID }) {
            var recordModel = records[recordIndex]
            recordModel.update(textSegments: textSegments, forFieldID: fieldID)
            records[recordIndex] = recordModel
        }
    }
    
    mutating func update(numberValueDraft: String?, recordID: String, fieldID: String) {
        if let recordIndex = records.firstIndex(where: { $0.recordID == recordID }) {
            var recordModel = records[recordIndex]
            recordModel.update(numberValueDraft: numberValueDraft, fieldID: fieldID)
            records[recordIndex] = recordModel
        }
    }
    
    mutating func update(phoneValues: [BTPhoneModel], forRecordID recordID: String, fieldID: String) {
        if let recordIndex = records.firstIndex(where: { $0.recordID == recordID }) {
            var recordModel = records[recordIndex]
            recordModel.update(phoneValues: phoneValues, forFieldID: fieldID)
            records[recordIndex] = recordModel
        }
    }
    mutating func update(fetchingGeoLocationFields locations: Set<BTFieldLocation>) {
        self.fetchingGeoLocations = locations
        records = records.map { model in
            var recordModel = model
            let fields = locations
                .filter({ $0.recordID == model.recordID })
                .map({ $0.fieldID })
            recordModel.update(fetchingGeoLoocationFields: Set(fields))
            return recordModel
        }
    }

    func getRecordModel(id: String) -> BTRecordModel? {
        return records.first(where: { $0.recordID == id })
    }

    @discardableResult
    mutating func updateRecord(_ record: BTRecordModel, for index: Int) -> Bool {
        guard records.count > index else {
            DocsLogger.btError("updateRecord out of index")
            return false
        }
        let newRecord = records[index]
        guard newRecord.recordID == record.recordID else {
            DocsLogger.btError("updateRecord error index")
            return false
        }
        self.records[index] = record
        return true
    }
    
    mutating func update(recordID: String, fieldID: String, buttonStatus: BTButtonFieldStatus) {
        var recordIndexs: [Int] = []
        for (index, record) in records.enumerated() where record.recordID == recordID {
            recordIndexs.append(index)
        }
        
        recordIndexs.forEach { index in
            var recordModel = records[index]
            recordModel.update(fieldID: fieldID, buttonStatus: buttonStatus)
            self.records[index] = recordModel
        }
    }
    
    mutating func update(topTip type: BTTopTipType) {
        self.topTipType = type
    }

    mutating func update(forceUpdateWhenWillDisplay: Bool, recordIndex: Int) {
        guard recordIndex < records.count else {
            return
        }
        records[recordIndex].update(forceUpdateWhenWillDisplay: forceUpdateWhenWillDisplay)
    }
}

extension BTTableModel: AnimatableSectionModelType {

    typealias Identity = String

    typealias Item = BTRecordModel

    var identity: String { tableID }

    var items: [BTRecordModel] { records }

    init(original: Self, items: [Self.Item]) {
        self = original
        records = items
    }
}
