//
// Created by duanxiaochen.7 on 2021/7/26.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKResource
import SKFoundation

protocol BTLinkPanelViewModelProtocol {
    var linkFieldMetaEmpty: Bool { get set }
    var mode: BTViewMode { get }
    var updateLinkPanelSubject: PublishSubject<BTLinkPanelMode> { get }
    var searchText: String { get set }
    var placedTopRecordIds: [String] { get }
    func updateSelectedRecords(_ models: [BTRecordModel])
    func reloadTable(_ type: BTCardFetchType)
    func fetchLinkCardList(_ type: BTCardFetchType, _ completionBlock: ((Bool) -> Void)?)
    func handleDataLoaded(router: BTAsyncRequestRouter)
    func cellState(recordModel: BTRecordModel) -> (String, Bool)?
    func changeSelectionStatus(id: String, isSelected: Bool, couldSelectMultiple: Bool)
}

final class BTLinkPanelViewModel: BTFetchDataDelegate, BTLinkPanelViewModelProtocol {

    weak var delegate: BTLinkPanelDelegate?

    weak var dataSource: BTLinkPanelDataSource?
    
    private let disposeBag = DisposeBag()

    let mode: BTViewMode

    private(set) var tableMeta: BTTableMeta?
    
    //被置顶的record
    var placedTopRecordIds = [String]()
    
    private(set) var recordModels: [BTRecordModel]? {
        didSet {
            updateView(meta: tableMeta, records: recordModels)
        }
    }
    
    //选中的选项
    private var selectedRecordModels = [BTRecordModel]()

    var linkFieldMetaEmpty: Bool = false

    private(set) var selectedIDs: [String] = []

    var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.search(self.searchText)
            }
        }
    }

    let updateLinkPanelSubject = PublishSubject<BTLinkPanelMode>()
    
    var fetchDataManager = BTFetchDataManager()

    init(delegate: BTLinkPanelDelegate, dataSource: BTLinkPanelDataSource, mode: BTViewMode) {
        self.delegate = delegate
        self.dataSource = dataSource
        self.mode = mode
        self.fetchDataManager.delegate = self
    }

    func cellState(recordModel: BTRecordModel) -> (String, Bool)? {
        return (BTUtil.getTitleAttrString(title: recordModel.recordTitle).string, recordModel.isSelected)
    }

    func changeSelectionStatus(id: String, isSelected: Bool, couldSelectMultiple: Bool) {
        var records: [BTRecordModel]?
        if searchText.isEmpty {
            records = recordModels?.filter({ !placedTopRecordIds.contains($0.recordID) })
        } else {
            records = recordModels
        }
        
        guard let records = records else { return }

        if !isSelected {
            selectedIDs.removeAll { $0 == id }
        } else {
            if couldSelectMultiple {
                selectedIDs.append(id)
            } else {
                selectedIDs = [id]
            }
        }

        applySelection(to: records, selectedIDs: selectedIDs, isNeedSetOldRecordTop: searchText.isEmpty)
        delegate?.updateLinkedRecords(recordIDs: selectedIDs, recordTitles: [:])
        delegate?.trackUpdatedLinkage(selectionStatus: isSelected)
    }

    func reloadTable(_ type: BTCardFetchType) {
        DocsLogger.btInfo("[BTLinkPanelViewModel] reloadTable type:\(type)")
        if type != .linkCardInitialize {
            fetchDataManager.clearWaitingAndDisposingRequests()
        }

        if tableMeta == nil || type == .linkCardUpdate {
            dataSource?.fetchTableMeta()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] newMeta in
                    guard let self = self else { return }
                    self.tableMeta = newMeta
                    self.tableMeta?.shouldDiscloseHiddenFields = true
                    self.fetchLinkCardList(type)
                }, onError: { [weak self] error in
                    DocsLogger.btError("[SYNC] link panel view model cannot get meta, error: \(error.localizedDescription)")
                    self?.linkFieldMetaEmpty = true
                    self?.tableMeta = nil
                    self?.recordModels = nil
                }).disposed(by: disposeBag)
        } else if type == .linkCardOnlyData {
            self.fetchLinkCardList(type)
        }
    }

    // 关联字段更新了选中数据，覆盖面板中的选中态
    func updateSelectedRecords(_ models: [BTRecordModel]) {
        selectedRecordModels = models
        selectedIDs = models.map { $0.recordID }
        // 把之前已选中的更新一下状态
        //除去被置顶的选项
        var records: [BTRecordModel]?
        if searchText.isEmpty {
            records = recordModels?.filter({ !placedTopRecordIds.contains($0.recordID) })
        } else {
            records = recordModels
        }
        
        if let values = records {
            applySelection(to: values, selectedIDs: selectedIDs, isNeedSetOldRecordTop: searchText.isEmpty)
        }
    }

    func applySelection(to oldRecords: [BTRecordModel], selectedIDs: [String], isNeedSetOldRecordTop: Bool = true) {
        var oldRecords = oldRecords
        if isNeedSetOldRecordTop {
            // 把已选(已不满足新筛选条件)的记录添加到当前记录最前面
            let oldRecordIds = oldRecords.map { $0.recordID }
            let recordsToAdd = selectedRecordModels.filter { !oldRecordIds.contains($0.recordID) }
            //被置顶的record
            placedTopRecordIds = recordsToAdd.map { $0.recordID }
            oldRecords.insert(contentsOf: recordsToAdd, at: 0)
        }
        recordModels = oldRecords.map { oldRecord -> BTRecordModel in
            var newRecord = oldRecord
            newRecord.update(selected: selectedIDs.contains(newRecord.recordID))
            return newRecord
        }
    }

    func search(_ keyword: String) {
        DocsLogger.btInfo("[SYNC] start searching")
        //触发搜索请求时，需要把当前请求队列和请求等待队列的所有请求移除
        fetchDataManager.reset()
        //显示loading
        delegate?.startLoadingTimer()
        fetchLinkCardList(.linkCardSearch)
    }

    private func updateView(meta: BTTableMeta?, records: [BTRecordModel]?) {
        guard let mode = getNextMode(by: meta, records: records) else  {
            return
        }
        updateLinkPanelSubject.onNext(mode)
    }
    
    
    /// 获取面板的下一个展示模式
    /// - Parameters:
    ///   - meta: 关联表的 meta 数据
    ///   - records: 关联表单记录数据
    /// - Returns: 下一个面板模式
    func getNextMode(by meta: BTTableMeta?, records: [BTRecordModel]?) -> BTLinkPanelMode? {
        guard let meta = meta else {
            if linkFieldMetaEmpty {
                return .tableDeleted
            } else {
                return nil
            }
        }
        
        if !meta.tableVisible {
            return .noPermission
        }
        
        if let checkResult = dataSource?.isFilterInfoValid(), !checkResult.isValid {
            return .filterInfoError(msg: checkResult.errorMsg)
        }
        
        let visibleRecords = records?.filter { $0.visible } ?? []
        if !visibleRecords.isEmpty {
            return .showData(tableMeta: meta, records: visibleRecords)
        }
        
        if searchText.isEmpty {
            return .listEmpty(tableMeta: meta)
        } else {
            return .searchEmpty(tableMeta: meta)
        }
    }
    

    func fetchLinkCardList(_ type: BTCardFetchType,
                           _ completionBlock: ((Bool) -> Void)? = nil) {
        DocsLogger.btInfo("[BTLinkPanelViewModel] start fetchLinkCardList type:\(type)")
        guard let request = dataSource?.constructCardRequest(type,
                                                             completionBlock: completionBlock,
                                                             searchKey: self.searchText) else {
            DocsLogger.btError("[BTLinkPanelViewModel] start fetchLinkCardList constructRequest failed type:\(type)")
            return
        }
        
        fetchDataManager.disposeRequest(request: request)
    }

    func executeRequest(request: BTGetCardListRequest,
                        isRetry: Bool = false) {

        dataSource?.fetchLinkCardList(request) { [weak self] resultRecord in
            guard let self = self, self.fetchDataManager.shouldHandleCallback(request: request) else { return }
            DocsLogger.btInfo("[BTLinkPanelViewModel] executeRequest success type:\(request.requestType) dataLoade:\(resultRecord.loaded)")
            self.handleRequestStatusChange(request: request,
                                           status: resultRecord.loaded ? .success : .waiting,
                                           result: resultRecord)
            self.fetchDataManager.handleNextRequest()
        } failedBlock: { [weak self] _ in
            guard let self = self, self.fetchDataManager.shouldHandleCallback(request: request) else { return }
            DocsLogger.btError("[BTLinkPanelViewModel] executeRequest failed type:\(request.requestType)")
            self.handleRequestStatusChange(request: request, status: .failed,
                                            result: nil)
            self.fetchDataManager.handleNextRequest()
        }
    }

    ///处理前端dataloaded信号
    func handleDataLoaded(router: BTAsyncRequestRouter) {
        //收到前端dataLoade信号重试等待队列的所有请求
        fetchDataManager.cardListRequestWaitingQueue.forEach { request in
            fetchDataManager.executeRequest(request: request, isRetry: true)
        }
        
        if !UserScopeNoChangeFG.ZJ.btLinkPanleSearchDisable {
            fetchDataManager.cardListRequestWaitingQueue.removeAll()
        }
    }
    
    ///处理请求状态变化
    func handleRequestStatusChange(request: BTGetCardListRequest,
                                   status: BTGetCardListRequestStatus,
                                   result: BTTableValue?) {
        
        DocsLogger.btInfo("[BTLinkPanelViewModel] handleRequestStatusChange requestType: \(request.requestType) status: \(status)")
        var currentRequest = request
        
        switch status {
        case .waiting:
            //数据loading中，放入等待队列，开启请求超时计时
            currentRequest.requestStatus = .waiting
            currentRequest.isRetryRequest = true
            fetchDataManager.startRequestTimer(request: currentRequest)
        case .timeOut:
            //处理请求超时和
            currentRequest.invalidateTimer()
            currentRequest.completionBlock?(false)
            _ = fetchDataManager.cardListRequestWaitingQueue.remove(currentRequest)
            switch currentRequest.requestType {
            case .linkCardInitialize, .linkCardSearch:
                delegate?.showTryAgainEmptyView(text: BundleI18n.SKResource.Bitable_SingleOption_ReloadTimeoutRetry(BundleI18n.SKResource.Bitable_Common_ButtonRetry),
                                                type: .searchFailed) { [weak self] in
                    //点击重试按钮，重新触发请求
                    self?.fetchDataManager.disposeRequest(request: currentRequest)
                }
            case .linkCardTop:
                updateLinkPanelSubject.onNext(.stopLoadingMore(requestType: .linkCardTop,
                                                               hasMore: true))
            case .linkCardBottom:
                updateLinkPanelSubject.onNext(.stopLoadingMore(requestType: .linkCardTop,
                                                               hasMore: true))
            default:
                break
            }
        case .success, .failed:
            //请求完成移除出等待队列
            currentRequest.invalidateTimer()
            currentRequest.completionBlock?(true)
            _ = fetchDataManager.cardListRequestWaitingQueue.remove(currentRequest)
            handleRequestCompleted(request: currentRequest, result: result)
        default:
            break
        }
    }

    ///处理数据加载完的请求
    private func handleRequestCompleted(request: BTGetCardListRequest,
                                        result: BTTableValue?) {
        guard let meta = self.tableMeta,
              let result = result else {
            self.updateView(meta: self.tableMeta, records: self.recordModels)
            return
        }

        DocsLogger.btInfo("[BTLinkPanelViewModel] handleRequestCompleted \(result.records.count) requestType:\(request.requestType)")
        var tableModel = BTTableModel()

        switch request.requestType {
        case .linkCardInitialize, .linkCardUpdate, .linkCardOnlyData, .linkCardSearch:
            //当前搜索的key为空时，需要将选中的内容置顶
            let isNeedSetOldRecordTop = searchText.isEmpty
            
            tableModel.update(meta: meta, value: result, mode: self.mode, holdDataProvider: nil)
            self.applySelection(to: tableModel.records, selectedIDs: self.selectedIDs, isNeedSetOldRecordTop: isNeedSetOldRecordTop)
            
            if request.requestType == .linkCardUpdate ||
               request.requestType == .linkCardOnlyData {
                //update需要滚动定位，因为是基于更新前列表上方可见的第一条记录向前拉取了10条记录
                if let activeIndex = recordModels?.firstIndex(where: { $0.recordID == request.requestModel.firstVisibleRecordId }) {
                    delegate?.scrollToIndex(index: activeIndex, animated: false, needFixOffest: true)
                } else {
                    delegate?.scrollToIndex(index: 0, animated: false, needFixOffest: false)
                }
            }
            
            stopLoadingMoreAndSetEnable(.linkCardTop, tableModel: tableModel)
            stopLoadingMoreAndSetEnable(.linkCardBottom, tableModel: tableModel)
        case .linkCardTop:
            //需要滚动定位
            tableModel.update(meta: meta, value: result, mode: self.mode, holdDataProvider: nil)
            stopLoadingMoreAndSetEnable(.linkCardTop, tableModel: tableModel)
            //请求回来的卡片的最后一张跟当前列表的第一张是否匹配
            guard !tableModel.records.isEmpty else {
                DocsLogger.btError("[BTLinkPanelViewModel] fetch top data records isEmpty")
                return
            }
            
            var fetchRecords = tableModel.records
            
            //去除当前列表中已置顶的选项，待请求数据拼接完成后，再走后续的置顶逻辑
            let currentRecordModels = recordModels?.filter({ !placedTopRecordIds.contains($0.recordID) }) ?? []
            
            //匹配请求回来的数据的最后一张卡片在当前列表中匹配的卡片index，有匹配的则拼接，没有则不处理
            guard let firstMatchRecordIndex = currentRecordModels.firstIndex(where: { $0.recordID == (fetchRecords.last?.recordID ?? "") }),
                  firstMatchRecordIndex < fetchRecords.count else {
                //数据不匹配，避免数据错乱，丢弃请求的数据不处理，保持原有数据，仅去除loading
                DocsLogger.btError("[BTLinkPanelViewModel] fetch top not match")
                return
            }

            fetchRecords.removeLast(firstMatchRecordIndex + 1)
            
            guard !fetchRecords.isEmpty else {
                DocsLogger.btError("[BTLinkPanelViewModel] fetch top fetchRecords isEmpty")
                return
            }
    
            self.applySelection(to: fetchRecords + currentRecordModels, selectedIDs: self.selectedIDs)
        case .linkCardBottom:
            tableModel.update(meta: meta, value: result, mode: self.mode, holdDataProvider: nil)
            stopLoadingMoreAndSetEnable(.linkCardBottom, tableModel: tableModel)
            guard !tableModel.records.isEmpty else {
                DocsLogger.btError("[BTLinkPanelViewModel] fetch bottom data records isEmpty")
                return
            }
            
            var fetchRecords = tableModel.records
            //匹配请求回来的数据的第一张在当前列表中匹配的卡片index，有匹配的则拼接，没有则不处理
            if let firstMatchRecordIndex = fetchRecords.firstIndex(where: { $0.recordID == (recordModels?.last?.recordID ?? "") }),
               firstMatchRecordIndex < fetchRecords.count {
                fetchRecords.removeFirst(firstMatchRecordIndex + 1)
            } else {
                //数据不匹配，避免数据错乱，丢弃请求的数据不处理，保持原有数据，仅去除loading
                DocsLogger.btError("[BTLinkPanelViewModel] fetch bottom not match")
                return
            }
            
            guard !fetchRecords.isEmpty else {
                DocsLogger.btError("[BTLinkPanelViewModel] fetch bottom fetchRecords isEmpty")
                return
            }
            
            //去重处理，当前请求回来的数据包括已置顶的数据时，需要将已置顶的数据去除
            let fetchRecordIDs = fetchRecords.map { $0.identify }
            let currentRecordModels = recordModels?.filter({ !fetchRecordIDs.contains($0.recordID) }) ?? []
            
            let records = currentRecordModels + fetchRecords
            self.applySelection(to: records, selectedIDs: self.selectedIDs, isNeedSetOldRecordTop: false)
        default:
            break
        }
    }
    
    ///停止loading，并设置面板上拉/下拉是否展示loading
    private func stopLoadingMoreAndSetEnable(_ requestType: BTCardFetchType, tableModel: BTTableModel?) {
        guard let recordModels = tableModel?.records else {
            return
        }

        switch requestType {
        case .linkCardTop:
            var enableLoadTopMore = true
            if let firstRecord = recordModels.first,
               firstRecord.globalIndex == 0 {
                //已无向上的分页数据
                enableLoadTopMore = false
            }
            updateLinkPanelSubject.onNext(.stopLoadingMore(requestType: .linkCardTop,
                                                           hasMore: enableLoadTopMore))
        case .linkCardBottom:
            var enableLoadBottomMore = true
            if let tableModel = tableModel,
               let lastRecord = recordModels.last,
               lastRecord.globalIndex == tableModel.total - 1 {
                //已无向下的分页数据
                enableLoadBottomMore = false
            }
            updateLinkPanelSubject.onNext(.stopLoadingMore(requestType: .linkCardBottom,
                                                           hasMore: enableLoadBottomMore))
        default:
            break
        }
    }
}


protocol BTLinkPanelDataSource: AnyObject {
    
    var linkFiledContext: (dataProvider: BTLinkTableDataProvider, viewMode: BTViewMode) { get }

    var nextMode: BTViewMode { get }

    func fetchTableMeta() -> Single<BTTableMeta>
    
    func isFilterInfoValid() -> (isValid: Bool, errorMsg: String)

    func fetchLinkCardList(_ request: BTGetCardListRequest?,
                           successBlock: @escaping (BTTableValue) -> Void,
                           failedBlock: @escaping (Error?) -> Void)

    func constructCardRequest(_ type: BTCardFetchType,
                              completionBlock: ((Bool) -> Void)?,
                              searchKey: String?) -> BTGetCardListRequest?
}
