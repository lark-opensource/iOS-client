//
//  BTFieldEditController+LinkField.swift
//  SKBitable
//
//  Created by ZhangYuanping on 2022/7/3.
//


import SKFoundation
import SKCommon
import SKResource
import EENavigator
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import SKUIKit
import UIKit

extension BTFieldEditController {
    
    func configLinkFieldUI(view: UIView, viewManager: BTFieldEditViewManager) {
        let headerHeight = viewManager.calLinkTableHeaderHeight()
        currentTableView.tableHeaderView?.frame.size.height = 176 + headerHeight
        specialSetView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(headerHeight)
        }
        let conditions = viewModel.linkTableFilterInfo?.conditions ?? []
        var conditionContainNotSupport = viewModel.cellViewDataManager?.isContainNotSupportField(in: conditions) ?? false
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if viewModel.isDynamicTablePartialDenied {
                conditionContainNotSupport = true
            }
        }
        let linkTableFooterView = viewManager.getLinkTableFooterView(
            filterConditionCount: conditions.count,
            conditionContainNotSupport: conditionContainNotSupport,
            isLinkAllRecord: viewModel.fieldEditModel.isLinkAllRecord,
            canAddMultiViewSelected: viewModel.fieldEditModel.fieldProperty.multiple
        )
        let footerHeight = viewManager.calLinkTableFooterHeight()
        linkTableFooterView.frame.size.height = footerHeight
        linkTableFooterView.snp.makeConstraints { make in
            make.height.equalTo(footerHeight).priority(.high)
        }
        footerView.activeLinkFooter(linkTableFooterView)
        updateSaveButtonForLinkField()
    }
    
    func updateSaveButtonForLinkField() {
        let result = viewModel.verifyLinkFieldCommitData()
        saveButton.setTitleColor(result.isValid ? UDColor.primaryContentDefault : UDColor.textDisabled, for: .normal)
    }
    
    func configLinkTableFilterConditionCell(indexPath: IndexPath,
                                          cell: BTConditionSelectCell) -> UITableViewCell {
        guard viewModel.linkFieldFilterCellModels.count > 0 else { return UITableViewCell() }
        let model = viewModel.linkFieldFilterCellModels[indexPath.row]
        let isShowDelete = model.fieldErrorType != .fieldNotSupport && viewModel.linkTableFilterInfo?.conditions.count != 1
        var cellModel = BTConditionSelectCellModel(conditionId: model.conditionId,
                                                   title: BTConditionSelectCellModel.titleWithIndex(indexPath.row + 1),
                                                   buttonModels: model.conditionButtonModels,
                                                   isShowDelete: isShowDelete,
                                                   isWarningVisible: model.fieldErrorType != nil,
                                                   warningText: model.fieldErrorType?.warnMessage ?? "")
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            // 关联部分无权限，不允许操作
            if viewModel.isLinkTablePartialDenied {
                cellModel.isDisable = true
            }
        }
        cell.configModel(cellModel)
        cell.isFirstCell = indexPath.row == 0
        cell.delegate = self
        cellHeight[indexPath.row] = cell.relayout()
        return cell
    }
    
    private func parseFilterValues<T>(values: [Any]?) -> [T] {
        return values as? [T] ?? []
    }
    
    private func getFilterOperator(condition: BTFilterCondition) -> BTFilterOptions.Field.RuleOperator? {
        let ruleOperator = viewModel.commonData.filterOptions
            .fieldOptions.first(where: { $0.id == condition.fieldId })?
            .operators.first(where: { $0.value == condition.operator })
        return ruleOperator
    }
    
    /// 点击修改关联字段关联数据表范围
    func didClickChooseRelatedTableRange(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        if viewModel.isLinkTablePartialDenied {
            // 关联数据表部分无权限，无法修改关联范围
            UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Relation_NoPermToEditFilterConditionDueToInaccessibleReferenceTable_Tooltip, on: self.view)
            return
        }
        if !button.enable {
            UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Relation_SelectLinkTableFirstToast_Mobile, on: self.view)
            return
        }
        
        var vc: BTPanelController?
        
        let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
            guard let self = self, let itemId = id else { return }
            let index = Int(itemId) ?? 0
            self.didClickItem(viewIdentify: BTFieldEditPageAction.linkTableFilterTypeSelect.rawValue, index: index)
            // 关闭当前选择面板
            vc?.dismiss(animated: true)
        }
        let selectedIndex = viewModel.fieldEditModel.isLinkAllRecord ? 0 : 1
        
        let dataList = [
            BTCommonDataItem(id: "0",
                             selectable: false,
                             selectCallback: selectCallback,
                             leftIcon: .init(image: selectedIndex == 0 ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                             size: CGSize(width: 20, height: 20)),
                             mainTitle: .init(text: BundleI18n.SKResource.Bitable_Relation_AllRecord)),
            BTCommonDataItem(id: "1",
                             selectable: false,
                             selectCallback: selectCallback,
                             leftIcon: .init(image: selectedIndex == 1 ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                             size: CGSize(width: 20, height: 20)),
                             mainTitle: .init(text: BundleI18n.SKResource.Bitable_Relation_SpecifiedRecord))
        ]
        
        vc = BTPanelController(title: BundleI18n.SKResource.Bitable_Relation_AvailableDataScope,
                               data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "linkRange",
                                                                                      items: dataList)]),
                               delegate: nil,
                               hostVC: self,
                               baseContext: baseContext)
        vc?.automaticallyAdjustsPreferredContentSize = false
        vc?.setCaptureAllowed(true)
        
        safePresent { [weak self] in
            guard let self = self, let vc = vc else { return }
            BTNavigator.presentSKPanelVCEmbedInNav(vc, from: UIViewController.docs.topMost(of: self) ?? self)
        }
    }
    
    /// 选择关联所有/指定范围
    func didChangeLinkTableRange(isLinkAllRecord: Bool) {
        viewModel.fieldEditModel.isLinkAllRecord = isLinkAllRecord
        let filterCount = viewModel.linkTableFilterInfo?.conditions.count ?? 0
        if !viewModel.fieldEditModel.isLinkAllRecord && filterCount == 0 {
            // 选择关联指定范围且当前无筛选条件时，主动添加一条
            checkAndAddLinkFieldFilterOption()
        } else {
            updateUI(fieldEditModel: viewModel.fieldEditModel)
        }
    }
    
    /// 点击关联筛选条件组合方式按钮
    func didClickLinkFieldFilterConjunctionButton(button: UIButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        let conjuctionValue = viewModel.linkTableFilterInfo?.conjunction ?? ""
        let datas = BTFilterHelper.getConjunctionModels(by: viewModel.commonData.filterOptions,
                                                        conjuctionValue: conjuctionValue)
        presentConjuctionPanel(conjuctionBtn: button,
                               datas: datas.models,
                               selectedIndex: datas.selectedIndex,
                               pageAction: .linkTableFilterConjunctionSelect)
    }
    
    func didChangeLinkFieldFilterConjunction(_ conjunction: BTConjunctionType) {
        viewModel.linkTableFilterInfo?.conjunction = conjunction.rawValue
        updateUI(fieldEditModel: viewModel.fieldEditModel)
    }
    
    func didClickAddLinkTableFilterOption(button: BTAddButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if viewModel.isLinkTablePartialDenied {
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceField_Tooltip, on: self.view)
                return
            }
        }
        if viewModel.linkTableFilterInfo?.conditions.count ?? 0 >= 5 {
            // 最多可添加 5 个条件
            UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Relation_ConditionNumLimit("5"), on: self.view)
            return
        }
        if !UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
        if viewModel.linkFieldFilterCellModels.contains(where: { $0.fieldErrorType == .fieldNotSupport }) {
            UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Mobile_Filter_UnsupportedField, on: self.view)
            return
        }
        }
        
        checkAndAddLinkFieldFilterOption()
        let trackString = self.viewModel.fieldEditModel.fieldTrackName
        delegate?.trackEditViewEvent(eventType: .bitableRelationFieldModifyViewClick,
                                     params: ["click": "add_condition",
                                              "field_type": trackString,
                                              "target": "none"],
                                     fieldEditModel: viewModel.fieldEditModel)
    }
    
    /// 检查关联表并添加关联字段筛选条件
    func checkAndAddLinkFieldFilterOption() {
        if viewModel.fieldEditModel.fieldProperty.tableId != viewModel.oldFieldEditModel.fieldProperty.tableId {
            // 选择了新的关联表，更新 FilterManger
            self.setupFilterManager()
            filterManager?.viewModel.dataService.getFieldFilterOptions().subscribe {[weak self]  event in
                guard let self = self else { return }
                switch event {
                case .success(let options):
                    DocsLogger.btInfo("[LinkField] tableId changed, get new FieldFilterOptions")
                    self.viewModel.commonData.filterOptions = options
                    // 更新 FilterManger 的 Options 数据
                    self.setupFilterManager()
                    self.addLinkTableFilterOption()
                case .error(let error):
                    DocsLogger.btError("[LinkField] tableId changed, get FieldFilterOptions is nil, error: \(error)")
                    return
                }
            }.disposed(by: self.bag)
        } else {
            addLinkTableFilterOption()
        }
    }
    
    private func addLinkTableFilterOption() {
        guard let field = viewModel.commonData.filterOptions.fieldOptions.first else {
            DocsLogger.btError("[LinkField] No FieldOptions for add new options")
            return
        }
        let ids = viewModel.linkTableFilterInfo?.conditions.compactMap { $0.conditionId }
        let args = BTGetBitableCommonDataArgs(type: .getNewConditionIds,
                                              tableID: viewModel.fieldEditModel.tableId,
                                              viewID: viewModel.fieldEditModel.viewId,
                                              fieldID: viewModel.fieldEditModel.fieldId,
                                              extraParams: ["total": 1,
                                                            "ids": ids ?? []])
        dataService?.getBitableCommonData(args: args) { [weak self] result, error in
            guard let self = self, error == nil,
                  let conditionIds = result as? [String],
                  let conditionId = conditionIds.first else {
                DocsLogger.btError("[LinkField] getConditionId failed")
                return
            }
            let operate = field.operators.first?.value ?? BTFilterOperator.defaultValue
            var condition = BTFilterCondition(conditionId: conditionId, fieldId: field.id,
                                              fieldType: field.compositeType.type.rawValue,
                                              operator: operate)
            if field.compositeType.uiType.rawValue == BTFieldUIType.checkbox.rawValue {
                condition.value = [false]
            }
            if self.viewModel.linkTableFilterInfo == nil || self.viewModel.linkTableFilterInfo?.conditions.count == 0 {
                let filterInfo = BTFilterInfos(conjunction: BTConjunctionType.And.rawValue, conditions: [condition])
                self.viewModel.linkTableFilterInfo = filterInfo
            } else {
                self.viewModel.linkTableFilterInfo?.conditions.append(condition)
            }
            self.updateUI(fieldEditModel: self.viewModel.fieldEditModel)
            self.addCellModel(condition: condition)
        }
    }
    
    func deleteFilterCondition(index: Int) {
        viewModel.linkTableFilterInfo?.conditions.remove(at: index)
        updateUI(fieldEditModel: viewModel.fieldEditModel)
        //需要更新指定的cell
        viewModel.linkFieldFilterCellModels.remove(at: index)
        updateCellModels(viewModel.linkFieldFilterCellModels)
        let stringForTrack = viewModel.fieldEditModel.fieldTrackName
        delegate?.trackEditViewEvent(eventType: .bitableRelationFieldModifyViewClick,
                                     params: ["click": "delete_condition",
                                              "field_type": stringForTrack,
                                              "target": "none"],
                                     fieldEditModel: viewModel.fieldEditModel)
    }
    
    
    func showFilterPanel(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        resignInputFirstResponder()
        editingFieldCell = cell
        editingFieldCellIndex = currentTableView.indexPath(for: cell)?.item
        guard let conditionIndex = editingFieldCellIndex else { return }
        guard let filterInfo = viewModel.linkTableFilterInfo else { return }
        self.filterManager?.ex_showFilterFlowPanel(conditionIndex: conditionIndex,
                                                   conditionCell: cell,
                                                   subCellIndex: index,
                                                   subCell: subCell,
                                                   filterInfos: filterInfo,
                                                   filterOptions: viewModel.commonData.filterOptions,
                                                   linkCellModels: viewModel.linkFieldFilterCellModels,
                                                   hostVC: self,
                                                   successHanler: { [weak self] newFilterCondition in
            guard let self = self else { return }
            DocsLogger.debug("==bitable== [LinkField] update filter by panel \(newFilterCondition.toDict())")
            self.viewModel.linkTableFilterInfo?.conditions[conditionIndex] = newFilterCondition
            //需要更新指定的cell
            self.reloadCellModels([newFilterCondition], isReloadAll: false)
        },
                                                failHandler: nil)
    }
    
    
    func setupFilterManager() {
        guard let jsService = dataService?.jsFuncService else { return }
        let baseData = BTBaseData(baseId: viewModel.fieldEditModel.fieldProperty.baseId,
                                  tableId: viewModel.fieldEditModel.fieldProperty.tableId,
                                  viewId: viewModel.fieldEditModel.viewId)
        let filterDataService = BTFilterDataService(baseData: baseData, jsService: jsService, dataService: dataService)
        let filterViewModel = BTFilterViewModel(filterOptions: viewModel.commonData.filterOptions,
                                                dataService: filterDataService)
        
        let coord = BTFilterCoordinator(hostVC: self, baseContext: baseContext)
        filterManager = BTFilterManager(viewModel: filterViewModel, coordinator: coord)
        viewModel.cellViewDataManager = BTLinkFieldFilterCellViewDataManager(dataService: filterDataService,
                                                                             timeZoneId: viewModel.commonData.filterOptions.timeZone,
                                                                             filterOptions: viewModel.commonData.filterOptions)
        filterManager?.trackInfo = BTFilterEventTrackInfo(hostDocsInfo: viewModel.commonData.hostDocsInfos, baseData: baseData, filterType: "relation")
    }
    
    ///全量更新cell
    func updateCellViewData(scrllToBottom: Bool = false) {
        reloadCellModels(viewModel.linkTableFilterInfo?.conditions ?? [], isReloadAll: true)
    }
    
    ///新增条件model
    func addCellModel(condition: BTFilterCondition) {
        let addCondition: ([BTLinkFieldFilterCellModel]) -> Void = { [weak self] cellDatas in
            guard let self = self else { return }
            self.viewModel.linkFieldFilterCellModels += cellDatas
            self.updateCellModels(self.viewModel.linkFieldFilterCellModels, scrllToBottom: true)
        }
        
        viewModel.cellViewDataManager?.convert(conditions: [condition], responseHandler: { models in
            addCondition(models)
        }, complete: { models in
            addCondition(models)
        })
    }
    
    func didClickRetry(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        //关联字段条件值需要异步加载
        guard viewModel.fieldEditModel.compositeType.classifyType == .link else {
            return
        }
        
        guard let conditions = viewModel.linkTableFilterInfo?.conditions,
              let index = currentTableView.indexPath(for: cell)?.item,
              index >= 0,
              index < conditions.count else {
            return
        }
        
        let disposeCellDatas: ([BTLinkFieldFilterCellModel]) -> Void = { [weak self] cellDatas in
            guard let self = self else { return }
            //返回的只有一个model，需要更新指定的model
            let currentModels = self.viewModel.linkFieldFilterCellModels.compactMap { model -> BTLinkFieldFilterCellModel in
                if model.conditionId == conditions[index].conditionId {
                    return cellDatas.first(where: { $0.conditionId == model.conditionId }) ?? model
                }
                
                return model
            }
            self.updateCellModels(currentModels)
        }
        
        viewModel.cellViewDataManager?.convert(conditions: [conditions[index]],
                                               responseHandler: { models in
            disposeCellDatas(models)
        },
                                               complete: { models in
            disposeCellDatas(models)
        })
    }
    
    ///更新model
    private func reloadCellModels(_ conditions: [BTFilterCondition], isReloadAll: Bool) {
        let reloadCellModel: ([BTLinkFieldFilterCellModel]) -> Void = { [weak self] models in
            guard let self = self else { return }
            //返回的只有一个model，需要更新指定的model
            var currentModels = models
            
            if !isReloadAll {
                currentModels = self.viewModel.linkFieldFilterCellModels.compactMap { model -> BTLinkFieldFilterCellModel in
                    return models.first(where: { $0.conditionId == model.conditionId }) ?? model
                }
            }
            
            if self.viewModel.linkFieldFilterCellModels.isEmpty {
                currentModels = models
            }

            self.updateCellModels(currentModels)
        }
        
        viewModel.cellViewDataManager?.convert(conditions: conditions, responseHandler: { models in
            reloadCellModel(models)
        }, complete: { models in
            reloadCellModel(models)
        })
    }
    
    ///刷新条件cell
    private func updateCellModels(_ models: [BTLinkFieldFilterCellModel], scrllToBottom: Bool = false) {
        viewModel.linkFieldFilterCellModels = models
        currentTableView.reloadData()
        updateSaveButtonForLinkField()
        if scrllToBottom {
            currentTableView.setContentOffset(CGPoint(x: 0, y: CGFloat.greatestFiniteMagnitude), animated: false)
        }
    }
}

extension BTFilterCondition {
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["conditionId"] = self.conditionId
        dict["fieldId"] = self.fieldId
        dict["fieldType"] = self.fieldType
        dict["operator"] = self.operator
        // 注意空值需传 NSNull 才不会被 Swift 字典过滤掉 "value"，前端 JS 需依靠 null 值做判断
        if let values = self.value, !values.isEmpty {
            dict["value"] = values
        } else {
            dict["value"] = NSNull()
        }
        return dict
    }
}

extension BTFilterInfos {
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["conjunction"] = self.conjunction
        var conditions = [[String: Any]]()
        for condition in self.conditions {
            conditions.append(condition.toDict())
        }
        dict["conditions"] = conditions
        return dict
    }
}
