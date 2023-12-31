//
//  BTRecordLinkPanelViewModel.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/7.
//

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKResource
import SKFoundation

final class BTRecordLinkPanelViewModel: BTLinkPanelViewModelProtocol {

    private weak var delegate: BTLinkPanelDelegate?

    private weak var dataSource: BTLinkPanelDataSource?
    
    private let disposeBag = DisposeBag()

    let mode: BTViewMode

    private(set) var tableMeta: BTTableMeta?
    
    //被置顶的record
    var placedTopRecordIds = [String]()
    
    private(set) var recordModels: [BTRecordModel] = []
    
    //选中的选项
    private var selectedRecordModels = [BTRecordModel]()
    
    //选中的选项
    private(set) var selectedIDs = [String]()

    var linkFieldMetaEmpty: Bool = false

    var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            search(searchText)
        }
    }

    let updateLinkPanelSubject = PublishSubject<BTLinkPanelMode>()
    
    private let dataProvider: BTLinkTableDataProvider

    init(delegate: BTLinkPanelDelegate, dataSource: BTLinkPanelDataSource) {
        self.delegate = delegate
        self.dataSource = dataSource
        let linkFiledContext = dataSource.linkFiledContext
        self.mode = linkFiledContext.viewMode
        self.dataProvider = linkFiledContext.dataProvider
        self.dataProvider.reset()
        self.dataProvider.delegate = self
    }

    func cellState(recordModel: BTRecordModel) -> (String, Bool)? {
        return (BTUtil.getTitleAttrString(title: recordModel.recordTitle).string, recordModel.isSelected)
    }

    func changeSelectionStatus(id: String, isSelected: Bool, couldSelectMultiple: Bool) {
        DocsLogger.btInfo("[BTLinkPanelViewModel] changeSelectionStatus id:\(id), isSelected:\(isSelected), couldSelectMultiple:\(couldSelectMultiple)")
        if !isSelected {
            selectedIDs.removeAll { $0 == id }
        } else {
            if couldSelectMultiple {
                selectedIDs.append(id)
            } else {
                selectedIDs = [id]
            }
        }
        
        
        let recordIdTitles = selectedIDs.map { recordId in
            if let recordTitle = selectedRecordModels.first(where: { model in
                model.recordID == recordId
            })?.recordTitle, !recordTitle.isEmpty {
                return (recordId, recordTitle)
            } else if let recordTitle = recordModels.first(where: { model in
                model.recordID == recordId
            })?.recordTitle, !recordTitle.isEmpty {
                return (recordId, recordTitle)
            }
            return (recordId, "")
        }
        updateView()
        delegate?.updateLinkedRecords(recordIDs: selectedIDs, recordTitles: Dictionary(uniqueKeysWithValues: recordIdTitles))
        delegate?.trackUpdatedLinkage(selectionStatus: isSelected)
    }

    func reloadTable(_ type: BTCardFetchType) {
        DocsLogger.btInfo("[BTLinkPanelViewModel] reloadTable type:\(type)")
        dataProvider.resume(onece: true)
    }

    // 关联字段更新了选中数据，覆盖面板中的选中态
    func updateSelectedRecords(_ models: [BTRecordModel]) {
        DocsLogger.btInfo("[BTLinkPanelViewModel] updateSelectedRecords models:\(models.count)")
        self.selectedRecordModels = models
        selectedIDs = models.map({ model in
            model.recordID
        })
        updateView()
    }

    private func applySelection() {
        var topSelectedRecordModels = self.selectedRecordModels
        self.recordModels = recordModels.map { oldRecord -> BTRecordModel in
            var newRecord = oldRecord
            newRecord.update(selected: selectedIDs.contains(newRecord.recordID))
            // 如果已经在内容中包括，就从置顶中移除
            topSelectedRecordModels.removeAll { model in
                model.recordID == newRecord.recordID
            }
            return newRecord
        }
        if !topSelectedRecordModels.isEmpty {
            topSelectedRecordModels = topSelectedRecordModels.map({ oldRecord -> BTRecordModel in
                var newRecord = oldRecord
                newRecord.update(selected: selectedIDs.contains(newRecord.recordID))
                return newRecord
            })
            if !searchText.isEmpty {
                topSelectedRecordModels = topSelectedRecordModels.filter({ model in
                    model.recordTitle.localizedStandardContains(searchText)
                })
            }
            self.recordModels = topSelectedRecordModels + self.recordModels
        }
    }

    func search(_ keyword: String) {
        DocsLogger.btInfo("[SYNC] start searching")
        // 显示 loading
        delegate?.startLoadingTimer()
        dataProvider.search(keyWord: keyword)
    }

    private func updateView() {
        let meta = self.tableMeta ?? BTTableMeta()
        applySelection()
        updateLinkPanelSubject.onNext(.showData(tableMeta: meta, records: self.recordModels))
    }
    

    func fetchLinkCardList(_ type: BTCardFetchType,
                           _ completionBlock: ((Bool) -> Void)? = nil) {
        DocsLogger.btInfo("[BTLinkPanelViewModel] start fetchLinkCardList type:\(type)")
        if type == .linkCardTop {
            dataProvider.reload()
        } else if type == .linkCardBottom {
            dataProvider.resume(onece: true)
        }
    }

    ///处理前端dataloaded信号
    func handleDataLoaded(router: BTAsyncRequestRouter) {
    }
    

    ///处理数据加载完的请求
    private func handleRequestCompleted(request: BTGetCardListRequest,
                                        result: BTTableValue?) {
    }
    
    ///停止loading，并设置面板上拉/下拉是否展示loading
    private func stopLoadingMoreAndSetEnable(_ requestType: BTCardFetchType, tableModel: BTTableModel?) {
    }
}

extension BTRecordLinkPanelViewModel: BTLinkTableDataProviderDelegate {
    func dataUpdate(linkTableName: String?, records: [LinkRecord], hasMore: Bool, loadStatus: LinkTableLoadStatus) {
        if searchText.isEmpty, case .failed(let error) = loadStatus {
            func showTryAgainEmptyView(
                _ text: String = BundleI18n.SKResource.Bitable_SingleOption_ReloadTimeoutRetry(BundleI18n.SKResource.Bitable_Common_ButtonRetry),
                showRetry: Bool = true
            ) {
                delegate?.showTryAgainEmptyView(text: text, type: .searchFailed, tryAgainBlock: showRetry ? { [weak self] in
                    self?.dataProvider.resume(onece: true)
                } : nil)
            }
            
            // 加载失败了(搜索模式会自动拉所有数据，这种情况失败了不做处理，重新搜索再拉数据)
            if let error = error as? LinkTableError {
                switch error {
                case .invalidResponse:
                    showTryAgainEmptyView()
                case .invalidResponseData:
                    showTryAgainEmptyView()
                case .invalidLinkContent:
                    showTryAgainEmptyView()
                case .tableNotFound(_, _):
                    showTryAgainEmptyView(BundleI18n.SKResource.Bitable_QuickAdd_LinkedFieldFailed_Tooltip, showRetry: false)
                case .noPermission(_, _):
                    updateLinkPanelSubject.onNext(.noPermission)
                case .unknownError(_, _):
                    showTryAgainEmptyView(BundleI18n.SKResource.Bitable_QuickAdd_LinkedFieldFailed_Tooltip, showRetry: false)
                }
            } else {
                showTryAgainEmptyView()
            }
            return
        }
        updateLinkPanelSubject.onNext(.stopLoadingMore(requestType: .linkCardBottom, hasMore: hasMore))
        let tableMeta = BTTableMeta(tableName: linkTableName ?? "")
        self.tableMeta = tableMeta
        self.recordModels = records.map { record in
            return BTRecordModel(recordID: record.recordID, recordTitle: record.primaryValue)
        }
        if records.isEmpty, !hasMore {
            // 数据为空
            if searchText.isEmpty {
                updateLinkPanelSubject.onNext(.listEmpty(tableMeta: tableMeta))
            } else {
                updateLinkPanelSubject.onNext(.searchEmpty(tableMeta: tableMeta))
            }
        } else {
            updateView()
        }
    }
}

extension BTRecordLinkPanelViewModel: BTFetchDataDelegate {
    

    func executeRequest(request: BTGetCardListRequest,
                        isRetry: Bool = false) {
    }
    
    ///处理请求状态变化
    func handleRequestStatusChange(request: BTGetCardListRequest,
                                   status: BTGetCardListRequestStatus,
                                   result: BTTableValue?) {
    }
}
