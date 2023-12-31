//
// Created by duanxiaochen.7 on 2021/7/26.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import SKBrowser
import SKResource
import SKCommon
import RxSwift
import SKUIKit
import SKFoundation
import UniverseDesignToast
import UniverseDesignEmpty

final class BTLinkEditAgent: BTBaseEditAgent {
    private weak var gestureManager: BTPanGestureManager!

    var currentLinkingBaseID: String = ""
    var currentLinkingTableID: String = ""
    
    private var throttle = SKThrottle(interval: 0.25)

    private lazy var cancelBtn: UIButton = UIButton(type: .custom).construct { (it) in
        it.rx.tap.subscribe(onNext: { [weak self]_ in
            self?.stopEditing(immediately: false)
        })
        .disposed(by: disposeBag)
    }

    private lazy var panel = BTLinkPanel(gestureManager: gestureManager,
                                         delegate: self,
                                         dataSource: self,
                                         superViewBottomOffset: coordinator?.inputSuperviewDistanceToWindowBottom ?? 0)

    override var editingPanelRect: CGRect {
        return panel.convert(panel.bounds, to: inputSuperview)
    }

    private let disposeBag = DisposeBag()
    
    private(set) var isEditing = false
    
    private(set) var filterInfo: BTFilterInfos?
    
    /// 过滤条件是否发生变更，过滤条件发生变更也要触发diff
    private(set) var filterInfoHasChange: Bool = false

    init(fieldID: String, recordID: String, gestureManager: BTPanGestureManager) {
        super.init(fieldID: fieldID, recordID: recordID)
        self.gestureManager = gestureManager
    }

    // 关联字段内容协同变更
    override func updateInput(fieldModel: BTFieldModel) {
        super.updateInput(fieldModel: fieldModel)
        guard let editingField = relatedVisibleField as? BTFieldLinkCellProtocol else { return }
        guard fieldModel.property.tableId == currentLinkingTableID else {
            if !UserScopeNoChangeFG.ZJ.btLinkPanelUpdateDataFixDisable {
                // 关联table发生变化，关闭面板
                self.stopEditing(immediately: false)
            }
            return
        }
        filterInfoHasChange = filterInfo != fieldModel.filterInfo
        filterInfo = fieldModel.filterInfo
        updatePanel(fieldModel: fieldModel, isFirstLoad: false)
        coordinator?.currentCard?.panelDidStartEditingField(editingField, scrollPosition: .bottom)
    }

    override var editType: BTFieldType { .singleLink } // duplex link 4.8 再支持编辑

    override func startEditing(_ cell: BTFieldCellProtocol) {
        coordinator?.currentCard?.keyboard.stop()
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if coordinator?.viewModel.tableMeta.fields[fieldID]?.property.tableVisible == false {
                DocsLogger.info("table no visible, cannot edit link field")
                if let onView = coordinator?.attachedController.view {
                    UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_ContactOwnerBeforeLinkRecords_Toast, on: onView)
                } else {
                    DocsLogger.error("get onview by coordinator?.attachedController.view failed")
                }
                self.stopEditing(immediately: false)
                return
            }
        }
        guard let editingField = relatedVisibleField as? BTFieldLinkCellProtocol else { return }
        isEditing = true
        currentLinkingBaseID = editingField.fieldModel.property.baseId
        currentLinkingTableID = editingField.fieldModel.property.tableId

        inputSuperview.addSubview(cancelBtn)
        inputSuperview.addSubview(panel)
        panel.snp.makeConstraints { it in
            it.top.equalTo(inputSuperview.bounds.height)
            it.bottom.equalTo(inputSuperview.snp.bottom)
            it.left.right.equalToSuperview()
        }
        cancelBtn.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(panel.snp.top)
        }

        updatePanel(fieldModel: editingField.fieldModel, isFirstLoad: true)
        inputSuperview.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, animations: { [self] in
            panel.snp.updateConstraints { it in
                it.top.equalTo(inputSuperview.bounds.height - gestureManager.midHeight)
            }
            inputSuperview.layoutIfNeeded()
        }, completion: { [self] _ in
            editingField.panelDidStartEditing()
            trackOpenLinkPanel(currentLinkageCount: editingField.linkedRecords.count, fieldModel: editingField.fieldModel)
        })
    }

    private func updatePanel(fieldModel: BTFieldModel, isFirstLoad: Bool) {
        panel.updateSelectedRecords(fieldModel.linkedRecords) // 从字段协同过来的数据一定是 selected 状态的，而被关联表格本身的协同要走 viewModel.reloadTable 重新拉
        panel.couldLinkMultipleRecords = fieldModel.property.multiple
        panel.linkFieldMetaEmpty = fieldModel.property.fields.isEmpty

        if isFirstLoad { // 这里是面板第一次加载数据的触发时机，后续从 field 中更新 panel 不进行全量拉取，只在下面的 respond(to:) 里面响应 linkRecordDataLoaded 时全量拉取
            panel.startLoadingTimer()
            panel.reloadViews(.linkCardInitialize)
        } else if filterInfoHasChange,
                  !UserScopeNoChangeFG.ZJ.btLinkPanelUpdateDataFixDisable {
            // 筛选条件发生变更，需要刷新关联面板
            panel.reloadViews(.linkCardUpdate)
        }
        
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            let hideNoPermTips = coordinator?.viewModel.mode == .addRecord || fieldModel.linkedRecords.first(where: { !$0.visible }) == nil
            // 关联+点开如果有无权限，需要展示tips
            panel.setNoPermTips(hidden: hideNoPermTips)
        }
    }

    // 被关联的 table 数据协同
    func respond(to actionParams: BTActionParamsModel) {
        DocsLogger.btInfo("[SYNC] \(actionParams.data.tableId) 的 edit agent 响应 action:\(actionParams.action)")
        guard actionParams.data.tableId == currentLinkingTableID else {
            DocsLogger.btError("[SYNC] receive resopnd tableId:\(actionParams.data.tableId) currentLinkingTableID:\(currentLinkingTableID)")
            return
        }
        
        throttle.schedule({ [weak self] in
            if actionParams.action == .updateField || actionParams.action == .linkTableChanged {
                self?.panel.reloadViews(.linkCardUpdate)
            } else if actionParams.action == .updateRecord {
                self?.panel.reloadViews(.linkCardOnlyData)
            }
        }, jobId: actionParams.action.rawValue)
    }

    override func stopEditing(immediately: Bool, sync: Bool = false) {
        defer {
            baseDelegate?.didCloseEditPanel(self, payloadParams: nil)
            coordinator?.invalidateEditAgent()
            (relatedVisibleField as? BTFieldLinkCellProtocol)?.stopEditing()
            coordinator?.currentCard?.keyboard.start()
            isEditing = false
        }
        cancelBtn.removeFromSuperview()
        guard panel.superview != nil else { return }
        panel.hide(immediately: immediately)
    }

    override func handleEmitEvent(event: BTEmitEvent, router: BTAsyncRequestRouter) {
        switch event {
        case .dataLoaded:
            guard router == .getLinkCardList else { return }
            panel.handleDataLoaded(router: router)
        }
    }
}


extension BTLinkEditAgent: BTLinkPanelDelegate {

    func updateLinkedRecords(recordIDs: [String], recordTitles: [String: String]) {
        editHandler?.updateLinkedRecords(fieldID: fieldID, linkedRecordIDs: recordIDs, recordTitles: recordTitles)
    }

    func trackOpenLinkPanel(currentLinkageCount: Int, fieldModel: BTFieldModel) {
        if var trackParams = coordinator?.viewModel.getCommonTrackParams() {
            trackParams["relation_count"] = currentLinkageCount
            trackParams["field_type"] = fieldModel.compositeType.fieldTrackName
            DocsTracker.newLog(enumEvent: .bitableCardLinkPanelView, parameters: trackParams)
        }
    }

    func trackUpdatedLinkage(selectionStatus: Bool) {
        if var trackParams = coordinator?.viewModel.getCommonTrackParams() {
            guard let editingField = relatedVisibleField as? BTFieldLinkCellProtocol else { return }
            trackParams["click"] = "click_record"
            trackParams["target"] = "none"
            trackParams["status"] = selectionStatus ? "open" : "close"
            trackParams["field_type"] = editingField.fieldModel.compositeType.fieldTrackName
            DocsTracker.newLog(enumEvent: .bitableCardLinkFieldClick, parameters: trackParams)
        }
    }

    func beginSearching() {
        gestureManager.resizePanel(panel: panel, to: .max)
        if var trackParams = coordinator?.viewModel.getCommonTrackParams() {
            guard let editingField = relatedVisibleField as? BTFieldLinkCellProtocol else { return }
     
            trackParams["click"] = "search"
            trackParams["target"] = "none"
            trackParams["field_type"] = editingField.fieldModel.compositeType.fieldTrackName
            DocsTracker.newLog(enumEvent: .bitableCardLinkFieldClick, parameters: trackParams)
        }
    }

    func createAndLinkNewRecord(primaryText: String?) {
        guard let editingField = relatedVisibleField as? BTFieldLinkCellProtocol else { return }
        let filterConditionCount = editingField.fieldModel.property.filterInfo?.conditions.count ?? 0
        let hasFilter = filterConditionCount > 0
        if hasFilter {
            // 关联字段已有筛选条件，阻止用户直接通过搜索添加
            let host = coordinator?.attachedController.view ?? panel
            let toast = BundleI18n.SKResource.Bitable_Relation_UnableToAddRecordWithConditionField
            UDToast.showFailure(with: toast, on: host)
            return
        }
        // origin id 后续用不到，也没有实际意义，可以传空
        let fromLocation = BTFieldLocation(originBaseID: "",
                                           originTableID: "",
                                           baseID: coordinator?.viewModel.actionParams.data.baseId ?? "",
                                           tableID: coordinator?.viewModel.actionParams.data.tableId ?? "",
                                           viewID: "",
                                           recordID: coordinator?.viewModel.currentRecordID ?? "",
                                           fieldID: fieldID)
        let toLocation = BTFieldLocation(originBaseID: "",
                                         originTableID: "",
                                         baseID: editingField.fieldModel.property.baseId,
                                         tableID: editingField.fieldModel.property.tableId,
                                         viewID: editingField.fieldModel.property.viewId,
                                         recordID: "",
                                         fieldID: editingField.fieldModel.property.primaryFieldId)
        
        var value: [BTRichTextSegmentModel]?
        if let primaryText = primaryText {
            value = [BTRichTextSegmentModel(type: .text, text: primaryText)]
        }
        
        editHandler?.addNewLinkedRecord(fromLocation: fromLocation, toLocation: toLocation, value: value, resultHandler: nil)
        if var trackParams = coordinator?.viewModel.getCommonTrackParams() {
            trackParams["click"] = "create_record"
            trackParams["target"] = "ccm_bitable_card_view"
            trackParams["field_type"] = editingField.fieldModel.compositeType.fieldTrackName
            DocsTracker.newLog(enumEvent: .bitableCardLinkFieldClick, parameters: trackParams)
        }
    }

    func finishLinking(_ panel: BTLinkPanel) {
        self.stopEditing(immediately: false)
    }
    
    func startLoadingTimer() {
        panel.startLoadingTimer()
    }
    
    func showTryAgainEmptyView(text: String, type: UDEmptyType, tryAgainBlock: (() -> Void)?) {
        panel.showTryAgainEmptyView(text: text, type: type, tryAgainBlock: tryAgainBlock)
    }
    
    func scrollToIndex(index: Int, animated: Bool, needFixOffest: Bool) {
        panel.scrollToIndex(index: index, animated: animated, needFixOffest: needFixOffest)
    }
}


extension BTLinkEditAgent: BTLinkPanelDataSource {
    
    var linkFiledContext: (dataProvider: BTLinkTableDataProvider, viewMode: BTViewMode) {
        get {
            let baseToken = coordinator?.editorDocsInfo.token ?? ""
            let tableID = coordinator?.viewModel.tableModel.tableID ?? ""
            let filedID = self.fieldID
            let linkDataProvider = coordinator?.viewModel.dataService?.holdDataProvider?.getLinkDataProvider(baseToken: baseToken, tableID: tableID, filedId: filedID) ?? BTLinkTableDataProvider(baseToken: baseToken, tableID: tableID, fieldID: filedID)
            return (dataProvider: linkDataProvider, viewMode: coordinator?.viewModel.mode ?? .card)
        }
    }
 
    var nextMode: BTViewMode {
        return .link
    }

    func fetchTableMeta() -> Single<BTTableMeta> {
        return Single<BTTableMeta>.create { [weak self] single in
            guard let self = self, let editingField = self.relatedVisibleField as? BTFieldLinkCellProtocol else {
                return Disposables.create()
            }
            self.editHandler?.dataService?.fetchTableMeta(
                baseID: editingField.fieldModel.property.baseId,
                tableID: editingField.fieldModel.property.tableId,
                viewID: editingField.fieldModel.property.viewId,
                viewMode: .card,
                fieldIds: [],
                resultHandler: { result, error in
                    if let error = error {
                        single(.error(error))
                        return
                    }
                    guard let result = result else {
                        single(.error(NSError(domain: "bitable", code: 999, userInfo: nil)))
                        return
                    }
                    single(.success(result))
                })
            return Disposables.create()
        }
    }

    func fetchLinkCardList(_ request: BTGetCardListRequest?,
                           successBlock: @escaping (BTTableValue) -> Void,
                           failedBlock: @escaping (Error?) -> Void) {
        guard let request = request,
              let editingField = relatedVisibleField as? BTFieldLinkCellProtocol else {
            return
        }
        
        let baseData = BTBaseData(baseId: request.requestModel.baseId,
                                  tableId: request.requestModel.tableId,
                                  viewId: request.requestModel.viewId)
        
        let args = BTJSFetchLinkCardArgs(baseData: baseData,
                                         bizTableId: coordinator?.viewModel.actionParams.data.tableId ?? "",
                                         bizFieldId: editingField.fieldModel.fieldID,
                                         recordIDs: request.requestModel.recordIds,
                                         startFromLeft: request.requestModel.startFromLeft,
                                         fetchCount: request.requestModel.fetchCount,
                                         fieldIDs: request.requestModel.fieldIds,
                                         searchKey: request.requestModel.searchKey)

        if UserScopeNoChangeFG.ZYS.loadRecordsOnDemand, coordinator?.viewModel.tableMeta.isPartial == true {
            DocsLogger.btInfo("fetchLinkCardList start for partical table")
            var bizData: [String: Any] = [
                "offset": args.startFromLeft,
                "length": args.fetchCount,
                "fieldId": fieldID,
            ]
            bizData["keywords"] = args.searchKey
            editHandler?.dataService?.asyncJsRequest(
                biz: .card,
                funcName: .asyncJsRequest,
                baseId: baseData.baseId,
                tableId: baseData.tableId,
                params: [
                    "router": BTAsyncRequestRouter.getLinkCardList.rawValue,
                    "tableId": baseData.tableId,
                    "data": bizData
                ],
                overTimeInterval: nil,
                responseHandler: { [weak self] response in
                    guard let self = self else {
                        return
                    }
                    switch response {
                    case .success(let resp):
                        DocsLogger.btInfo("fetchLinkCardList success call back")
                        BTTableValue.desrializedGlobalAsync(with: resp.data, callbackInMainQueue: true) { model in
                            if let model {
                                DocsLogger.info("fetchLinkCardList success finish")
                                successBlock(model)
                            } else {
                                DocsLogger.info("fetchLinkCardList fail, decode error")
                                failedBlock(DocsNetworkError.invalidData)
                            }
                        }
                    case .failure(let error):
                        DocsLogger.error("fetchLinkCardList fail call back", error: error)
                        failedBlock(error)
                    }
                },
                resultHandler: { result in
                    DocsLogger.info("fetchLinkCardList call result: \(result)")
                })
            return
        }
        
        editHandler?.dataService?.fetchLinkCardList(args: args,
                                                    resultHandler: { result, error in
            if let error = error {
                failedBlock(error)
            }

            guard let result = result else {
                failedBlock(NSError(domain: "bitable", code: 1003, userInfo: nil))
                return
            }

            successBlock(result)
        })
    }

    func constructCardRequest(_ type: BTCardFetchType,
                              completionBlock: ((Bool) -> Void)? = nil,
                              searchKey: String?) -> BTGetCardListRequest? {

        guard let editingField = self.relatedVisibleField as? BTFieldLinkCellProtocol else {
            return nil
        }

        var recordIds: [String]?
        
        switch type {
        case .linkCardUpdate, .linkCardOnlyData:
            //需要把当前可视的所有recordID都传给前端，避免部分record被删除，导致前端没法定位请求数据范围
            recordIds = panel.visibleRecordIDsNotPlacedTop
        case .linkCardTop:
            //向上请求数据
            if let recordId = panel.firstRecordID {
                recordIds = [recordId]
            }
        case .linkCardBottom:
            //向下请求数据
            if let recordId = panel.lastRecordID {
                recordIds = [recordId]
            }
        default:
            break
        }
        
        let requestModel = BTGetCardListModel(baseId: editingField.fieldModel.property.baseId,
                                              tableId: editingField.fieldModel.property.tableId,
                                              viewId: editingField.fieldModel.property.viewId,
                                              startFromLeft: type.offset(fromCurrentIndex: panel.firstVisibleRecordIdxNotPlacedTop,
                                                                         currentCount: panel.currentVisibleRecordsCount),
                                              fetchCount: type.preloadSize(currentCount: panel.currentVisibleRecordsCount),
                                              firstVisibleRecordId: panel.firstVisibleRecordID,
                                              recordIds: recordIds,
                                              fieldIds: [editingField.fieldModel.property.primaryFieldId],
                                              searchKey: searchKey)

        let request = BTGetCardListRequest(requestId: String(Date().timeIntervalSince1970),
                                           requestType: type,
                                           requestStatus: .start,
                                           requestModel: requestModel,
                                           completionBlock: completionBlock)

        return request
    }
    
     /// 关联的筛选信息是否有效，如果无效返回提醒信息
    func isFilterInfoValid() -> (isValid: Bool, errorMsg: String) {
        let filterConditionCount = relatedVisibleField?.fieldModel.property.filterInfo?.conditions.count ?? 0
        let hasFilter = filterConditionCount > 0
        if hasFilter,
           let msg = relatedVisibleField?.fieldModel.fieldWarning,
           !msg.isEmpty {
            return (false, msg)
        }
        return (true, "")
    }
}
