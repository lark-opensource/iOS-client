//
//  BTFilterPanelManager.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/19.
//  


import SKFoundation
import SKUIKit
import SKCommon
import EENavigator
import SKResource
import UniverseDesignToast
import UniverseDesignActionPanel

final class BTFilterPanelManager {
    
    var hostDocsInfo: DocsInfo?
    
    private var viewModel: BTFilterPanelViewModel
    
    private var baseData: BTBaseData
    
    private weak var filterPanelVC: BTFilterPanelController?
    
    private weak var filterVCV2: BTFilterControllerV2?
    
    private var filterFlowManager: BTFilterManager?
    
    private var filterService: BTFilterDataService
    weak var dataService: BTDataService?
    
    private let baseContext: BaseContext
    
    init(baseData: BTBaseData, jsService: SKExecJSFuncService, baseContext: BaseContext, dataService: BTDataService?, callback: String) {
        self.baseData = baseData
        self.baseContext = baseContext
        self.dataService = dataService
        filterService = BTFilterDataService(baseData: baseData,
                                                jsService: jsService,
                                                dataService: dataService)
        self.viewModel = BTFilterPanelViewModel(filterPanelService: BTFilterPanelDataService(jsService: jsService),
                                                filterFlowService: filterService,
                                                callback: callback)
    }
    /// 获取筛选Controller
    func getFilterController() -> BTFilterControllerV2 {
        if let vc = self.filterVCV2 {
            return vc
        } else {
            let filterVC = BTFilterControllerV2(model: BTFilterPanelModel())
            filterVC.delegate = self
            self.filterVCV2 = filterVC
            return filterVC
        }
        
    }
    /// 展示筛选面板
    func showFilterPanelIfCan(from hostVC: UIViewController) {
        viewModel.getFilterPanelModel { [weak self] model in
            guard let model = model else {
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Error_SyetemErrorCommonTips_Mobile, on: hostVC.view)
                return
            }
            self?.showOrUpdateFilterPanel(model: model, hostVC: hostVC)
        }
    }
    /// 更新筛选面板
    func updateFilterPanelIfNeedV2() {
        guard filterVCV2 != nil else { return }
        viewModel.getFilterPanelModel { [weak self] model in
            guard let model = model else {
                return
            }
            self?.filterVCV2?.updateModel(model)
        }
    }
    /// 更新筛选面板
    func updateFilterPanelIfNeed() {
        guard filterPanelVC != nil else { return }
        viewModel.getFilterPanelModel { [weak self] model in
            guard let model = model else {
                return
            }
            self?.filterPanelVC?.updateModel(model)
        }
    }
    /// 关闭筛选面板
    func closeFilterPanel() {
        filterPanelVC?.dismiss(animated: false)
    }
    
    private func showOrUpdateFilterPanel(model: BTFilterPanelModel, hostVC: UIViewController) {
        trackEvent(.view)
        guard self.filterPanelVC == nil else {
            self.filterPanelVC?.updateModel(model)
            return
        }
        let filterPanelVC = BTFilterPanelController(model: model, shouldShowDragBar: !BTNavigator.isReularSize(hostVC))
        filterPanelVC.delegate = self
        self.filterPanelVC = filterPanelVC
        BTNavigator.presentDraggableVCEmbedInNav(filterPanelVC, from: hostVC)
    }
    
    /// 由事件触发数据更新
    private func updateFilterInfoAndReloadFilterPanelVC(action: BTFilterPanelViewModel.UpdateFilterInfoAction) {
        viewModel.updateFilterInfo(action: action) { [weak self] model in
            guard let self = self, let model = model else {
                if let view = self?.filterPanelVC?.view {
                    UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Error_SyetemErrorCommonTips_Mobile, on: view)
                }
                return
            }
            var scrollToIndex: Int?
            switch action {
            case .addCondition:
                scrollToIndex = model.conditions.count > 0 ? model.conditions.count - 1 : nil
            default: break
            }
            self.filterPanelVC?.updateModel(model, scrollToConditionAt: scrollToIndex)
        }
    }
    
    /// 由事件触发数据更新
    private func updateFilterInfoAndReloadFilterPanelVCV2(action: BTFilterPanelViewModel.UpdateFilterInfoAction) {
        viewModel.updateFilterInfo(action: action) { [weak self] model in
            guard let self = self, let model = model else {
                if let view = self?.filterVCV2?.view {
                    UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Error_SyetemErrorCommonTips_Mobile, on: view)
                }
                return
            }
            var scrollToIndex: Int?
            switch action {
            case .addCondition:
                scrollToIndex = model.conditions.count > 0 ? model.conditions.count - 1 : nil
            default: break
            }
            self.filterVCV2?.updateModel(model, scrollToConditionAt: scrollToIndex)
        }
    }
}

// MARK: - BTFilterPanelControllerDelegate
extension BTFilterPanelManager: BTFilterPanelControllerDelegate {
    
    /// 增加
    func filterPanelControllerDidTapAddNewCondition(_ controller: BTFilterPanelController) {
        trackEvent(.click(.add))
        viewModel.makeNewCondtion { [weak self] newCondition in
            guard let newCondition = newCondition else {
                return
            }
            
            self?.updateFilterInfoAndReloadFilterPanelVC(action: .addCondition(newCondition))
        }
    }
    /// 删除
    func filterPanelController(_ controller: BTFilterPanelController, didTapDeleteAt index: Int, conditionModel: BTConditionSelectCellModel) {
        trackEvent(.click(.delete(conditionIndex: index)))
        updateFilterInfoAndReloadFilterPanelVC(action: .removeCondition(conditionModel.conditionId))
    }
    
    /// 更新，重新触发请求
    func filterPanelController(_ controller: BTFilterPanelController, conditionModel: BTConditionSelectCellModel) {
        updateFilterInfoAndReloadFilterPanelVC(action: .reloadCondition(conditionModel.conditionId))
    }
    
    /// 更改
    func filterPanelController(_ controller: BTFilterPanelController,
                               didTapItemAt index: Int,
                               conditionCell: UITableViewCell,
                               conditionSubCell: UICollectionViewCell?,
                               subCellIndex: Int) {
        
        guard let jsData = viewModel.cacheJSData else { return }
        
        trackEvent(.click(.conditionContent(conditionIndex: index, stepIndex: subCellIndex)))
        
        let filterFlowManager = BTFilterManager(viewModel: BTFilterViewModel(filterOptions: jsData.filterOptions,
                                                                             dataService: viewModel.filterFlowService),
                                                coordinator: BTFilterCoordinator(
                                                    hostVC: controller,
                                                    baseContext: baseContext
                                                )
        )
        filterFlowManager.trackInfo = BTFilterEventTrackInfo(hostDocsInfo: hostDocsInfo, baseData: baseData, filterType: "filter")
        self.filterFlowManager = filterFlowManager
        filterFlowManager.ex_showFilterFlowPanel(conditionIndex: index,
                                                 conditionCell: conditionCell,
                                                 subCellIndex: subCellIndex,
                                                 subCell: conditionSubCell,
                                                 filterInfos: jsData.filterInfos,
                                                 filterOptions: jsData.filterOptions,
                                                 linkCellModels: jsData.cellModes,
                                                 hostVC: controller,
                                                 successHanler: { [weak self] newCondition in
            self?.updateFilterInfoAndReloadFilterPanelVC(action: .updateCondition(newCondition))
        }, failHandler: nil)
    }
    /// 任一/所有
    func filterPanelController(_ controller: BTFilterPanelController,
                               didTapConjuction button: BTConditionSelectButton) {
        
        let result = viewModel.getConjuctionSelectedModels()
        let popSource = UDActionSheetSource(sourceView: button,
                                            sourceRect: button.bounds,
                                            preferredContentWidth: 84,
                                            arrowDirection: [.down, .up])
        let pageInfo = PoppverPageInfo(title: BundleI18n.SKResource.Bitable_SingleOption_MeetConditionTitle_Mobile,
                                       dataList: result.models,
                                       defaultTypeIndex: result.selectedIndex,
                                       popSource: popSource,
                                       hostVC: controller)
        var vc: BTPanelController?
        
        let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
            guard let self = self, let itemId = id else { return }
            let index = Int(itemId) ?? 0
            self.handleSelectConjuction(at: index)
            // 关闭当前选择面板
            vc?.dismiss(animated: true)
        }
        
        
        var index = -1
        let datas = result.models.map {
            index = index + 1
            return BTCommonDataItem(id: String(index),
                                    selectable: false,
                                    selectCallback: selectCallback,
                                    leftIcon: .init(image: result.selectedIndex == index ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                                    size: CGSize(width: 20, height: 20)),
                                    mainTitle: .init(text: $0.title))
        }
        vc = BTPanelController(title: BundleI18n.SKResource.Bitable_SingleOption_MeetConditionTitle_Mobile,
                               data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "filter",
                                                                                  items: datas)]),
                               delegate: nil,
                               hostVC: controller, baseContext: baseContext)
        vc?.setCaptureAllowed(true)
        vc?.automaticallyAdjustsPreferredContentSize = false
        guard let vc = vc else { return }
        
        if controller.isMyWindowRegularSize() && SKDisplay.pad {
            BTNavigator.presentActionSheetPage(with: pageInfo) { [weak self] index in
                self?.handleSelectConjuction(at: index)
            }
        } else {
            BTNavigator.presentSKPanelVCEmbedInNav(vc, from: UIViewController.docs.topMost(of: controller) ?? controller)
        }
    }
    
    func handleSelectConjuction(at index: Int) {
        guard let jsData = viewModel.cacheJSData else { return }
        let selectedConjuction = jsData.filterOptions.conjunctionOptions[index].value
        trackEvent(.click(.conjuction(value: selectedConjuction)))
        guard jsData.filterInfos.conjunction != selectedConjuction else {
            return
        }
        updateFilterInfoAndReloadFilterPanelVC(action: .updateConjuction(value: selectedConjuction))
    }
    
    func handleSelectConjuctionV2(at index: Int) {
        guard let jsData = viewModel.cacheJSData else { return }
        let selectedConjuction = jsData.filterOptions.conjunctionOptions[index].value
        trackEvent(.click(.conjuction(value: selectedConjuction)))
        guard jsData.filterInfos.conjunction != selectedConjuction else {
            return
        }
        updateFilterInfoAndReloadFilterPanelVCV2(action: .updateConjuction(value: selectedConjuction))
    }
}

// MARK: - Event Track
extension BTFilterPanelManager {
    
    enum PanelEventType {
        enum ClickEventType {
            case add
            case conditionContent(conditionIndex: Int, stepIndex: Int)
            case delete(conditionIndex: Int)
            case conjuction(value: String)
        }
        
        case view
        case click(ClickEventType)
    }
    
    func trackEvent(_ event: PanelEventType) {
        var commonParams = BTEventParamsGenerator.createCommonParams(by: hostDocsInfo,
                                                          baseData: baseData)
        commonParams["filter_type"] = "filter"
        commonParams["is_premium_limited"] =  DocsTracker.toString(value: viewModel.cacheJSData?.filterInfos.conditions.contains(where: { condition in
            return condition.invalidType == .fieldUnreadable
        }))
        if let type = BTGlobalTableInfo.currentViewInfoForBase(baseData.baseId)?.gridViewLayoutType {
            commonParams[BTTableLayoutSettings.ViewType.trackKey] = type.trackValue
            if UserScopeNoChangeFG.XM.nativeCardViewEnable {
                commonParams.merge(other: CardViewConstant.commonParams)
            }
        } else {
            commonParams[BTTableLayoutSettings.ViewType.trackKey] = BTTableLayoutSettings.ViewType.classic.trackValue
        }
        if UserScopeNoChangeFG.ZYS.loadRecordsOnDemand {
            if let isRowLimit = viewModel.cacheJSData?.filterInfos.isRowLimit {
                commonParams["is_row_limit"] = isRowLimit ? "true" : "false"
            }
            if let ver = viewModel.cacheJSData?.filterInfos.schemaVersion {
                commonParams["schema_version"] = "\(ver)"
            }
        }
        switch event {
        case .view:
            DocsTracker.newLog(enumEvent: .bitableFilterSetView, parameters: commonParams)
        case .click(let clickEvent):
            updateParamsByClickEvent(clickEvent, params: &commonParams)
            DocsTracker.newLog(enumEvent: .bitableFilterSetClick, parameters: commonParams)
        }
    }
    
    private func updateParamsByClickEvent(_ clickEvent: PanelEventType.ClickEventType,
                                          params: inout [String: String]) {
        
        // 获取条件相关数据
        func getConditionRelateDatas(by conditionIndex: Int) -> (condition: BTFilterCondition?, field: BTFilterOptions.Field?) {
            var condition: BTFilterCondition?
            var fieldOption: BTFilterOptions.Field?
            if let jsData = viewModel.cacheJSData,
                jsData.filterInfos.conditions.count > conditionIndex {
                condition = jsData.filterInfos.conditions[conditionIndex]
                fieldOption = jsData.filterOptions.fieldOptions.first(where: { $0.id == condition?.fieldId })
            }
            return (condition, fieldOption)
        }
        params["target"] = "none"
        switch clickEvent {
        case .add:
            params["click"] = "add_condition"
        case let .conditionContent(conditionIndex, stepIndex):
            let (condition, field) = getConditionRelateDatas(by: conditionIndex)
            let stringForTrack = field?.compositeType.fieldTrackName ?? "none"
            let valueType = BTFilterValueType(valueType: field?.valueType ?? 0)
            let isCheckBox = valueType == .checkbox
            /// checkbox 特殊埋点
            if stepIndex == 1, isCheckBox {
                params["click"] = "input_click"
                return
            }
            let isDate = valueType == .date
            let step = BTFilterHelper.getFilterStep(by: stepIndex)
            params["field_type"] = stringForTrack
            switch step {
            case .field:
                params["click"] = "condition_click"
            case .rule:
                params["click"] = "operation_click"
                params["operator"] = BTFilterOperator(rawValue: condition?.operator ?? "")?.tracingString ?? "none"
            case .value:
                let _dateValue = isDate ? (condition?.value?.first as? String) : nil
                if let dateValue = _dateValue, let duration = BTFilterDuration(rawValue: dateValue) {
                    params["filter_day_value"] = duration.trackString
                }
                params["click"] = "input_click"
            }
        case let .delete(conditionIndex):
            let (condition, field) = getConditionRelateDatas(by: conditionIndex)
            let stringForTrack = field?.compositeType.fieldTrackName ?? "none"
            params["click"] = "delete_click"
            params["field_type"] = stringForTrack
        case .conjuction(let value):
            var trackValue: String = "unknow"
            switch value {
            case "and":
                trackValue = "all"
            case "or":
                trackValue = "any"
            default:
                break
            }
            params["click"] = "\(trackValue)_condition"
        }
    }
}

extension BTFilterPanelManager: BTFilterControllerDelegateV2 {
    /// 将要显示
    func filterPanelControllerWillShow(_ controller: BTFilterControllerV2) {
        trackFilterPanelViewV1()
        viewModel.getFilterPanelModel { [weak self] model in
            guard let vc = self?.filterVCV2 else {
                DocsLogger.info("[BTFIlterPanelManager] getFilterPanelModel filterVCV2 is nil")
                self?.trackFilterPanelViewV2()
                return
            }
            guard let model = model else {
                DocsLogger.info("[BTFIlterPanelManager] getFilterPanelModel model is nil")
                self?.trackFilterPanelViewV2()
                return
            }
            vc.updateModel(model)
            // 埋点依赖获取的数据
            self?.trackFilterPanelViewV2()
        }
    }
    
    private func trackFilterPanelViewV1() {
        guard !UserScopeNoChangeFG.ZYS.loadRecordsOnDemand else {
            return
        }
        trackEvent(.view)
    }
     
    private func trackFilterPanelViewV2() {
        guard UserScopeNoChangeFG.ZYS.loadRecordsOnDemand else {
            return
        }
        trackEvent(.view)
    }
    /// 增加
    func filterPanelControllerDidTapAddNewCondition(_ controller: BTFilterControllerV2) {
        trackEvent(.click(.add))
        viewModel.makeNewCondtion { [weak self] newCondition in
            guard let newCondition = newCondition else {
                DocsLogger.info("[BTFIlterPanelManager] makeNewCondtion newCondition is nil")
                return
            }
            
            self?.updateFilterInfoAndReloadFilterPanelVCV2(action: .addCondition(newCondition))
        }
    }
    /// 删除
    func filterPanelController(_ controller: BTFilterControllerV2, didTapDeleteAt index: Int, conditionModel: BTConditionSelectCellModel) {
        trackEvent(.click(.delete(conditionIndex: index)))
        updateFilterInfoAndReloadFilterPanelVCV2(action: .removeCondition(conditionModel.conditionId))
    }
    
    /// 更新，重新触发请求
    func filterPanelController(_ controller: BTFilterControllerV2, conditionModel: BTConditionSelectCellModel) {
        updateFilterInfoAndReloadFilterPanelVCV2(action: .reloadCondition(conditionModel.conditionId))
    }
    
    /// 更改
    func filterPanelController(_ controller: BTFilterControllerV2,
                               didTapItemAt index: Int,
                               conditionCell: UITableViewCell,
                               conditionSubCell: UICollectionViewCell?,
                               subCellIndex: Int) {
        
        guard let jsData = viewModel.cacheJSData else { return }
        
        trackEvent(.click(.conditionContent(conditionIndex: index, stepIndex: subCellIndex)))
        
        let filterFlowManager = BTFilterManager(viewModel: BTFilterViewModel(filterOptions: jsData.filterOptions,
                                                                             dataService: viewModel.filterFlowService),
                                                coordinator: BTFilterCoordinator(
                                                    hostVC: controller,
                                                    baseContext: baseContext
                                                )
        )
        filterFlowManager.trackInfo = BTFilterEventTrackInfo(hostDocsInfo: hostDocsInfo, baseData: baseData, filterType: "filter")
        self.filterFlowManager = filterFlowManager
        filterFlowManager.ex_showFilterFlowPanel(conditionIndex: index,
                                                 conditionCell: conditionCell,
                                                 subCellIndex: subCellIndex,
                                                 subCell: conditionSubCell,
                                                 filterInfos: jsData.filterInfos,
                                                 filterOptions: jsData.filterOptions,
                                                 linkCellModels: jsData.cellModes,
                                                 hostVC: controller,
                                                 successHanler: { [weak self] newCondition in
            self?.updateFilterInfoAndReloadFilterPanelVCV2(action: .updateCondition(newCondition))
        }, failHandler: nil)
    }
    /// 任一/所有
    func filterPanelController(_ controller: BTFilterControllerV2,
                               didTapConjuction button: BTConditionSelectButton) {
        
        let result = viewModel.getConjuctionSelectedModels()
        let popSource = UDActionSheetSource(sourceView: button,
                                            sourceRect: button.bounds,
                                            preferredContentWidth: 84,
                                            arrowDirection: [.down, .up])
        let pageInfo = PoppverPageInfo(title: BundleI18n.SKResource.Bitable_SingleOption_MeetConditionTitle_Mobile,
                                       dataList: result.models,
                                       defaultTypeIndex: result.selectedIndex,
                                       popSource: popSource,
                                       hostVC: controller)
        var vc: BTPanelController?
        
        let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
            guard let self = self, let itemId = id else { return }
            let index = Int(itemId) ?? 0
            self.handleSelectConjuctionV2(at: index)
            // 关闭当前选择面板
            vc?.dismiss(animated: true)
        }
        
        
        var index = -1
        let datas = result.models.map {
            index = index + 1
            return BTCommonDataItem(id: String(index),
                                    selectable: false,
                                    selectCallback: selectCallback,
                                    leftIcon: .init(image: result.selectedIndex == index ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                                    size: CGSize(width: 20, height: 20)),
                                    mainTitle: .init(text: $0.title))
        }
        vc = BTPanelController(title: BundleI18n.SKResource.Bitable_SingleOption_MeetConditionTitle_Mobile,
                               data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "filter",
                                                                                  items: datas)]),
                               delegate: nil,
                               hostVC: controller, baseContext: baseContext)
        vc?.setCaptureAllowed(true)
        vc?.automaticallyAdjustsPreferredContentSize = false
        guard let vc = vc else { return }
        
        if controller.isMyWindowRegularSize() && SKDisplay.pad {
            BTNavigator.presentActionSheetPage(with: pageInfo) { [weak self] index in
                self?.handleSelectConjuctionV2(at: index)
            }
        } else {
            BTNavigator.presentSKPanelVCEmbedInNav(vc, from: UIViewController.docs.topMost(of: controller) ?? controller)
        }
    }
    
}
