//
//  BTSortPanelManager.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/22.
//  


import SKFoundation
import SKUIKit
import SKResource
import SKCommon
import UIKit
import EENavigator
import UniverseDesignToast
import UniverseDesignActionPanel

struct PoppverPageInfo {
    var title: String
    var dataList: [BTConjuctionSelectedModel]
    var defaultTypeIndex: Int
    var popSource: UDActionSheetSource
    var hostVC: UIViewController
}


final class BTSortPanelManager {
    
    private var viewModel: BTSortPanelViewModel
    
    private weak var sortPanelVC: BTSortPanelController?
    
    private weak var sortPanelVCV2: BTSortControllerV2?
    
    private var changingSortInfo: BTSortData.SortFieldInfo?
    // 排序点击应用
    var sortApplyClick: (() -> Void)?
    
    var hostDocsInfo: DocsInfo?
    
    private var baseData: BTBaseData
    
    private let baseContext: BaseContext
    
    init(baseData: BTBaseData, jsService: SKExecJSFuncService, baseContext: BaseContext, callback: String) {
        self.baseData = baseData
        self.baseContext  = baseContext
        let sortPanelService = BTSortPanelDataService(baseData: baseData, jsService: jsService)
        self.viewModel = BTSortPanelViewModel(dataService: sortPanelService, callback: callback)
    }
    
    func getSortController() -> BTSortControllerV2 {
        /// 获取排序Controller
        if let vc = self.sortPanelVCV2 {
            return vc
        } else {
            let sortVC = BTSortControllerV2(model: BTSortPanelModel())
            sortVC.delegate = self
            self.sortPanelVCV2 = sortVC
            return sortVC
        }
    }
    
    func showSortPanelIfCan(from hostVC: UIViewController) {
        viewModel.getSortModel { [weak self] model in
            guard let model = model else {
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Error_SyetemErrorCommonTips_Mobile, on: hostVC.view)
                return
            }
            self?.showSortPanel(model: model, hostVC: hostVC)
        }
    }
    
    func updateSortPanelIfNeed() {
        guard sortPanelVC != nil else { return }
        viewModel.getSortModel { [weak self] model in
            guard let model = model else { return }
            self?.sortPanelVC?.updateModel(model)
        }
    }
    
    func updateSortPanelIfNeedV2() {
        guard sortPanelVCV2 != nil else { return }
        viewModel.getSortModel { [weak self] model in
            guard let model = model else { return }
            self?.sortPanelVCV2?.updateModel(model)
        }
    }
    
    func closeSortPanel() {
        sortPanelVC?.dismiss(animated: false)
    }
    
    func closeSortPanelByAction() {
        viewModel.notifyClose()
        sortPanelVC?.dismiss(animated: true)
    }
    
    private func showSortPanel(model: BTSortPanelModel, hostVC: UIViewController) {
        trackEvent(.view)
        let sortPanelVC = BTSortPanelController(model: model, shouldShowDragBar: !BTNavigator.isReularSize(hostVC))
        sortPanelVC.delegate = self
        self.sortPanelVC = sortPanelVC
        BTNavigator.presentDraggableVCEmbedInNav(sortPanelVC, from: hostVC)
    }
    
    private func updateSortInfoAndReloadSortPanelVC(action: BTSortPanelViewModel.UpdateSortInfoAction) {
        viewModel.updateSortInfos(action: action) { [weak self] model in
            guard let self = self, let model = model else {
                if let view = self?.sortPanelVC?.view {
                    UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Error_SyetemErrorCommonTips_Mobile, on: view)
                }
                return
            }
            var scrollToIndex: Int?
            switch action {
            case .apply:
                self.closeSortPanelByAction()
                return
            case .addSortInfo:
                scrollToIndex = model.conditions.count > 0 ? model.conditions.count - 1 : nil
            default: break
            }
            self.sortPanelVC?.updateModel(model, scrollToConditionAt: scrollToIndex)
        }
    }
    
    private func updateSortInfoAndReloadSortPanelVCV2(action: BTSortPanelViewModel.UpdateSortInfoAction) {
        viewModel.updateSortInfos(action: action) { [weak self] model in
            guard let self = self, let model = model else {
                if let view = self?.sortPanelVCV2?.view {
                    UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Error_SyetemErrorCommonTips_Mobile, on: view)
                }
                return
            }
            var scrollToIndex: Int?
            switch action {
            case .apply:
                self.closeSortPanelByAction()
                return
            case .addSortInfo:
                scrollToIndex = model.conditions.count > 0 ? model.conditions.count - 1 : nil
            default: break
            }
            self.sortPanelVCV2?.updateModel(model, scrollToConditionAt: scrollToIndex)
        }
    }
}

extension BTSortPanelManager: BTSortPanelControllerDelegate {
    
    func sortPanelControllerDidTapDone(_ controller: BTSortPanelController) {
        updateSortInfoAndReloadSortPanelVC(action: .apply)
        trackEvent(.click(.confirm))
    }
    
    func sortPanelControllerDidTapClose(_ controller: BTSortPanelController) {
        self.closeSortPanelByAction()
    }
    
    func sortPanelControllerDidTapAddNewCondition(_ controller: BTSortPanelController) {
        guard let newSortInfo = viewModel.getAddNewInfo() else {
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Field_SortConditionMaxError_Toast_Mobile, on: controller.view)
            return
        }
        trackEvent(.click(.add))
        updateSortInfoAndReloadSortPanelVC(action: .addSortInfo(newSortInfo))
    }
    
    func sortPanelController(_ controller: BTSortPanelController, didChange autoSort: Bool) {
        trackEvent(.click(.autoSort(value: autoSort)))
        updateSortInfoAndReloadSortPanelVC(action: .updateAutoSort(autoSort))
    }
    
    func sortPanelController(_ controller: BTSortPanelController,
                             didTapDeleteAt index: Int,
                             conditionModel: BTConditionSelectCellModel) {
        trackEvent(.click(.delete(conditionIndex: index)))
        updateSortInfoAndReloadSortPanelVC(action: .removeSortInfo(conditionModel.conditionId))
    }
    
    func sortPanelController(_ controller: BTSortPanelController,
                             didTapItemAt index: Int,
                             conditionCell: UITableViewCell,
                             conditionSubCell: UICollectionViewCell?,
                             subCellIndex: Int) {
        
        trackEvent(.click(.conditionContent(conditionIndex: index, stepIndex: subCellIndex)))
        guard let sortInfo = viewModel.getSortInfo(at: index),
              let sortOption = viewModel.getSortOption(by: sortInfo.fieldId) else {
            return
        }
        changingSortInfo = sortInfo
        switch subCellIndex {
        case 0:
            let result = viewModel.getFieldCommonListData(with: index)
            presentFieldCommonDataList(from: controller, datas: result.datas, selectedIndex: result.selectedIndex)
        case 1:
            // 排序
            var vc: BTPanelController?
            
            let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
                guard let self = self, let itemId = id else { return }
                let index = Int(itemId) ?? 0
                self.handleSelectSortInfoDesc(at: index)
                // 关闭当前选择面板
                vc?.dismiss(animated: true)
            }
            
            
            var index = -1
            let selectedIndex = sortOption.orders.firstIndex(where: { $0.desc == sortInfo.desc }) ?? 0
            let datas = sortOption.orders.map {
                index = index + 1
                return BTCommonDataItem(id: String(index),
                                        selectable: false,
                                        selectCallback: selectCallback,
                                        leftIcon: .init(image: selectedIndex == index ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                                        size: CGSize(width: 20, height: 20)),
                                        mainTitle: .init(text: $0.text))
            }
            
            let dataList = sortOption.orders.map {
                return BTConjuctionSelectedModel(title: $0.text)
            }
            
            vc = BTPanelController(title: BundleI18n.SKResource.Bitable_Record_SetSortMethod,
                                   data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "sortMode",
                                                                                      items: datas)]),
                                   delegate: nil,
                                   hostVC: controller, baseContext: baseContext)
            vc?.setCaptureAllowed(true)
            vc?.automaticallyAdjustsPreferredContentSize = false
            guard let vc = vc else { return }
            
            
            let sourceView = conditionSubCell ?? conditionCell
            let popSource = UDActionSheetSource(sourceView: sourceView,
                                                sourceRect: sourceView.bounds,
                                                arrowDirection: [.down, .up])
            let pageInfo = PoppverPageInfo(title: BundleI18n.SKResource.Bitable_Record_SetSortMethod,
                                           dataList: dataList,
                                           defaultTypeIndex: selectedIndex,
                                           popSource: popSource,
                                           hostVC: controller)
            if controller.isMyWindowRegularSize() && SKDisplay.pad {
                BTNavigator.presentActionSheetPage(with: pageInfo,
                                                   didSelectedHandler: { [weak self] index in
                    self?.handleSelectSortInfoDesc(at: index)
                }, didCancelHandelr: { [weak self] in
                    self?.trackHalfWayEvent(.cancel(.sort))
                })
            } else {
                BTNavigator.presentSKPanelVCEmbedInNav(vc, from: UIViewController.docs.topMost(of: controller) ?? controller)
            }
        default: break
        }
    }
    
    private func handleSelectSortInfoDesc(at index: Int) {
        trackHalfWayEvent(.inputArea(.sort))
        guard let sortInfo = changingSortInfo,
              let sortOption = viewModel.getSortOption(by: sortInfo.fieldId) else {
            return
        }
        let desc = sortOption.orders[index].desc
        if desc == sortInfo.desc {
            return
        }
        var newSortInfo = sortInfo
        newSortInfo.desc = desc
        updateSortInfoAndReloadSortPanelVC(action: .updateSortInfo(original: sortInfo, new: newSortInfo))
    }
}

extension BTSortPanelManager: BTSortPanelControllerDelegateV2 {
    
    func sortControllerWillShow(_ controller: BTSortControllerV2) {
        trackEvent(.view)
        viewModel.getSortModel { [weak self] model in
            if let model = model {
                self?.sortPanelVCV2?.updateModel(model)
            } else {
                DocsLogger.warning("[BTSortPanelManager] getSortModel empty")
            }
        }
    }
    
    func sortPanelControllerDidTapDone(_ controller: BTSortControllerV2) {
        updateSortInfoAndReloadSortPanelVCV2(action: .apply)
        sortApplyClick?()
        trackEvent(.click(.confirm))
    }
    
    func sortPanelControllerDidTapClose(_ controller: BTSortControllerV2) {
        self.closeSortPanelByAction()
    }
    
    func sortPanelControllerDidTapAddNewCondition(_ controller: BTSortControllerV2) {
        guard let newSortInfo = viewModel.getAddNewInfo() else {
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Field_SortConditionMaxError_Toast_Mobile, on: controller.view)
            return
        }
        trackEvent(.click(.add))
        updateSortInfoAndReloadSortPanelVCV2(action: .addSortInfo(newSortInfo))
    }
    
    func sortPanelController(_ controller: BTSortControllerV2, didChange autoSort: Bool) {
        trackEvent(.click(.autoSort(value: autoSort)))
        updateSortInfoAndReloadSortPanelVCV2(action: .updateAutoSort(autoSort))
    }
    
    func sortPanelController(_ controller: BTSortControllerV2,
                             didTapDeleteAt index: Int,
                             conditionModel: BTConditionSelectCellModel) {
        trackEvent(.click(.delete(conditionIndex: index)))
        updateSortInfoAndReloadSortPanelVCV2(action: .removeSortInfo(conditionModel.conditionId))
    }
    
    func sortPanelController(_ controller: BTSortControllerV2,
                             didTapItemAt index: Int,
                             conditionCell: UITableViewCell,
                             conditionSubCell: UICollectionViewCell?,
                             subCellIndex: Int) {
        
        trackEvent(.click(.conditionContent(conditionIndex: index, stepIndex: subCellIndex)))
        guard let sortInfo = viewModel.getSortInfo(at: index),
              let sortOption = viewModel.getSortOption(by: sortInfo.fieldId) else {
            return
        }
        changingSortInfo = sortInfo
        switch subCellIndex {
        case 0:
            let result = viewModel.getFieldCommonListData(with: index)
            presentFieldCommonDataList(from: controller, datas: result.datas, selectedIndex: result.selectedIndex)
        case 1:
            // 排序
            var vc: BTPanelController?
            
            let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
                guard let self = self, let itemId = id else { return }
                let index = Int(itemId) ?? 0
                self.handleSelectSortInfoDescV2(at: index)
                // 关闭当前选择面板
                vc?.dismiss(animated: true)
            }
            
            
            var index = -1
            let selectedIndex = sortOption.orders.firstIndex(where: { $0.desc == sortInfo.desc }) ?? 0
            let datas = sortOption.orders.map {
                index = index + 1
                return BTCommonDataItem(id: String(index),
                                        selectable: false,
                                        selectCallback: selectCallback,
                                        leftIcon: .init(image: selectedIndex == index ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                                        size: CGSize(width: 20, height: 20)),
                                        mainTitle: .init(text: $0.text))
            }
            
            let dataList = sortOption.orders.map {
                return BTConjuctionSelectedModel(title: $0.text)
            }
            
            vc = BTPanelController(title: BundleI18n.SKResource.Bitable_Record_SetSortMethod,
                                   data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "sortMode",
                                                                                      items: datas)]),
                                   delegate: nil,
                                   hostVC: controller, baseContext: baseContext)
            vc?.setCaptureAllowed(true)
            vc?.automaticallyAdjustsPreferredContentSize = false
            guard let vc = vc else { return }
            
            
            let sourceView = conditionSubCell ?? conditionCell
            let popSource = UDActionSheetSource(sourceView: sourceView,
                                                sourceRect: sourceView.bounds,
                                                arrowDirection: [.down, .up])
            let pageInfo = PoppverPageInfo(title: BundleI18n.SKResource.Bitable_Record_SetSortMethod,
                                           dataList: dataList,
                                           defaultTypeIndex: selectedIndex,
                                           popSource: popSource,
                                           hostVC: controller)
            if controller.isMyWindowRegularSize() && SKDisplay.pad {
                BTNavigator.presentActionSheetPage(with: pageInfo,
                                                   didSelectedHandler: { [weak self] index in
                    self?.handleSelectSortInfoDescV2(at: index)
                }, didCancelHandelr: { [weak self] in
                    self?.trackHalfWayEvent(.cancel(.sort))
                })
            } else {
                BTNavigator.presentSKPanelVCEmbedInNav(vc, from: UIViewController.docs.topMost(of: controller) ?? controller)
            }
        default: break
        }
    }
    
    private func handleSelectSortInfoDescV2(at index: Int) {
        trackHalfWayEvent(.inputArea(.sort))
        guard let sortInfo = changingSortInfo,
              let sortOption = viewModel.getSortOption(by: sortInfo.fieldId) else {
            return
        }
        let desc = sortOption.orders[index].desc
        if desc == sortInfo.desc {
            DocsLogger.info("[BTSortPanelManager] sortInfo desc is same")
            return
        }
        var newSortInfo = sortInfo
        newSortInfo.desc = desc
        updateSortInfoAndReloadSortPanelVCV2(action: .updateSortInfo(original: sortInfo, new: newSortInfo))
    }
}

extension BTSortPanelManager: BTFieldCommonDataListDelegate {
    
    func presentFieldCommonDataList(from hostVC: UIViewController, datas: [BTFieldCommonData], selectedIndex: Int) {
        let selectedIndexPath = IndexPath(item: selectedIndex, section: 0)
        let listVC = BTFieldCommonDataListController(data: datas,
                                                     title: BundleI18n.SKResource.Bitable_Relation_SelectField_Mobile,
                                                     action: "SortFieldList",
                                                     shouldShowDragBar: false,
                                                     shouldShowDoneButton: true,
                                                     lastSelectedIndexPath: selectedIndexPath)
        listVC.delegate = self
        listVC.supportedInterfaceOrientationsSetByOutside = .portrait
        BTNavigator.presentDraggableVCEmbedInNav(listVC, from: hostVC)
    }
    
    func didSelectedItem(_ item: BTFieldCommonData,
                         relatedItemId: String,
                         relatedView: UIView?,
                         action: String,
                         viewController: UIViewController,
                         sourceView: UIView? = nil) {
        trackHalfWayEvent(.inputArea(.field))
        viewController.dismiss(animated: true)
        guard let sortInfo = changingSortInfo,
              sortInfo.fieldId != item.id else {
            return
        }
        let newSortInfo = BTSortData.SortFieldInfo(fieldId: item.id, desc: false)
        updateSortInfoAndReloadSortPanelVCV2(action: .updateSortInfo(original: sortInfo, new: newSortInfo))
    }
    
    func didClickClose(relatedItemId: String, action: String) {
        trackHalfWayEvent(.cancel(.field))
    }
}


// MARK: - Event Track
extension BTSortPanelManager {
    
    enum PanelEventType {
        enum ClickEventType {
            case add
            case conditionContent(conditionIndex: Int, stepIndex: Int)
            case delete(conditionIndex: Int)
            case autoSort(value: Bool)
            case confirm
        }
        
        case view
        case click(ClickEventType)
    }
    
    func trackEvent(_ event: PanelEventType) {
        var commonParams = BTEventParamsGenerator.createCommonParams(by: hostDocsInfo,
                                                                     baseData: baseData)
        if let type = BTGlobalTableInfo.currentViewInfoForBase(baseData.baseId)?.gridViewLayoutType {
            commonParams[BTTableLayoutSettings.ViewType.trackKey] = type.trackValue
            if UserScopeNoChangeFG.XM.nativeCardViewEnable {
                commonParams.merge(other: CardViewConstant.commonParams)
            }
        } else {
            commonParams[BTTableLayoutSettings.ViewType.trackKey] = BTTableLayoutSettings.ViewType.classic.trackValue
        }
        switch event {
        case .view:
            commonParams["sort_count"] = "\(viewModel.cacheJSData?.sortInfo.count ?? 0)"
            commonParams["is_auto_sort"] = "\(viewModel.cacheJSData?.autoSort ?? false)"
            var isFieldUnreadable = viewModel.cacheJSData?.fieldOptions.contains(where: { option in
                guard let sortInfo = viewModel.cacheJSData?.sortInfo else { return false }
                var hasFieldUnreadable = false
                for info in sortInfo where info.fieldId == option.id {
                    hasFieldUnreadable = option.invalidType == .fieldUnreadable
                    if hasFieldUnreadable {
                        break
                    }
                }
                return hasFieldUnreadable
            })
            commonParams["is_premium_limited"] = DocsTracker.toString(value: isFieldUnreadable)
            DocsTracker.newLog(enumEvent: .bitableSortSetView, parameters: commonParams)
        case .click(let clickEvent):
            updateParamsByClickEvent(clickEvent, params: &commonParams)
            DocsTracker.newLog(enumEvent: .bitableSortSetClick, parameters: commonParams)
        }
    }
    
    private func updateParamsByClickEvent(_ clickEvent: PanelEventType.ClickEventType,
                                          params: inout [String: String]) {
        params["target"] = "none"
        switch clickEvent {
        case .add:
            params["click"] = "add_click"
        case let .delete(conditionIndex):
            let condition = viewModel.getSortInfo(at: conditionIndex)
            let field = viewModel.getSortOption(by: condition?.fieldId ?? "")
            var stringForTrack = field?.compositeType.fieldTrackName ?? "none"
            params["click"] = "delete_click"
            params["field_type"] = stringForTrack
        case let .conditionContent(conditionIndex, stepIndex):
            let condition = viewModel.getSortInfo(at: conditionIndex)
            let field = viewModel.getSortOption(by: condition?.fieldId ?? "")
            var stringForTrack = field?.compositeType.fieldTrackName ?? "none"
            switch stepIndex {
            case 0: //field
                params["click"] = "fieldClick"
                params["field_type"] = stringForTrack
            case 1: // rule
                params["click"] = "group_rule_click"
                params["field_type"] = stringForTrack
                params["rule"] = (condition?.desc ?? false) ? "option_inverse_order" : "option_order"
            default: break
            }
        case .autoSort(let value):
            params["click"] = "auto_sort"
            params["status"] = value ? "open" : "close"
        case .confirm:
            params["click"] = "confirm"
        }
    }
    
    enum HalfWayEventType {
        enum SettingType: String {
            case field
            case sort
        }
        case cancel(SettingType)
        case inputArea(SettingType)
        
        var trackValue: (click: String, type: SettingType) {
            switch self {
            case .cancel(let type): return ("cancel", type)
            case .inputArea(let type): return ("input_area", type)
            }
        }
    }
    /// 排序各种选择面板相关埋点
    func trackHalfWayEvent(_ event: HalfWayEventType) {
        var commonParams = BTEventParamsGenerator.createCommonParams(by: hostDocsInfo,
                                                                     baseData: baseData)
        commonParams["target"] = "none"
        let trackValue = event.trackValue
        commonParams["click"] = trackValue.click
        commonParams["setting_type"] = trackValue.type.rawValue
        DocsTracker.newLog(enumEvent: .bitableSortSetHalfwayClick, parameters: commonParams)
    }
}
