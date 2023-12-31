//
//  BTViewModel.swift
//  DocsSDK
//
//  Created by Webster on 2020/3/13.
//  swiftlint:disable file_length

import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import RxSwift
import SpaceInterface

/// 获取数据时的错误
enum BTGetTableDataError: Error {
    case recordsEmpty
}

indirect enum BTViewMode: Equatable, CustomStringConvertible {
    
    // 仅用于埋点
    var trackValue: String {
        switch self {
        case .card:
            return "card"
        case .link:
            return "link"
        case .submit:
            return "submit"
        case .form:
            return "form"
        case .indRecord:
            return "indRecord"
        case .stage(let origin):
            return "stage"
        case .addRecord:
            return "addRecord"
        }
    }
    
    case card // 普通卡片
    case link// 关联记录卡片
    case submit // 提交模式
    case form // 表单
    case indRecord // 记录分享卡片
    case stage(origin: BTViewMode) // 阶段
    case addRecord  // 快捷新建记录

    var description: String {
        switch self {
        case .card: return "base bt card"
        case .link: return "linked bt card"
        case .submit: return "submit"
        case .form: return "form"
        case .indRecord: return "ind record"
        case .stage: return "stage detail"
        case .addRecord: return "add record"
        }
    }
    
    var openType: BTStatisticOpenFileType {
        switch self {
        case .card, .link, .submit, .form, .stage:
            return .main
        case .indRecord:
            return .share_record
        case .addRecord:
            return .base_add
        }
    }
    
    var isCard: Bool {
        self == .card
    }
    
    var isLinkedRecord: Bool {
        if case .link = self {
            return true
        }
        return false
    }
    
    var isIndRecord: Bool {
        self == .indRecord
    }
    
    /// 是否为 Base 外新建记录场景
    var isAddRecord: Bool {
        self == .addRecord
    }
    
    /// 是否为 Base 内新建记录场景
    var isSubmitRecord: Bool {
        self == .submit
    }
    
    var isStage: Bool {
        if case .stage(_) = self {
            return true
        }
        return false
    }

    var isForm: Bool {
        return self == .form
    }
    
    // 正常show出来的
    var isNormalShowRecord: Bool {
        return self != .form && self != .indRecord
    }
    
    var needScrollToCurrentCardAfterUpdate: Bool {
        if UserScopeNoChangeFG.ZJ.btCardReform {
            return !self.isForm
        }
        
        return !self.isForm && !self.isStage
    }
    
    var shouldShowItemViewCatalogue: Bool {
        switch self {
        case .card, .link, .submit, .form:
            return false
        case .indRecord, .addRecord:
            return true
        case .stage(let origin):
            return origin.shouldShowItemViewCatalogue
        }
    }
}

enum BTGetCardListRequestStatus: String {
    case start //初始状态
    case waiting //等待dataLoaded信号
    case processing //请求处理中
    case timeOut //请求超时
    case failed //请求失败
    case success //请求成功
}

struct BTGetCardListModel: Hashable {
    var baseId: String = ""
    var tableId: String = ""
    var viewId: String = ""
    var startFromLeft: Int = 0 //是基于当前 record 向左的偏移
    var fetchCount: Int = 0 //分页请求卡片数
    var firstVisibleRecordId: String? //当前第一个可见的记录ID
    var recordIds: [String]? //当前视图中心的卡片ID，关联面板的情况下是当前可视的所有recordID
    var groupValue: String? //当前卡片分组ID，看板视图透传给前端
    var fieldIds: [String]? //字段ID，用来请求关联记录数据时只请求主键信息
    var searchKey: String? //搜索关键字
    var requestingForInvisibleRecords: Bool = false //是否请求不可见的卡片
}

struct BTGetCardListRequest: Hashable {
    static func == (lhs: BTGetCardListRequest, rhs: BTGetCardListRequest) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var requestId: String = "" //请求ID
    var requestType: BTCardFetchType = .initialize(true) //请求类型
    var requestStatus: BTGetCardListRequestStatus = .start //请求状态
    var requestModel: BTGetCardListModel = BTGetCardListModel() //请求参数
    var requestTimer: Timer? //请求超时计时器
    var requestLinkLevel: Int = 0 //关联卡片请求当前层数
    var isRetryRequest: Bool = false //是否是重试的请求
    var overTimeInterval: Double = 10 //请求超时时间
    var completionBlock: ((Bool) -> Void)? //请求完成回调，包括请求超时和失败，bool值表示请求是否成功

    func hash(into hasher: inout Hasher) {
        hasher.combine(requestType)
        if requestType != .left && requestType != .right {
            hasher.combine(requestModel)
        }
    }
    
    mutating func invalidateTimer() {
        requestTimer?.invalidate()
        requestTimer = nil
    }
}

enum BTViewModelConst {
    static let preloadOffset: Int = 1 //预加载偏移量
}

final class BTViewModel {
    
    static var chatterIDTokenMap = [String: String]()

    /// 视图类型
    var mode: BTViewMode

    /// 上层传过来的被关联的 recordID 数组
    var recordIDs: [String]
    
    /// 数据拉取接口
    weak var dataService: BTDataService?

    /// 其实就是 BTController
    weak var listener: BTViewModelListener?

    /// 最新的前端action信息
    private(set) var actionParams: BTActionParamsModel

    /// 表格结构
    private(set) var tableMeta = BTTableMeta()

    /// 记录数据
    private(set) var tableValue = BTTableValue()
    
    /// 当前点击的阶段字段id
    private(set) var stageFieldId: String = ""

    var tableModel = BTTableModel()

    var unfilteredRecords: [BTRecordModel] {
        tableModel.records.filter { !$0.isFiltered }
    }

    //保证fetch过程互斥
    private let fetchSemaphore = DispatchSemaphore(value: 1)

    private var activeRecordIndex = 0

    private var activeRecordID: String = ""
    
    /// 是否是来自之前通过提交模式创建的记录预览（右上角菜单需要增加继续创建）
    private(set) var preMockRecordId: String?
    
    //卡片分组ID，同一张卡片可能出现在多个分组，需要用分组ID + 卡片ID来唯一标识卡片
    var activeRecordGroupValue: String = ""

    private lazy var fetchQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "spacekit.bitable.vm", qos: DispatchQoS.userInteractive)
        return queue
    }()

    private var isDismissing = false
    
    let disposeBag: DisposeBag = DisposeBag()

    var bizData: BTDataBizInfo { _BizInfo(dataService: dataService) }

    var hostChatId: String? { dataService?.hostChatId }

    var openCardTracker: OpenCardTracker?

    /// 这里的 docsInfo? 和 bizData.docInfo 都是来自 dataService?.docInfo，不同之处在于
    /// 这里返回的是 Optional 值。新逻辑建议优先使用此值，正确处理nil有助于提高代码的可维护性。
    /// bizData.docInfo 返回的是非 Optional 值，在 dataService = nil 时其内部返回了一个默认值。新逻辑不建议使用此值，除非有特殊需求需要返回一个非空值。
    var hostDocsInfo: DocsInfo? {
        dataService?.hostDocInfo
    }
    
    var bitableIsReady: Bool {
        didSet {
            guard bitableIsReady != oldValue else { return }
            if bitableIsReady {
                DocsLogger.btInfo("[Status] BTViewModel bitableIsReadyDidSet: \(bitableIsReady),  mode: \(mode), recordIDs: \(recordIDs)")
                listener?.bitableReady()
            }
        }
    }

    var currentRecordIndex: Int {
        var recordID = currentRecordID
        if let currentLoadingRecordID = currentLoadingRecordID {
            //因为展示loading卡片时没有记录loading卡片的fake ID
            //会导致卡片列表发生变化时，调用scrollToCurrentCard，当前显示的是loading卡片时，会滚动到loading卡片的上一张或者下一张
            recordID = currentLoadingRecordID
        }
        
        let matchIndex = tableModel.records.firstIndex {
            let isMatched = $0.recordID == recordID
            if activeRecordGroupValue.isEmpty {
                return isMatched
            } else {
                return isMatched && $0.groupValue == activeRecordGroupValue
            }
        }
        if let index = matchIndex {
            activeRecordIndex = Int(index)
        } else {
            let count = tableModel.records.count
            if count == 0 {
                activeRecordIndex = -1
            } else {
                activeRecordIndex = min(max(0, activeRecordIndex), count - 1)
            }
            
            //没有匹配上证明loading卡片被删除
            currentLoadingRecordID = nil
        }
        return activeRecordIndex
    }

    var currentRecordID: String { activeRecordID }
    
    //当前正在展示的loading卡片ID
    var currentLoadingRecordID: String?
    
    var fetchDataManager = BTFetchDataManager()

    var context: BTContext

    let fpsTrace: BTRecordFPSTrace

    var shouldShowItemViewTabs: Bool {
        return tableModel.records.first?.shouldShowItemViewTabs ?? false
    }

    var shouldShowAttachmentCover: Bool {
        return tableModel.records.first?.shouldShowAttachmentCoverField() ?? false
    }
    
    var shouldShowItemViewCatalogue: Bool {
        return tableModel.records.first?.shouldShowItemViewCatalogue ?? false
    }
    
    var currentCardPresentMode: CardPresentMode = .fullScreen

    var baseContext: BaseContext

    var hasTTU: Bool = false
    var hasTTV: Bool = false

    var canEditAttachmentCover: Bool {
        guard mode != .indRecord else {
            return false
        }
        return tableMeta.coverChangeAble
    }

    var shouldShowCoverOperationInMenu: Bool {
        guard UserScopeNoChangeFG.PXR.bitableRecordSubscribeEnable else {
            return false
        }
        return canEditAttachmentCover
    }
    
    init(mode: BTViewMode,
         recordIDs: [String] = [],
         stageFieldId: String = "",
         dataService: BTDataService?,
         cardActionParams: BTActionParamsModel,
         baseContext: BaseContext,
         bitableIsReady: Bool = false,
         context: BTContext) {
        if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
            // 最开始mode其实不准确，但是本期把viewType带过来，就是准确的form视图下是准确的，方便更早的判断是表单模式
            self.mode = cardActionParams.data.viewType == .form ? .form : mode
        } else {
            self.mode = mode
        }
        self.recordIDs = recordIDs
        self.dataService = dataService
        self.actionParams = cardActionParams
        self.baseContext = baseContext
        self.stageFieldId = stageFieldId
        if cardActionParams.originBaseID.isEmpty {
            self.actionParams.originBaseID = cardActionParams.data.baseId
        }
        if cardActionParams.originTableID.isEmpty {
            self.actionParams.originTableID = cardActionParams.data.tableId
        }
        self.activeRecordID = cardActionParams.data.recordId
        self.bitableIsReady = bitableIsReady
        self.context = context

        let openType = mode.isIndRecord ? BTStatisticOpenFileType.share_record.rawValue : BTStatisticOpenFileType.main.rawValue
        fpsTrace = BTRecordFPSTrace(openType: openType)

        self.fetchDataManager.delegate = self
    }

    func kickoff() {
        fetchDataManager.clearWaitingAndDisposingRequests()
        getCommonData()
        constructCardRequest(.initialize(self.bitableIsReady), completionBlock: { [weak self] success in
            guard success else {
                self?.handleOpenRecordFail()
                return
            }
            self?.notifyTableInit()
        })
    }
    
    func updateRecord(meta: BTTableMeta, value: BTTableValue) {
        self.recordIDs = value.records.map({ value in
            value.recordId
        })
        self.tableMeta = meta
        self.tableValue = value
        self.tableModel.update(meta: meta, value: value, mode: self.mode, holdDataProvider: dataService?.holdDataProvider)
	}

    func updateAddRecord(meta: BTTableMeta, value: BTTableValue, baseName: String) {
        self.recordIDs = value.records.map({ value in
            value.recordId
        })
        self.tableModel.update(baseName: baseName)
        self.tableMeta = meta
        self.tableValue = value
        self.tableModel.update(meta: meta, value: value, mode: self.mode, holdDataProvider: dataService?.holdDataProvider)
    }
    
    func updateBaseName(baseName: String) {
        self.tableModel.update(baseName: baseName)
    }

    private func handleOpenRecordFail() {
        if let traceId = context.openRecordTraceId {
            BTOpenRecordReportHelper.reportOpenFail(traceId: traceId)
        }

        if let traceId = context.openBaseTraceId {
            if mode == .indRecord {
                BTOpenFileReportMonitor.reportOpenShareRecordFail(traceId: traceId)
            } else if mode == .form {
                BTOpenFileReportMonitor.reportOpenFormFail(traceId: traceId)
            }
        }
    }

    func fetchRecords(_ request: BTGetCardListRequest,
                      successBlock: @escaping (Bool) -> Void,
                      failedBlock: @escaping (Error?) -> Void) {
        switch request.requestType {
        case .initialize:
            initialize(with: request, successBlock, failedBlock)
        case .update, .bitableReady:
            updateMetaThenData(with: request, successBlock, failedBlock)
        case .onlyData:
            updateOnlyData(with: request, successBlock, failedBlock)
        case .left:
            fetchLeftRecords(with: request, successBlock, failedBlock)
        case .right:
            fetchRightRecords(with: request, successBlock, failedBlock)
        case .filteredOnlyOne:
            fetchFilteredOnlyOneRecord(with: request, successBlock, failedBlock)
        default:
            break
        }
    }

    func markDismissing() {
        isDismissing = true
    }
    
    ///获取bitable commonData数据
    func getCommonData() {
        dataService?.getBitableCommonData(args: BTGetBitableCommonDataArgs(type: .colorList, tableID: actionParams.data.tableId)) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                DocsLogger.btError("[SYNC] getColorList failed error:\(error)")
                return
            }
            
            guard let dataDic = result as? [String: Any],
                  let resultData = dataDic["ColorList"] as? [[String: Any]],
                  let colorList = [BTColorModel].deserialize(from: resultData) else {
                DocsLogger.btError("[SYNC] getColorList decode error")
                return
            }
            
            DocsLogger.btInfo("[SYNC] getColorList success")
            self.tableMeta.colors = colorList.compactMap({ $0 })
            self.tableModel.update(meta: self.tableMeta, value: self.tableValue, mode: self.mode, holdDataProvider: dataService?.holdDataProvider)
        }
        
        dataService?.getBitableCommonData(args: BTGetBitableCommonDataArgs(type: .buttonColorList, tableID: actionParams.data.tableId)) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                DocsLogger.btError("[SYNC] getButtonColorList failed error:\(error)")
                return
            }
            
            guard let dataDic = result as? [String: Any],
                  let resultData = dataDic["buttonColorList"] as? [[String: Any]],
                  let buttonColors = [BTButtonColorModel].deserialize(from: resultData) else {
                DocsLogger.btError("[SYNC] getButtonColorList decode error")
                return
            }
            
            DocsLogger.btInfo("[SYNC] getButtonColorList success")
            self.tableMeta.buttonColors = buttonColors.compactMap({ $0 })
            self.tableModel.update(meta: self.tableMeta, value: self.tableValue, mode: self.mode, holdDataProvider: dataService?.holdDataProvider)
        }
    }

    deinit {
        // wait状态时，将fetchSemaphore置nil或者赋值，会crash
        // fetchSemaphore释放时，必须保证当前信号量值大于等于初始信号量值，否则会crash
        unlockFetch()
    }
}

extension BTViewModel {
    private final class _BizInfo: BTDataBizInfo {
        private let dataService: BTDataService?
        init(dataService: BTDataService?) {
            self.dataService = dataService
        }
        
        var isInVideoConference: Bool { dataService?.isInVideoConference ?? false }
        var hostDocInfo: DocsInfo { dataService?.hostDocInfo ?? DocsInfo(type: .unknownDefaultType, objToken: "") }
        var hostDocUrl: URL? { dataService?.hostDocUrl }
        var hostChatId: String? { dataService?.hostChatId }
        var jsFuncService: SKExecJSFuncService? { dataService?.jsFuncService }
        var holdDataProvider: BTHoldDataProvider? { dataService?.holdDataProvider }
    }
}

//当前指向页的记录
extension BTViewModel {
    // 在后续更新 actionParams 时，要确保 originID 不被替换为空
    func updateActionParams(_ newActionParams: BTActionParamsModel, shouldOverrideOriginID: Bool = false) {
        let originBaseID = actionParams.originBaseID
        let originTableID = actionParams.originTableID
        actionParams = newActionParams

        if shouldOverrideOriginID {
            actionParams.originBaseID = actionParams.data.baseId
            actionParams.originTableID = actionParams.data.tableId
        } else {
            if actionParams.originBaseID.isEmpty {
                actionParams.originBaseID = originBaseID
            }
            if actionParams.originTableID.isEmpty {
                actionParams.originTableID = originTableID
            }
        }
        self.tableModel.update(topTip: newActionParams.data.topTipType)
    }

    func updateCurrentRecordID(_ recordID: String) {
        activeRecordID = recordID
    }
    
    func updateCurrentRecordGroupValue(_ groupValue: String) {
        activeRecordGroupValue = groupValue
    }

    func updateCurrentRecordIndex(_ index: Int) {
        activeRecordIndex = index
    }
    
    func updatecurrentLoadingRecordID(_ recordID: String?) {
        currentLoadingRecordID = recordID
    }

    func nativeUpdateHiddenFields(toDisclosed flag: Bool) {
        tableModel.update(shouldDiscloseHiddenFields: flag)
        tableModel.update(meta: tableMeta, value: tableValue, mode: mode, holdDataProvider: dataService?.holdDataProvider)
    }
    
    func updateProAddSubmitTopTipShowed(_ hasShow: Bool) {
        // 这里需要更新下 meta，前端只触发了 data update，但是这个值存储在 meta 中
        tableMeta.submitTopTipShowed = hasShow
        tableModel.update(submitTopTipShowed: hasShow)
    }
}

// MARK: fetch

extension BTViewModel {
    func initialize(with request: BTGetCardListRequest,
                    _ successBlock: @escaping (Bool) -> Void,
                    _ failedBlock: @escaping (Error?) -> Void) {
        startTrackOpenCardEvent()
        updateMetaThenData(with: request, successBlock, failedBlock)
    }

    // swiftlint:disable cyclomatic_complexity
    func updateMetaThenData(with request: BTGetCardListRequest,
                            _ successBlock: @escaping (Bool) -> Void,
                            _ failedBlock: @escaping (Error?) -> Void) {
        fetchQueue.async { [weak self] in
            guard let self = self else { return }
            self.lockFetch()
            let isInitialization: Bool = request.requestType == .initialize(true) // ture or false 都视为一样
            if isInitialization {
                self.openCardTracker?.trackTimestamp(type: .nativeRequestTableMetaTime)
            }
            self.requestTableMeta { [weak self] (metaResult, error) in
                guard let `self` = self else { return }
                guard var metaResult = metaResult else {
                    DocsLogger.btError("[SYNC] requestTableMeta isInitialization: \(isInitialization) errorMsg: \(error?.localizedDescription ?? "")")
                    if isInitialization, let error = error {
                        self.trackFetchDataFailedEvent(errorMsg: error.localizedDescription, failedType: .metaFailed)
                    }
                    self.unlockFetch()
                    DispatchQueue.main.async { [weak self] in
                        self?.notifyMetaFetchFailed()
                        failedBlock(error)
                    }
                    return
                }
                // 表单打开关联记录: viewType表示当前视图的类型，一直是form，所以需要把viewType手动改一下，和安卓对齐
                if self.mode.isLinkedRecord {
                    metaResult.viewType = "grid"
                }
                if !self.mode.isIndRecord, metaResult.viewType == "form" {
                    self.mode = .form
                }
                if isInitialization {
                    self.openCardTracker?.trackTimestamp(timestamp: metaResult.timestamp, type: .webReceiveTableMetaRequestTime)
                    self.openCardTracker?.trackTimestamp(type: .nativeReceiveTableMetaTime)
                    self.openCardTracker?.trackTimestamp(type: .nativeRequestTableDataTime)
                }
                if self.tableMeta != metaResult {
                    self.tableMeta = metaResult
                    DispatchQueue.main.async { [weak self] in
                        self?.notifyMetaUpdate()
                    }
                }
                if self.mode.isLinkedRecord {
                    self.updateCurrentLinkedRecords(successBlock: successBlock,
                                                    failedBlock: failedBlock,
                                                    isInitialization: isInitialization)
                } else {
                    let finishBlock: (BTTableValue?, Error?) -> Void = { [weak self] (recordsResult, error) in
                        guard let self = self else { return }
                        guard var recordsResult = recordsResult else {
                            DocsLogger.btError("[SYNC] requestTableData isInitialization: \(isInitialization) errorMsg: \(error?.localizedDescription ?? "")")
                            if isInitialization, let error = error {
                                self.trackFetchDataFailedEvent(errorMsg: error.localizedDescription, failedType: .dataFailed)
                            }
                            self.unlockFetch()
                            DispatchQueue.main.async { [weak self] in
                                self?.notifyValueFetchFailed()
                                failedBlock(error)
                            }
                            // bitable 重构后这里的return丢了，这次补回来
                            return
                        }
                        if self.handleEmptyRecordsWhenGetTableData(result: recordsResult,
                                                                   isInitialization: isInitialization,
                                                                   emptyBlock: failedBlock) {
                            return
                        }
                        if isInitialization {
                            self.openCardTracker?.trackTimestamp(timestamp: recordsResult.timestamp, type: .webReceiveTableDataRequestTime)
                            self.openCardTracker?.trackTimestamp(type: .nativeReceiveTableDataTime)
                            
                            let currentRecords = self.tableValue.records
                            
                            if !recordsResult.loaded {
                                if currentRecords.isEmpty {
                                    //初始化数据加载中，需要显示loading
                                    var loadingRecordModel = BTRecordValue()
                                    loadingRecordModel.recordId = BTSpecialRecordID.initLoading.rawValue
                                    loadingRecordModel.dataStatus = .loading
                                    
                                    recordsResult.records = [loadingRecordModel]
                                } else {
                                    recordsResult.records = currentRecords
                                }
                            }
                        } else {
                            //非初始化的更新
                            //update请求触发的更新完成后直接刷新页面，不需要展示loading
                            guard recordsResult.loaded else {
                                self.unlockFetch()
                                DispatchQueue.main.async {
                                    successBlock(false)
                                }
                                return
                            }
                        }
                        DocsLogger.btInfo("updateMetaThenData loaded:\(recordsResult.loaded) count:\(recordsResult.records.count)")
                        self.tableValue = recordsResult
                        self.tableModel.update(meta: self.tableMeta, value: self.tableValue, mode: self.mode, holdDataProvider: dataService?.holdDataProvider)
                        self.unlockFetch()
                        DispatchQueue.main.async { [weak self] in
                            if !isInitialization ||
                                (request.isRetryRequest && recordsResult.loaded) {
                                self?.notifyModelUpdate()
                            }
                            successBlock(recordsResult.loaded)
                        }
                    }
                    self.requestTableData(request: request, finish: finishBlock)
                }
            }
        }
    }

    private func updateOnlyData(with request: BTGetCardListRequest,
                                _ successBlock: @escaping (Bool) -> Void,
                                _ failedBlock: @escaping (Error?) -> Void) {
        guard tableMeta.fields.count > 0 else { // 没有拉过 meta 的话先去拉 meta
            updateMetaThenData(with: request, successBlock, failedBlock)
            return
        }
        fetchQueue.async { [weak self] in
            guard let self = self else { return }
            self.lockFetch()
            if case .link = self.mode {
                self.updateCurrentLinkedRecords(successBlock: successBlock, failedBlock: failedBlock)
            } else {
                self.requestTableData(request: request, finish: { [weak self] (recordsResult, error) in
                    guard let self = self else { return }
                    guard let recordsResult = recordsResult else {
                        DocsLogger.btError("[SYNC] requestTableData errorMsg: \(error?.localizedDescription ?? "")")
                        self.unlockFetch()
                        DispatchQueue.main.async { [weak self] in
                            self?.notifyValueFetchFailed()
                            failedBlock(error)
                        }
                        return
                    }
                    if self.handleEmptyRecordsWhenGetTableData(result: recordsResult,
                                                               emptyBlock: failedBlock) {
                        return
                    }
                    
                    guard recordsResult.loaded else {
                        self.unlockFetch()
                        DispatchQueue.main.async {
                            successBlock(false)
                        }
                        return
                    }
                    
                    self.tableValue = recordsResult
                    self.tableModel.update(meta: self.tableMeta, value: self.tableValue, mode: self.mode, holdDataProvider: dataService?.holdDataProvider)
                    self.unlockFetch()
                    DispatchQueue.main.async { [weak self] in
                        self?.notifyModelUpdate()
                        successBlock(true)
                    }
                })
            }
        }
    }

    private func updateCurrentLinkedRecords(successBlock: @escaping (Bool) -> Void,
                                            failedBlock: @escaping (Error?) -> Void,
                                            isInitialization: Bool = false) {
        let ids: [String]
        if isInitialization {
            if recordIDs.count >= 11 {
                if let curIndex = recordIDs.firstIndex(of: activeRecordID) {
                    let startIndex = max(recordIDs.startIndex, curIndex - 5)
                    let endIndex = min(curIndex + 5, recordIDs.endIndex - 1)
                    ids = [String](recordIDs[startIndex...endIndex])
                } else {
                    ids = [String](recordIDs[0...11])
                }
            } else {
                ids = recordIDs
            }
        } else {
            ids = tableModel.records.map(\.recordID)
        }
        requestRecordsData(ids: ids) { [weak self] (recordsResult, error) in
            guard let self = self else { return }
            guard let recordsResult = recordsResult else {
                self.unlockFetch()
                DispatchQueue.main.async { [weak self] in
                    self?.notifyValueFetchFailed()
                    failedBlock(error)
                }
                return
            }
            if self.handleEmptyRecordsWhenGetTableData(result: recordsResult,
                                                       isInitialization: isInitialization,
                                                       emptyBlock: failedBlock) {
                return
            }
            self.tableValue = recordsResult
            self.tableValue.total = self.recordIDs.count
            self.tableModel.update(meta: self.tableMeta, value: self.tableValue, mode: self.mode, holdDataProvider: dataService?.holdDataProvider)
            self.unlockFetch()
            DispatchQueue.main.async { [weak self] in
                if !isInitialization {
                    self?.notifyModelUpdate()
                }
                successBlock(recordsResult.loaded)
            }
        }
    }

    private func fetchLeftRecords(with request: BTGetCardListRequest,
                                  _ successBlock: @escaping (Bool) -> Void,
                                  _ failedBlock: @escaping (Error?) -> Void) {
        fetchQueue.async { [weak self] in
            guard let self = self else { return }
            self.lockFetch()
            if case .link = self.mode {
                let ids: [String]
                if let firstID = self.tableModel.records.first?.recordID,
                   let firstIndex = self.recordIDs.firstIndex(of: firstID) {
                    let startIndex = max(self.recordIDs.startIndex, firstIndex - 5)
                    let endIndex = firstIndex
                    ids = [String](self.recordIDs[startIndex ... endIndex])
                } else if self.recordIDs.count >= 11 {
                    ids = [String](self.recordIDs[0 ... 11])
                } else {
                    ids = self.recordIDs
                }
                self.requestRecordsData(ids: ids) { [weak self] recordsResult, error in
                    self?.onReceiveData(with: request, isLeft: true, recordsResult: recordsResult, error: error, successBlock, failedBlock)
                }
            } else {
                self.requestTableData(request: request) { [weak self] recordsResult, error in
                    self?.onReceiveData(with: request, isLeft: true, recordsResult: recordsResult, error: error, successBlock, failedBlock)
                }
            }
        }
    }
    
    private func onReceiveData(with request: BTGetCardListRequest,
                               isLeft: Bool,
                               recordsResult: BTTableValue?,
                               error: Error?,
                               _ successBlock: @escaping (Bool) -> Void,
                               _ failedBlock: @escaping (Error?) -> Void) {
        guard var recordsResult = recordsResult else {
            self.unlockFetch()
            DispatchQueue.main.async { [weak self] in
                self?.notifyValueFetchFailed()
                failedBlock(error)
            }
            return
        }

        var currentRecords = self.tableValue.records
        if !recordsResult.loaded {
            // 数据加载中。。。
            DocsLogger.btInfo("[SYNC] did fetch \(isLeft ? "left" : "right") records loading")
            if !request.isRetryRequest {
                // 初始化数据加载中，需要显示loading
                var loadingRecordModel = BTRecordValue()
                loadingRecordModel.dataStatus = .loading
                if isLeft {
                    loadingRecordModel.recordId = BTSpecialRecordID.leftLoading.rawValue
                    recordsResult.records = [loadingRecordModel] + currentRecords
                } else {
                    loadingRecordModel.recordId = BTSpecialRecordID.rightLoading.rawValue
                    recordsResult.records = currentRecords + [loadingRecordModel]
                }
            } else {
                // retry的请求不需要再加loading
                recordsResult.records = currentRecords
            }
        } else {
            // 数据加载完成，移除loading，拼接数据
            if !currentRecords.isEmpty, .loading == currentRecords.first?.dataStatus {
                // 数据loaded，移除loading
                currentRecords.removeFirst()
            }
            let firstMatchRecordIndex: Int?
            if isLeft {
                firstMatchRecordIndex = currentRecords.firstIndex(where: { $0.identify == (recordsResult.records.last?.identify ?? "") })
            } else {
                firstMatchRecordIndex = recordsResult.records.firstIndex(where: { $0.identify == (currentRecords.last?.identify ?? "") })
            }
            // 匹配请求回来的数据的最后一张卡片在当前列表中匹配的卡片index，有匹配的则拼接，没有则不处理
            // 还需要比对groupID，同一张卡片可能在列表中出现多次
            if let firstMatchRecordIndex = firstMatchRecordIndex,
               firstMatchRecordIndex < recordsResult.records.count {
                if isLeft {
                    recordsResult.records.removeLast(firstMatchRecordIndex + 1)
                    recordsResult.records += currentRecords
                } else {
                    //向右请求会多请求两张，因为前端对于负的offset不好处理
                    recordsResult.records.removeFirst(firstMatchRecordIndex + 1)
                    recordsResult.records = currentRecords + recordsResult.records
                }
            } else {
                // 数据不匹配，避免数据错乱，丢弃请求的数据不处理，保持原有数据，仅去除loading
                recordsResult.records = currentRecords
                DocsLogger.btError("[SYNC] did fetch \(isLeft ? "left" : "right") records not match")
            }
        }

        self.tableValue = recordsResult
        if self.mode.isLinkedRecord {
            self.tableValue.total = self.recordIDs.count
        }
        self.tableModel.update(meta: self.tableMeta, value: self.tableValue, mode: self.mode, holdDataProvider: dataService?.holdDataProvider)
        DocsLogger.btInfo("[SYNC] did fetch \(isLeft ? "left" : "right") records, now current index: \(self.currentRecordIndex)")
        self.unlockFetch()
        DispatchQueue.main.async { [weak self] in
            self?.notifyModelUpdate()
            successBlock(recordsResult.loaded)
        }
    }

    private func fetchRightRecords(with request: BTGetCardListRequest,
                                   _ successBlock: @escaping (Bool) -> Void,
                                   _ failedBlock: @escaping (Error?) -> Void) {
        fetchQueue.async { [weak self] in
            guard let self = self else { return }
            self.lockFetch()
            if case .link = self.mode {
                let ids: [String]
                let recordsCount = self.tableModel.records.count

                guard recordsCount > 0 else {
                    DocsLogger.btError("[SYNC] did fetch right records is empty")
                    self.onReceiveData(with: request, isLeft: false, recordsResult: nil, error: nil, successBlock, failedBlock)
                    return
                }
                // 跟普通卡片的请求保持一致，从最后一张开始请求
                let lastID = self.tableModel.records[max(recordsCount - 1, 0)].recordID
                if let lastIndex = self.recordIDs.firstIndex(of: lastID) {
                    let startIndex = lastIndex
                    let endIndex = min(lastIndex + 5, self.recordIDs.endIndex - 1)
                    ids = [String](self.recordIDs[startIndex ... endIndex])
                } else if self.recordIDs.count >= 11 {
                    ids = [String](self.recordIDs[0 ... 11])
                } else {
                    ids = self.recordIDs
                }
                self.requestRecordsData(ids: ids) { [weak self] recordsResult, error in
                    self?.onReceiveData(with: request, isLeft: false, recordsResult: recordsResult, error: error, successBlock, failedBlock)
                }
            } else {
                self.requestTableData(request: request) { [weak self] recordsResult, error in
                    self?.onReceiveData(with: request, isLeft: false, recordsResult: recordsResult, error: error, successBlock, failedBlock)
                }
            }
        }
    }

    private func fetchFilteredOnlyOneRecord(with request: BTGetCardListRequest,
                                            _ successBlock: @escaping (Bool) -> Void,
                                            _ failedBlock: @escaping (Error?) -> Void) {
        fetchQueue.async { [weak self] in
            guard let self = self else { return }
            self.lockFetch()
            self.requestTableData(request: request) { [weak self] (recordsResult, error) in
                guard let self = self else { return }
                guard let recordsResult = recordsResult else {
                    self.unlockFetch()
                    DispatchQueue.main.async { [weak self] in
                        self?.notifyValueFetchFailed()
                        failedBlock(error)
                    }
                    return
                }
                
                if self.handleEmptyRecordsWhenGetTableData(result: recordsResult,
                                                           emptyBlock: failedBlock) {
                    return
                }
                
                guard recordsResult.loaded else {
                    self.unlockFetch()
                    DispatchQueue.main.async {
                        successBlock(false)
                    }
                    return
                }
                
                self.tableValue = recordsResult
                self.tableModel.update(meta: self.tableMeta, value: self.tableValue, mode: self.mode, holdDataProvider: dataService?.holdDataProvider)
                self.tableModel.update(isFiltered: true)
                self.unlockFetch()
                DispatchQueue.main.async { [weak self] in
                    self?.notifyModelUpdate()
                    successBlock(recordsResult.loaded)
                }
            }
        }
    }

    private func requestTableMeta(_ finish: @escaping (BTTableMeta?, Error?) -> Void) {
        let fieldIds = [stageFieldId]
        dataService?.fetchTableMeta(baseID: actionParams.data.baseId,
                                    tableID: actionParams.data.tableId,
                                    viewID: actionParams.data.viewId,
                                    viewMode: mode,
                                    fieldIds: fieldIds) { (result, error) in
            if let error = error {
                DocsLogger.btError("[SYNC] js bridge get table meta failed: \(error)")
            }
            finish(result, error)
        }
    }

    private func requestTableData(request: BTGetCardListRequest, finish: @escaping (BTTableValue?, Error?) -> Void) {
        let baseData = BTBaseData(baseId: request.requestModel.baseId,
                                  tableId: request.requestModel.tableId,
                                  viewId: request.requestModel.viewId)
        let fieldIds = [stageFieldId]
        let args = BTJSFetchCardArgs(baseData: baseData,
                                     recordID: request.requestModel.recordIds?.first ?? "",
                                     groupValue: request.requestModel.groupValue,
                                     startFromLeft: request.requestModel.startFromLeft,
                                     fetchCount: request.requestModel.fetchCount,
                                     requestingForInvisibleRecords: request.requestModel.requestingForInvisibleRecords,
                                     viewMode: UserScopeNoChangeFG.ZJ.btCardReform ? .card : mode,
                                     fieldIds: fieldIds)
        
        dataService?.fetchCardList(args: args) { [weak self] (result, error) in
            guard let self = self else { return }
            if let error = error {
                DocsLogger.btError("[SYNC] js bridge get table data failed: \(error)")
            }
            finish(result, error)
            
            if UserScopeNoChangeFG.ZJ.btCardReform {
                self.getStageItemViewData(recordIds: [args.recordID],
                                          tableId: baseData.tableId,
                                          viewId: baseData.viewId,
                                          offset: args.startFromLeft,
                                          length: args.fetchCount)
            }
        }
    }

    func getFormBannerURL(viewId: String, tableId: String, responseHandler: @escaping (String?) -> Void) {
        if let service = self.dataService {
            service.getViewMeta(viewId: viewId, tableId: tableId, extra: ["bannerImgSpec":1280]) { res in
                switch res {
                case .success(let viewMeta):
                    // 复用CodableUtility内的日志，不打重复日志了
                    let formBannerInfoUrl = try? CodableUtility.decode(BTFormViewMetaProperty.self, withJSONString: viewMeta.property).formBannerInfo?.url
                    responseHandler(formBannerInfoUrl)
                    // 会打出 nil true false 三种
                    DocsLogger.info("formBannerInfoUrl.isEmpty: \(formBannerInfoUrl?.isEmpty)")
                case .failure(let err):
                    DocsLogger.error("getViewMeta error", error: err)
                    responseHandler(nil)
                }
            }
        } else {
            DocsLogger.error("service is nil")
            responseHandler(nil)
        }
    }

    private func requestRecordsData(ids: [String], _ finish: @escaping (BTTableValue?, Error?) -> Void) {
        dataService?.fetchRecords(baseID: actionParams.data.baseId,
                                  tableID: actionParams.data.tableId,
                                  recordIDs: ids,
                                  fieldIDs: nil) { (result, error) in
            if let error = error {
                DocsLogger.btError("[SYNC] js bridge get table data failed: \(error)")
            }
            finish(result, error)
            
            if UserScopeNoChangeFG.ZJ.btCardReform {
                self.getStageItemViewData(recordIds: ids,
                                          tableId: self.actionParams.data.tableId)
            }
        }
    }
    
    private func getStageItemViewData(recordIds: [String],
                                      tableId: String,
                                      viewId: String? = nil,
                                      offset: Int? = nil,
                                      length: Int? = nil) {
        var payload: [String: Any] = ["tableId": tableId,
                                      "recordIds": recordIds]
        
        if let viewId = viewId {
            payload["viewId"] = viewId
        }
        
        if let offset = offset {
            payload["offset"] = offset
        }
        
        if let length = length {
            payload["length"] = length
        }
        dataService?.getItemViewData(type: .stage,
                                     tableId: tableId,
                                     payload: payload,
                                     resultHandler: { result in
            switch result {
            case .success(let data):
                guard let dicData = data as? [String: Any],
                      let resultData = dicData["data"] as? [String: Any] else {
                    DocsLogger.btError("getItemViewData decode error data: \(String(describing: data))")
                    return
                }
                
                do {
                    let stageData = try CodableUtility.decode(BTItemViewDatas.self, withJSONObject: resultData)
                    var recordUpdated = false
                    stageData.stageItemViewData.forEach { data in
                        if let recordIndex = self.tableModel.records.firstIndex(where: { $0.recordID == data.recordId }) {
                            var record = self.tableModel.records[recordIndex]
                            data.stageDatas?.forEach { stageData in
                                var requiredFields: [String: [String]] = [:]
                                var fields = record.wrappedFields
                                if !UserScopeNoChangeFG.ZJ.btItemViewOriginFieldsFixDisable {
                                    fields = record.originalFields
                                }
                                if let fieldIndex = fields.firstIndex(where: { $0.fieldID == stageData.stageFieldId }) {
                                    // 阶段字段model
                                    var field = fields[fieldIndex]
                                    // 修改FieldValue里面的fieldPermission信息
                                    var stageConvert: [String: Bool] = [:]
                                    stageData.optionDatas.forEach { optionData in
                                        stageConvert[optionData.optionId] = optionData.stageConvert
                                        requiredFields[optionData.optionId] = optionData.requiredFields
                                    }
                                    let existStageConvert = field.fieldPermission?.stageConvert ?? [:]
                                    if stageConvert != existStageConvert {
                                        field.update(stageConvert: stageConvert)
                                        record.update(field, for: fieldIndex)
                                        recordUpdated = true
                                    }
                                }
                                
                                // 修改RecordModel里面的isRequired信息
                                let existRequiredFields = record.stageRequiredFields[stageData.stageFieldId] ?? [:]
                                if requiredFields != existRequiredFields {
                                    record.update(stageFieldId: stageData.stageFieldId, requiredFields: requiredFields)
                                    recordUpdated = true
                                }
                            }
                            if recordUpdated {
                                self.tableModel.updateRecord(record, for: recordIndex)
                            }
                        }
                    }
                    if recordUpdated {
                        self.notifyModelUpdate()
                    }
                } catch {
                    DocsLogger.btError("getItemViewData decode error data error:\(DocsLogger.btError("getItemViewData decode error data: \(String(describing: data))"))")
                }
            case .failure(let error):
                DocsLogger.error("getItemViewData failed: \(error)")
            }
        })
    }

    private func lockFetch() {
        _ = fetchSemaphore.wait(timeout: .distantFuture)
    }

    private func unlockFetch() {
        fetchSemaphore.signal()
    }
    
    /// 处理空数据，当获取卡片数据的时候
    /// - Parameters:
    ///   - result: 卡片数据
    ///   - emptyBlock: 空数据时的会调处理
    /// - Returns: 是否需要处理
    func handleEmptyRecordsWhenGetTableData(result: BTTableValue,
                                            isInitialization: Bool = false,
                                            emptyBlock: @escaping (Error?) -> Void) -> Bool {
        guard result.records.isEmpty, result.loaded else {
            return false
        }
        self.trackFetchDataFailedEvent(errorMsg: "requestTableData records is Empty in mode: \(self.mode.description)",
                                       failedType: .recordsEmpty)
        /// 如果是表单就不进行处理。
        guard self.mode != .form else {
            return false
        }
        let error = BTGetTableDataError.recordsEmpty
        self.unlockFetch()
        DocsLogger.error("[SYNC] requestTableData records is Empty")
        DispatchQueue.main.async { [weak self] in
            if isInitialization {
                self?.listener?.didRequestingValueErrorWhenOpenCard(error)
            }
            emptyBlock(error)
        }
        return true
    }
}

extension BTViewModel {

    func updateForm() {
        if mode != .form {
            // 目前服务于更新表单视图封面，其他视图复用请进行兼容
            DocsLogger.info("recieve updateForm and not form cancel update")
            return
        }
        fetchDataManager.clearWaitingAndDisposingRequests()

        constructCardRequest(.onlyData) { [weak self] value in
        }
    }
    // swiftlint:disable cyclomatic_complexity
    func respond(to newAction: BTCardActionTask) {
        DocsLogger.btInfo("[SYNC] \(actionParams.data.tableId) viewModel responds to \(newAction.actionParams.action.rawValue)")
        guard isDismissing == false else {
            DocsLogger.info("[SYNC] 当前卡片正在退出, 不对参数做处理")
            newAction.completedBlock()
            return
        }
        switch newAction.actionParams.action {
        case .bitableIsReady:
            constructCardRequest(.bitableReady, completionBlock: { [weak self] success in
                if success {
                    self?.bitableIsReady = true
                }
                newAction.completedBlock()
            })
        case .showCard, .showManualSubmitCard:
            guard respondShowCard(to: newAction) else {
                return
            }
        case .tableRecordsDataLoaded:
            kickoff()
            newAction.completedBlock()
        case .updateRecord:
            updateActionParams(newAction.actionParams, shouldOverrideOriginID: true)
            // 当前卡片分组ID可能发生变化，需要更新分组ID
            updateCurrentRecordGroupValue(newAction.actionParams.data.groupValue)
            fetchDataManager.clearWaitingAndDisposingRequests()
            constructCardRequest(.onlyData, completionBlock: { _ in
                newAction.completedBlock()
            })
        case .updateField:
            fetchDataManager.clearWaitingAndDisposingRequests()
            constructCardRequest(.update, completionBlock: { _ in
                newAction.completedBlock()
            })
        case .closeCard, .deleteRecord:
            notifyMustCloseCard(newAction: newAction)
        case .recordFiltered:
            fetchDataManager.clearWaitingAndDisposingRequests()
            constructCardRequest(.filteredOnlyOne, completionBlock: { _ in
                newAction.completedBlock()
            })
        case .linkTableChanged:
            fetchDataManager.clearWaitingAndDisposingRequests()
            constructCardRequest(.update, completionBlock: { _ in
                newAction.completedBlock()
            })
        case .formFieldsValidate:
            dealValidateFields(action: newAction, isInStage: false)
            newAction.completedBlock()
        case .fieldsValidate:
            if newAction.actionParams.data.stackViewId == tableMeta.stackViewId {
                dealValidateFields(action: newAction, isInStage: true)
            }
            newAction.completedBlock()
        case .switchCard:
            updateActionParams(newAction.actionParams)
            updateCurrentRecordID(newAction.actionParams.data.recordId)
            updateCurrentRecordGroupValue(newAction.actionParams.data.groupValue)
            let scrollCardBlock: (Bool) -> Void = { [weak self] animated in
                guard let self = self else { return }
                let topFieldId = newAction.actionParams.data.topFieldId
                // 滚动到指定卡片
                self.notifyScrollToCard(animated: animated, completion: {
                    if !topFieldId.isEmpty {
                        self.notifyScrollToCardField(fieldID: topFieldId)
                    }
                    newAction.completedBlock()
                })
            }

            let contains = tableModel.records.contains { $0.recordID == newAction.actionParams.data.recordId }
            if !contains {
                fetchDataManager.clearWaitingAndDisposingRequests()
                constructCardRequest(.update, completionBlock: { success in
                    newAction.completedBlock()
                    guard success else { return }
                    scrollCardBlock(false)
                })
                return
            }

            scrollCardBlock(true)
        case .scrollCard:
            //vcFollow 滚动到卡片指定field
            let topFieldId = newAction.actionParams.data.topFieldId
            self.notifyScrollToCardField(fieldID: topFieldId)
            newAction.completedBlock()
        case .submitResult:
            break
        case .showLinkCard:
            break
        case .setCardHidden:
            notifySetCardHidden(newAction: newAction, isHidden: true)
            break
        case .setCardVisible:
            notifySetCardHidden(newAction: newAction, isHidden: false)
            break
        case .showIndRecord:
            break
        case .showAddRecord:
            break
        case .addRecordResult:
            break
        }
    }
    
    private func respondShowCard(to newAction: BTCardActionTask) -> Bool {
        if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            if newAction.actionParams.action == .showCard {
                self.mode = .card
                self.preMockRecordId = newAction.actionParams.data.preMockRecordId
            } else if newAction.actionParams.action == .showManualSubmitCard {
                self.mode = .submit
                self.preMockRecordId = nil
            }
        }
        updateActionParams(newAction.actionParams, shouldOverrideOriginID: true)
        updateCurrentRecordID(newAction.actionParams.data.recordId)
        updateCurrentRecordGroupValue(newAction.actionParams.data.groupValue)
        if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            tableModel.update(meta: tableMeta, value: tableValue, mode: mode, holdDataProvider: dataService?.holdDataProvider)
            tableModel.update(canAddRecord: newAction.actionParams.data.preMockRecordId.isEmpty == false)
        }
        // 第一次进入表单/提交表单后，需要滚动到顶部
        if mode.isForm, !tableModel.records.isEmpty {
            notifyScrollToField(at: IndexPath(row: 0, section: 0), scrollPosition: [.bottom, .centeredHorizontally])
        }
        // showCard 和 showManualSubmitCard 第一次事件处理不会走这个方法，直接走了 kickOff
        // 如果走进来了说明是前端重复发了事件，我们按照 update 的流程走就行，但是需要更新 recordID
        fetchDataManager.clearWaitingAndDisposingRequests()
        
        let scrollCardBlock: (Bool) -> Void = { [weak self] animated in
            guard let self = self else { return }
            let fieldId = newAction.actionParams.data.fieldId
            // 滚动到指定卡片
            self.notifyScrollToCard(animated: animated, completion: {
                if !UserScopeNoChangeFG.QYK.btBaseSwitchRecordFixDisable {
                    guard let vc = self.listener as? BTController else { return }
                    if !fieldId.isEmpty && fieldId != vc.currentCard?.recordModel.primaryFieldID {
                        self.notifyScrollToCardField(fieldID: fieldId)
                    }
                } else {
                    if !fieldId.isEmpty {
                        self.notifyScrollToCardField(fieldID: fieldId)
                    }
                    newAction.completedBlock()
                }
            })
        }

        let contains = tableModel.records.contains { $0.recordID == newAction.actionParams.data.recordId }
        if !contains {
            constructCardRequest(.update, completionBlock: { success in
                newAction.completedBlock()
                guard success else { return }
                if !UserScopeNoChangeFG.QYK.btBaseSwitchRecordFixDisable {
                    scrollCardBlock(false)
                }
            })
            return false
        }
        scrollCardBlock(false)
        if !UserScopeNoChangeFG.QYK.btBaseSwitchRecordFixDisable {
            newAction.completedBlock()
        }
        if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            notifyModelUpdate()
        }
        return true
    }
    
    func dealValidateFields(action: BTCardActionTask, isInStage: Bool) {
        if !tableModel.records.isEmpty {
            let errorFields = action.actionParams.data.fields
            DocsLogger.btInfo("[SYNC] unfilled mandatory field count: \(errorFields.count)")
            errorFields.forEach { key, submitError in
                if isInStage {
                    tableModel.updateAndReset(errorMsg: submitError.errorMsg, forFieldID: key)
                } else {
                    tableModel.update(errorMsg: submitError.errorMsg, forFieldID: key)
                }
            }
            if let fieldId = errorFields.first?.key {
                notifyScrollToField(with: fieldId, scrollPosition: [.top, .centeredHorizontally])
            }
            DispatchQueue.main.async { [weak self] in
                self?.notifyModelUpdate()
            }
        }
    }

    func jsModifyField(withID fieldID: String, editType: BTFieldEditType? = nil, value: Any?) {
        guard let currentEditingRecord = tableModel.records.first(where: { $0.recordID == activeRecordID }),
              currentEditingRecord.editable,
              let currentEditingField = currentEditingRecord.wrappedFields.first(where: { $0.fieldID == fieldID }),
              currentEditingField.editable
        else {
            DocsLogger.btInfo("[SYNC] has no \(activeRecordID) \(fieldID) edit permission，not allowed to submit changeset")
            return
        }
        let args = BTSaveFieldArgs(originBaseID: actionParams.originBaseID,
                                   originTableID: actionParams.originTableID,
                                   currentBaseID: actionParams.data.baseId,
                                   currentTableID: actionParams.data.tableId,
                                   currentViewID: actionParams.data.viewId,
                                   currentRecordID: activeRecordID,
                                   currentFieldID: fieldID,
                                   callback: actionParams.callback,
                                   editType: editType,
                                   value: value)
        dataService?.saveField(args: args)
    }
    
    func quickAddViewClick(fieldID: String) {
        guard let currentEditingRecord = tableModel.records.first(where: { $0.recordID == activeRecordID }),
              currentEditingRecord.editable,
              let currentEditingField = currentEditingRecord.wrappedFields.first(where: { $0.fieldID == fieldID }),
              currentEditingField.editable
        else {
            DocsLogger.btInfo("[SYNC] has no \(activeRecordID) \(fieldID) edit permission，not allowed to submit changeset")
            return
        }
        let args = BTSaveFieldArgs(originBaseID: actionParams.originBaseID,
                                   originTableID: actionParams.originTableID,
                                   currentBaseID: actionParams.data.baseId,
                                   currentTableID: actionParams.data.tableId,
                                   currentViewID: actionParams.data.viewId,
                                   currentRecordID: activeRecordID,
                                   currentFieldID: fieldID,
                                   callback: actionParams.callback)
        dataService?.quickAddViewClick(args: args)
    }

    func jsExecuteCommands(command: BTCommands,
                           field: BTFieldCellProtocol?,
                           property: Any?,
                           extraParams: Any?,
                           resultHandler: @escaping (BTExecuteFailReson?, Error?) -> Void) {
        guard let field = field else { return }

        let fieldInfo = BTJSFieldInfoArgs(index: nil,
                                          fieldID: field.fieldID,
                                          fieldName: field.fieldModel.name,
                                          compositeType: field.fieldModel.compositeType,
                                          fieldDescription: field.fieldModel.description,
                                          allowEditModes: field.fieldModel.allowedEditModes)
        let args = BTExecuteCommandArgs(command: command,
                                        tableID: actionParams.data.tableId,
                                        viewID: actionParams.data.viewId,
                                        fieldInfo: fieldInfo,
                                        property: property,
                                        checkConfirmValue: nil,
                                        extraParams: extraParams)

        dataService?.executeCommands(args: args, resultHandler: resultHandler)
    }

    func jsGetPermission(entity: String,
                         operation: OperationType,
                         recordID: String?,
                         fieldIDs: [String]?,
                         resultHandler: @escaping (Any?, Error?) -> Void) {
        let args = BTGetPermissionDataArgs(entity: entity,
                                          tableID: actionParams.data.tableId,
                                          viewID: actionParams.data.viewId,
                                          recordID: recordID,
                                          fieldIDs: fieldIDs,
                                          operation: [operation])
        dataService?.getPermissionData(args: args, resultHandler: resultHandler)
    }

    func jsGetBitableCommonData(type: BTEventType,
                                fieldID: String,
                                extraParams: [String: Any]?,
                                resultHandler: @escaping (Any?, Error?) -> Void) {
        let args = BTGetBitableCommonDataArgs(type: type,
                                              tableID: actionParams.data.tableId,
                                              viewID: actionParams.data.viewId,
                                              fieldID: fieldID,
                                              extraParams: extraParams)
        dataService?.getBitableCommonData(args: args, resultHandler: resultHandler)
    }

    func jsCreateAndLinkNewRecord(sourceLocation: BTFieldLocation, targetLocation: BTFieldLocation, value: Any?, resultHandler: ((Result<Any?, Error>) -> Void)? = nil) {
        let args = BTCreateAndLinkRecordArgs(originBaseID: actionParams.originBaseID,
                                             originTableID: actionParams.originTableID,
                                             callback: actionParams.callback,
                                             sourceLocation: sourceLocation,
                                             targetLocation: targetLocation,
                                             value: value)
        dataService?.createAndLinkRecord(args: args, resultHandler: resultHandler)
    }

    func jsUpdateHiddenFields(toDisclosed flag: Bool) {
        let args = BTHiddenFieldsDisclosureArgs(originBaseID: actionParams.originBaseID,
                                                originTableID: actionParams.originTableID,
                                                callback: actionParams.callback,
                                                currentBaseID: actionParams.data.baseId,
                                                currentTableID: actionParams.data.tableId,
                                                toDisclosed: flag)
        dataService?.toggleHiddenFieldsDisclosure(args: args)
    }

    func jsDeleteRecord(recordID: String) {
        let args = BTDeleteRecordArgs(originBaseID: actionParams.originBaseID,
                                      originTableID: actionParams.originTableID,
                                      callback: actionParams.callback,
                                      currentBaseID: actionParams.data.baseId,
                                      currentTableID: actionParams.data.tableId,
                                      currentViewID: actionParams.data.viewId,
                                      recordID: recordID)
        dataService?.deleteRecord(args: args)
    }

    func jsAsyncRequest(router: BTAsyncRequestRouter,
                        data: [String: Any]?,
                        overTimeInterval: Double?,
                        responseHandler: @escaping(Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                        resultHandler: ((Result<Any?, Error>) -> Void)?) {
        var params: [String: Any] = ["router": router.rawValue,
                                     "tableId": actionParams.data.tableId]

        if var data = data {
            data["tableId"] = actionParams.data.tableId
            params["data"] = data
        }
        dataService?.asyncJsRequest(biz: .card,
                                    funcName: .asyncJsRequest,
                                    baseId: actionParams.data.baseId,
                                    tableId: actionParams.data.tableId,
                                    params: params,
                                    overTimeInterval: overTimeInterval,
                                    responseHandler: responseHandler,
                                    resultHandler: { result in
            resultHandler?(result)
        })
    }
}


// MARK: listener methods
extension BTViewModel {

    func notifyTableInit() {
        listener?.didLoadInitial(model: tableModel)
    }

    func notifyModelUpdate() {
        listener?.didUpdateModel(model: tableModel)
    }

    func notifyMetaUpdate() {
        listener?.didUpdateMeta(meta: tableMeta)
    }

    func notifyScrollToField(at indexPath: IndexPath, scrollPosition: UICollectionView.ScrollPosition) {
        listener?.currentCardScrollToField(at: indexPath, scrollPosition: scrollPosition)
    }
    
    func notifyScrollToField(with fieldId: String, scrollPosition: UICollectionView.ScrollPosition) {
        listener?.currentCardScrollToField(with: fieldId, scrollPosition: scrollPosition)
    }

    func notifyScrollToCard(animated: Bool = true, completion: (() -> Void)? = nil) {
        listener?.scrollToDesignatedCard(animated: animated, completion: completion)
    }

    func notifyScrollToCardField(fieldID: String) {
        listener?.notifyScrollToCardField(fieldID: fieldID)
    }

    func notifyMustCloseCard(newAction: BTCardActionTask) {
        listener?.jsRequestCloseCard(newAction: newAction)
    }

    func notifyMetaFetchFailed() {
        listener?.didFailRequestingMeta()
    }

    func notifyValueFetchFailed() {
        listener?.didFailRequestingValue()
    }
    
    func notifySetCardHidden(newAction: BTCardActionTask, isHidden: Bool) {
        listener?.jsRequestCardHidden(newAction: newAction, isHidden: isHidden)
    }

     /// 当前卡片打开的前提下，前端再次打开卡片，触发数据更新后需要通知进行滚动，且通知卡片打开。
    func notifyRefreshDataByShowCard() {
        guard mode != .form, self.hostDocsInfo?.isInVideoConference ?? false || currentCardPresentMode == .card else {
            DocsLogger.btError("[Sync] notifyRefreshDataByShowCard invoke not inVC")
            return
        }
        listener?.notifyRefreshDataByShowCard()
    }
}

// MARK: fetch data
extension BTViewModel: BTFetchDataDelegate {
    ///构建请求model
    func constructCardRequest(_ type: BTCardFetchType,
                              overTimeInterval: Double = 10,
                              completionBlock: ((Bool) -> Void)? = nil) {
        
        DocsLogger.btInfo("[BTViewModel] constructCardRequest requestType: \(type)")
            let unfilteredRecords = self.unfilteredRecords
            let firstFetchingRecordLeftOffset = unfilteredRecords.isEmpty ? -1 : currentRecordIndex

            let currentUnfilteredRecordsCount = unfilteredRecords.count
            var requestingForInvisibleRecords = type == .filteredOnlyOne
            var groupValue = activeRecordGroupValue
            if case let .initialize(isReady) = type {
              groupValue = actionParams.data.groupValue
              requestingForInvisibleRecords = requestingForInvisibleRecords || !isReady
            }

            let requestModel = BTGetCardListModel(baseId: actionParams.data.baseId,
                               tableId: actionParams.data.tableId,
                               viewId: actionParams.data.viewId,
                               startFromLeft: type.offset(fromCurrentIndex: firstFetchingRecordLeftOffset, currentCount: currentUnfilteredRecordsCount),
                               fetchCount: type.preloadSize(currentCount: currentUnfilteredRecordsCount),
                               recordIds: [currentRecordID],
                               groupValue: groupValue,
                               requestingForInvisibleRecords: requestingForInvisibleRecords)

        let request = BTGetCardListRequest(requestId: String(Date().timeIntervalSince1970),
                                           requestType: type,
                                           requestStatus: .start,
                                           requestModel: requestModel,
                                           overTimeInterval: overTimeInterval,
                                           completionBlock: completionBlock)
            fetchDataManager.disposeRequest(request: request)
    }
    
    ///执行请求
    func executeRequest(request: BTGetCardListRequest,
                        isRetry: Bool = false) {
        fetchRecords(request) { [weak self] loaded in
            guard let self = self else { return }
            DocsLogger.btInfo("[BTViewModel] executeRequest success requestType: \(request.requestType)")
            self.handleRequestStatusChange(request: request, status: loaded ? .success : .waiting, result: nil)
            self.fetchDataManager.handleNextRequest()
        } failedBlock: { [weak self] _ in
            DocsLogger.btError("[BTViewModel] executeRequest failed requestType: \(request.requestType)")
            self?.handleRequestStatusChange(request: request, status: .failed, result: nil)
            self?.fetchDataManager.handleNextRequest()
        }
    }
    
    ///处理前端dataloaded信号
    func handleDataLoaded(router: BTAsyncRequestRouter) {
        //收到前端dataLoade信号重试等待队列的所有请求
        DocsLogger.btInfo("[BTViewModel] [EmitEvent] handle dataLoaded mode:\(mode) router:\(router) waitingRequest:\(fetchDataManager.cardListRequestWaitingQueue.count)")
        
        switch router {
        case .getCardList:
            //普通卡片相关的loaded信号
            guard mode == .card || mode.isIndRecord else {
                return
            }
        case .getRecordsData:
            //关联卡片相关的loaded信号
            guard mode.isLinkedRecord else {
                return
            }
        default:
            return
        }
        
        fetchDataManager.cardListRequestWaitingQueue.forEach { request in
            fetchDataManager.executeRequest(request: request, isRetry: true)
        }
    }
    
    ///处理请求状态变化
    func handleRequestStatusChange(request: BTGetCardListRequest, status: BTGetCardListRequestStatus, result: BTTableValue?) {
        var currentRequest = request
        var recordStatus: BTRecordValueStatus = .success
        
        switch status {
        case .waiting:
            recordStatus = .loading
            //数据loading中，放入等待队列，开启请求超时计时
            currentRequest.requestStatus = .waiting
            currentRequest.isRetryRequest = true
            if case .initialize(_) = request.requestType, !request.isRetryRequest {
                //initialize的completion是去走kickoff流程，打开卡片
                currentRequest.completionBlock?(true)
                currentRequest.completionBlock = nil
            }
            fetchDataManager.startRequestTimer(request: currentRequest)
        case .timeOut, .failed, .success:
            currentRequest.invalidateTimer()
            currentRequest.completionBlock?(status == .success)
            _ = fetchDataManager.cardListRequestWaitingQueue.remove(currentRequest)
            
            if status == .timeOut {
                recordStatus = .timeOut(request: currentRequest)
            } else if status == .failed {
                recordStatus = .failed
            } else if status == .success {
                recordStatus = .success
            }
        default:
            break
        }

        DocsLogger.btInfo("[BTViewModel] handleRequestStatusChange requestType: \(request.requestType) status: \(status.rawValue) recordStatus:\(recordStatus)")
        
        switch request.requestType {
        case .initialize(let loaded):
            if loaded,
               var loadingRecord = tableModel.records.first(where: { $0.dataStatus != .success }) {
                loadingRecord.update(status: recordStatus)
                tableModel.updateRecord(loadingRecord, for: 0)
                notifyModelUpdate()
            }
        case .left:
            if var firstRecord = tableModel.records.first,
               firstRecord.dataStatus != .success {
                firstRecord.update(status: recordStatus)
                tableModel.updateRecord(firstRecord, for: 0)
                notifyModelUpdate()
            }
        case .right:
            if var lastRecord = tableModel.records.last,
               lastRecord.dataStatus != .success {
                lastRecord.update(status: recordStatus)
                tableModel.updateRecord(lastRecord, for: tableModel.records.count - 1)
                notifyModelUpdate()
            }
        default:
            break
        }
    }
}
