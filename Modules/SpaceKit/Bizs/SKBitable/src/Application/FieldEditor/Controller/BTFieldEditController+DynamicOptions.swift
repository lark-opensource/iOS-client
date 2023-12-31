//
//  BTFieldEditController+DynamicOptions.swift
//  SKBitable
//
//  Created by zoujie on 2022/6/22.
//  swiftlint:disable file_length

import Foundation
import SKUIKit
import SKFoundation
import EENavigator
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignEmpty
import UniverseDesignActionPanel

extension BTFieldEditController {
    ///选项字段级联
    func configDynamicOptionConditionCell(indexPath: IndexPath,
                                          cell: UITableViewCell) -> UITableViewCell {
        guard indexPath.row < dynamicOptionsConditions.count,
              let cell = cell as? BTConditionSelectCell else { return cell }
        let item = dynamicOptionsConditions[indexPath.row]
        let (buttons, errorMsg) = viewModel.configConditionButtons(item)
        var cellModel = BTConditionSelectCellModel(conditionId: item.conditionId,
                                                   title: BTConditionSelectCellModel.titleWithIndex(indexPath.row + 1),
                                                   buttonModels: buttons,
                                                   isShowDelete: viewModel.linkTableFilterInfo?.conditions.count != 1,
                                                   isWarningVisible: !errorMsg.isEmpty,
                                                   warningText: errorMsg)
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            // 级联引用字段无权限以 及 新文档且部分无权限操作下，设置为灰色，点击弹toast
            if viewModel.isDynamicFieldDenied || viewModel.isDynamicPartNoPerimission {
                cellModel.isDisable = true
            }
        }
        cell.configModel(cellModel)
        cell.isFirstCell = indexPath.row == 0
        cell.delegate = self
        cellHeight[indexPath.row] = cell.relayout()
        return cell
    }

    func didSelectedDynamicOptionItem(_ item: BTFieldCommonData,
                                      relatedItemId: String,
                                      relatedView: UIView?,
                                      action: BTFieldEditDataListViewAction,
                                      viewController: UIViewController) {
        switch action {
        case .updateDynamicOptionCondition:
            //更新条件规则
            guard let index = editingFieldCellIndex,
                  let cell = editingFieldCell,
                  index < dynamicOptionsConditions.count else {
                return
            }

            dynamicOptionsConditions[index].operator = BTConditionType(rawValue: item.id) ?? .Unkonwn
            currentTableView.reloadData()

            delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                         params: ["click": dynamicOptionsConditions[index].operator.tracingString,
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)

            if !dynamicOptionsConditions[index].operator.hasNotNextValueType {
                didClickSelectCurrentTableFieldButton(button: nil, cell: cell, cellIndex: index)
            } else {
                viewController.dismiss(animated: true)
            }
        case .updateDynamicOptionTargetTableId:
            //更新引用数据表
            viewModel.dynamicOptionRuleTargetTable = item.id
            //清空引用字段
            viewModel.dynamicOptionRuleTargetField = ""
            //清空条件
            dynamicOptionsConditions.removeAll()
            viewModel.getFieldOperators(tableId: item.id,
                                        fieldId: nil,
                                        needUpdate: true,
                                        completion: nil)
            footerView.optionFooter.updateAddButton(enable: true, topMargin: 0)
            viewManager?.updateData(commonData: viewModel.commonData, fieldEditModel: viewModel.fieldEditModel)
            setSaveButtonEnable()
            currentTableView.reloadData()
            viewController.dismiss(animated: true)
        case .updateDynamicOptionTargetFieldId:
            //更新引用字段
            viewModel.dynamicOptionRuleTargetField = item.id
            viewManager?.updateData(commonData: viewModel.commonData, fieldEditModel: viewModel.fieldEditModel)
            setSaveButtonEnable()
            currentTableView.reloadData()
            viewController.dismiss(animated: true)
        case .updateDynamicOptionConditionLinkTableFieldId:
            //更新条件cell中引用表中的字段
            guard let index = editingFieldCellIndex,
                  let cell = editingFieldCell,
                  index < dynamicOptionsConditions.count else {
                return
            }

            dynamicOptionsConditions[index].fieldId = item.id
            let mapItem = viewModel.commonData.linkTableFieldOperators.first(where: { $0.id == item.id })
            dynamicOptionsConditions[index].fieldType = mapItem?.compositeType.type ?? .text
            dynamicOptionsConditions[index].operator = .Unkonwn
            currentTableView.reloadData()
            didClickConditionButton(button: nil, cell: cell, cellIndex: index)
        case .updateDynamicOptionConditionCurrentTableFieldId:
            //更新条件cell中当前表中的字段
            guard let index = editingFieldCellIndex,
                  index < dynamicOptionsConditions.count else {
                return
            }

            dynamicOptionsConditions[index].value = item.id
            currentTableView.reloadData()
            viewController.dismiss(animated: true)
        default:
            break
        }
    }

    ///更改选项数据源类型静态或者级联
    func didClickOptionTypeChooseButton(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        var vc: BTPanelController?
        
        let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
            guard let self = self, let itemId = id else { return }
            let index = Int(itemId) ?? 0
            self.didClickItem(viewIdentify: BTFieldEditPageAction.optionsTypeSelect.rawValue, index: index)
            // 关闭当前选择面板
            vc?.dismiss(animated: true)
        }
        
        let selectedIndex = viewModel.fieldEditModel.fieldProperty.optionsType == .staticOption ? 0 : 1
        
        let dataList = [
            BTCommonDataItem(id: "0",
                             selectable: false,
                             selectCallback: selectCallback,
                             leftIcon: .init(image: selectedIndex == 0 ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                             size: CGSize(width: 20, height: 20),
                                             alignment: BTCommonDataItemIconInfo.ItemIconAlignment.top(offset: 0)),
                             mainTitle: .init(text: BundleI18n.SKResource.Bitable_SingleOption_CustomizeOptionContent),
                             subTitle: .init(text: BundleI18n.SKResource.Bitable_SingleOption_CustomizeOptionContentDesc,
                                             lineNumber: 0)),
            BTCommonDataItem(id: "1",
                             selectable: false,
                             selectCallback: selectCallback,
                             leftIcon: .init(image: selectedIndex == 1 ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                             size: CGSize(width: 20, height: 20),
                                             alignment: BTCommonDataItemIconInfo.ItemIconAlignment.top(offset: 0)),
                             mainTitle: .init(text: BundleI18n.SKResource.Bitable_SingleOption_SubsetFromOtherTable),
                             subTitle: .init(text: BundleI18n.SKResource.Bitable_SingleOption_SubsetFromOtherTableDesc,
                                             lineNumber: 0))
        ]
        
        vc = BTPanelController(title: BundleI18n.SKResource.Bitable_SingleOption_SubsetCondition,
                               data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "optionType",
                                                                                  items: dataList)]),
                               delegate: nil,
                               hostVC: self,
                               baseContext: baseContext)
        vc?.setCaptureAllowed(true)
        vc?.automaticallyAdjustsPreferredContentSize = false
        
        safePresent { [weak self] in
            guard let self = self, let vc = vc else { return }
            BTNavigator.presentSKPanelVCEmbedInNav(vc, from: UIViewController.docs.topMost(of: self) ?? self)
        }
    }

    ///选择级联选项引用的数据表
    func didClickDynamicOptionTableChooseButton(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                     params: ["click": "select_range_table",
                                              "target": "none"],
                                     fieldEditModel: viewModel.fieldEditModel)
        var showHiddenTableFooter = false
        let data = viewModel.commonData.tableNames.compactMap { table -> BTFieldCommonData? in
            guard table.readPerimission else { return nil }
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                if table.isPartialDenied == true {
                    // 只要筛掉了部分无权限的表就展示提示
                    showHiddenTableFooter = true
                    // 部分无权限需要筛选
                    return nil
                }
            }
            let data = BTFieldCommonData(id: table.tableId,
                                         name: table.tableName,
                                         icon: UDIcon.getIconByKey(.sheetBitableOutlined, iconColor: UDColor.iconN1))
            return data
        }

        var selectedIndexPath: IndexPath?
        if let selectedIndex = data.firstIndex(where: { $0.id == viewModel.dynamicOptionRuleTargetTable }) {
            selectedIndexPath = IndexPath(item: selectedIndex, section: 0)
        }

        self.dynamicOptionsShowCommonDataListVC(data: data,
                                                title: BundleI18n.SKResource.Bitable_SingleOption_SelectTargetTable_Mobile,
                                                action: .updateDynamicOptionTargetTableId,
                                                shouldShowDragBar: true,
                                                relatedItemId: "",
                                                relatedView: button,
                                                lastSelectedIndexPath: selectedIndexPath,
                                                showHiddenTableFooter: showHiddenTableFooter)
    }

    ///选择级联选项引用的字段
    func didClickDynamicOptionFieldChooseButton(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                     params: ["click": "select_range_field",
                                              "target": "none"],
                                     fieldEditModel: viewModel.fieldEditModel)
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if viewModel.isDynamicPartNoPerimission {
                // 需要注意的是，设计稿并不是所有场景都要弹toast的，例如此场景
                DocsLogger.info("isDynamicPartNoPerimission cannot click DynamicOptionFieldChooseButton")
                return
            }
        }
        guard viewModel.verifyTargetTable() else {
            DocsLogger.btError("filed edit dynamicOption not selected targetTableId first")
            UDToast.showWarning(with: BundleI18n.SKResource.Bitable_SingleOption_SelectTableThenFieldToast_Mobile, on: self.view)
            return
        }

        let openPanelBlock = { [weak self] in
            guard let self = self else { return }
            let data = self.viewModel.commonData.linkTableFieldOperators.compactMap { field -> BTFieldCommonData? in
                guard field.id != self.viewModel.fieldEditModel.fieldId,
                      field.compositeType.classifyType == .option,
                      field.property.optionsType == .staticOption,
                      !field.isDeniedField else {
                    //过滤自身和非选项类型的字段，不能关联级联类型的字段，还有无权限的字段
                    return nil
                }
                if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                    if field.isPartialDenied == true {
                        // 筛选掉字段挖空的情况
                        return nil
                    }
                }
                let icon = field.compositeType.icon()
                let tableName = self.viewModel.commonData.tableNames.first(where: { $0.tableId == self.viewModel.fieldEditModel.fieldProperty.optionsRule.targetTable })?.tableName ?? ""
                let data = BTFieldCommonData(
                    id: field.id,
                    name: field.name,
                    groupId: tableName,
                    icon: icon,
                    showLighting: field.isSync
                )
                return data
            }

            var selectedIndexPath: IndexPath?
            if let selectedIndex = data.firstIndex(where: { $0.id == self.viewModel.dynamicOptionRuleTargetField }) {
                selectedIndexPath = IndexPath(item: selectedIndex, section: 0)
            }

            self.dynamicOptionsShowCommonDataListVC(data: data,
                                                    title: BundleI18n.SKResource.Bitable_SingleOption_SelectTargetField_Mobile,
                                                    action: .updateDynamicOptionTargetFieldId,
                                                    shouldShowDragBar: true,
                                                    relatedItemId: "",
                                                    relatedView: button,
                                                    lastSelectedIndexPath: selectedIndexPath,
                                                    emptyViewType: .searchFailed,
                                                    emptyViewText: BundleI18n.SKResource.Bitable_SingleOption_NoAvailableField_Mobile)
        }

        viewModel.getFieldOperators(tableId: viewModel.dynamicOptionRuleTargetTable,
                                    fieldId: nil,
                                    needUpdate: viewModel.commonData.linkTableFieldOperators.isEmpty,
                                    completion: {
            openPanelBlock()
        })
    }

    //点击条件组合方式按钮
    func didClickDynamicOptionLinkRelationButton(button: UIButton) {
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            // 级联引用字段无权限以 及 新文档且部分无权限操作下，设置为灰色，点击弹toast
            if viewModel.isDynamicFieldDenied || viewModel.isDynamicPartNoPerimission {
                DocsLogger.info("isDynamicFieldDenied or isDynamicPartNoPerimission toast")
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceTable_Tooltip, on: view)
                return
            }
        }
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        
        let datas = BTConjunctionType.allCases.map {
            BTConjuctionSelectedModel(title: $0.text)
        }
        let conjunction = BTConjunctionType(rawValue: viewModel.dynamicOptionRuleConjunction) ?? .And
        let selectedIndex = (conjunction == .And) ? 0 : 1
        presentConjuctionPanel(conjuctionBtn: button,
                               datas: datas,
                               selectedIndex: selectedIndex,
                               pageAction: .dynamicOptionsConjunctionSelect)
    }
    
    /// 展示所有/任一 面板
    func presentConjuctionPanel(conjuctionBtn: UIButton,
                                datas: [BTConjuctionSelectedModel],
                                selectedIndex: Int,
                                pageAction: BTFieldEditPageAction) {
        let popSource = UDActionSheetSource(sourceView: conjuctionBtn,
                                            sourceRect: conjuctionBtn.bounds,
                                            preferredContentWidth: 84,
                                            arrowDirection: [.down, .up])
        let info = PoppverPageInfo(title: BundleI18n.SKResource.Bitable_SingleOption_MeetConditionTitle_Mobile,
                                   dataList: datas,
                                   defaultTypeIndex: selectedIndex,
                                   popSource: popSource,
                                   hostVC: self)
        var vc: BTPanelController?
        
        let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
            guard let self = self, let itemId = id else { return }
            let index = Int(itemId) ?? 0
            self.didClickItem(viewIdentify: pageAction.rawValue, index: index)
            // 关闭当前选择面板
            vc?.dismiss(animated: true)
        }
        
        
        var index = -1
        let datas = datas.map {
            index = index + 1
            return BTCommonDataItem(id: String(index),
                                    selectable: false,
                                    selectCallback: selectCallback,
                                    leftIcon: .init(image: selectedIndex == index ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                                    size: CGSize(width: 20, height: 20)),
                                    mainTitle: .init(text: $0.title))
        }
        vc = BTPanelController(title: BundleI18n.SKResource.Bitable_SingleOption_MeetConditionTitle_Mobile,
                               data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "conjuction",
                                                                                  items: datas)]),
                               delegate: nil,
                               hostVC: self,
                               baseContext: baseContext)
        vc?.setCaptureAllowed(true)
        guard let vc = vc else { return }
        
        safePresent { [weak self] in
            guard let self = self else { return }
            if self.isMyWindowRegularSize() && SKDisplay.pad {
                BTNavigator.presentActionSheetPage(with: info) { [weak self] index in
                    self?.didClickItem(viewIdentify: pageAction.rawValue,
                                       index: index)
                }
            } else {
                BTNavigator.presentSKPanelVCEmbedInNav(vc, from: UIViewController.docs.topMost(of: self) ?? self)
            }
        }
    }
}

extension BTFieldEditController: BTConditionSelectCellDelegate, BTConditionNoPermissionCellDelegate {
    func didClickDelete(cell: UITableViewCell) {
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if viewModel.fieldEditModel.compositeType.classifyType == .link {
                // 关联
                if viewModel.isLinkTablePartialDenied {
                    DocsLogger.info("isLinkTablePartialDenied toast")
                    UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceTable_Tooltip, on: view)
                    return
                }
            } else {
                // 级联引用字段无权限以 及 新文档且部分无权限操作下，设置为灰色，点击弹toast
                if viewModel.isDynamicFieldDenied || viewModel.isDynamicPartNoPerimission {
                    DocsLogger.info("isDynamicFieldDenied or isDynamicPartNoPerimission toast")
                    UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceTable_Tooltip, on: view)
                    return
                }
            }
        }

        //删除cell
        guard let index = currentTableView.indexPath(for: cell)?.item else {
            DocsLogger.error("delete error, find no index")
            return
        }

        hasFieldSubSettingClick = true
        if viewModel.fieldEditModel.compositeType.classifyType == .link {
            deleteFilterCondition(index: index)
            return
        }

        delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                     params: ["click": "delete_condition",
                                              "target": "none"],
                                     fieldEditModel: viewModel.fieldEditModel)

        dynamicOptionsConditions.remove(at: index)
        currentTableView.reloadData()
    }
    func didClickNoPermissionCellDelete(cell: UITableViewCell) {
        // toast逻辑
        if viewModel.fieldEditModel.compositeType.classifyType == .link {
            // 关联
            if viewModel.isLinkTablePartialDenied {
                DocsLogger.info("isLinkTablePartialDenied toast")
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceTable_Tooltip, on: view)
                return
            }
        } else {
            // 级联引用字段无权限以 及 新文档且部分无权限操作下，设置为灰色，点击弹toast
            if viewModel.isDynamicFieldDenied || viewModel.isDynamicPartNoPerimission {
                DocsLogger.info("isDynamicFieldDenied or isDynamicPartNoPerimission toast")
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceTable_Tooltip, on: view)
                return
            }
        }
        // 删除逻辑
        guard let index = currentTableView.indexPath(for: cell)?.item else {
            DocsLogger.error("delete error, find no index")
            return
        }
        if viewModel.fieldEditModel.compositeType.classifyType == .link {
            DocsLogger.info("link delete cell")
            deleteFilterCondition(index: index)
        } else {
            DocsLogger.info("dynamic delete cell")
            dynamicOptionsConditions.remove(at: index)
            currentTableView.reloadData()
        }
    }
    func didClickContainerButton(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        hasFieldSubSettingClick = true
        if viewModel.fieldEditModel.compositeType.classifyType == .link {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                // 点击关联条件按钮，有部分权限不可以点击，弹出toast
                let noAction = viewModel.isLinkTablePartialDenied
                if noAction {
                    DocsLogger.info("isDynamicFieldDenied or isDynamicPartNoPerimission or isDynamicTablePartialDenied toast")
                    UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceTable_Tooltip, on: view)
                    return
                }
            }
            showFilterPanel(index: index, cell: cell, subCell: subCell)
            return
        }
        if index == 0 {
            didClickSelectLinkTableFieldButton(button: nil, cell: cell)
        } else if index == 1 {
            didClickConditionButton(button: nil, cell: cell)
        } else if index == 2 {
            didClickSelectCurrentTableFieldButton(button: nil, cell: cell)
        }
    }
    
    func didClickSelectLinkTableFieldButton(button: BTConditionSelectButton?, cell: UITableViewCell) {
        //选择引用表中的字段
        resignInputFirstResponder()
        editingFieldCell = cell
        editingFieldCellIndex = currentTableView.indexPath(for: cell)?.item
        
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            // 级联引用字段无权限以 及 新文档且部分无权限操作下，设置为灰色，点击弹toast
            let shouldShowToast = viewModel.isDynamicFieldDenied || viewModel.isDynamicPartNoPerimission
            if shouldShowToast {
                DocsLogger.info("isDynamicFieldDenied or isDynamicPartNoPerimission toast")
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceField_Tooltip, on: view)
                return
            }
        }

        guard let index = editingFieldCellIndex,
              index < dynamicOptionsConditions.count else {
            DocsLogger.btError("dynamic option get fields is empty")
            return
        }

        guard viewModel.verifyTargetTable() else {
            UDToast.showWarning(with: BundleI18n.SKResource.Bitable_SingleOption_PleaseSelectReferencedDataToast_Mobile, on: self.view)
            return
        }

        delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                     params: ["click": "select_quote_field",
                                              "target": "none"],
                                     fieldEditModel: viewModel.fieldEditModel)

        let openPanelBlock = { [weak self] in
            guard let self = self else { return }

            let tableName = self.viewModel.commonData.tableNames.first(where: { $0.tableId == self.viewModel.fieldEditModel.fieldProperty.optionsRule.targetTable })?.tableName ?? ""
            
            let data = self.viewModel.commonData.linkTableFieldOperators.compactMap { field -> BTFieldCommonData? in
                // 如果当前表和引用表是同一张表，则过滤掉当前字段
                if field.id == self.viewModel.fieldEditModel.fieldId,
                    self.viewModel.fieldEditModel.tableId == self.viewModel.fieldEditModel.fieldProperty.optionsRule.targetTable {
                    //过滤掉当前字段
                    return nil
                }
                
                guard !field.isDeniedField else {
                    //过滤无权限字段
                    return nil
                }
                
                let icon = field.compositeType.icon()
                let data = BTFieldCommonData(id: field.id,
                                             name: field.name,
                                             groupId: tableName,
                                             icon: icon,
                                             showLighting: field.isSync,
                                             rightIocnType: .arraw,
                                             selectedType: .textHighlight)
                return data
            }

            var selectedIndexPath: IndexPath?
            if let selectedIndex = data.firstIndex(where: { $0.id == self.dynamicOptionsConditions[index].fieldId }) {
                selectedIndexPath = IndexPath(item: selectedIndex, section: 0)
            }

            self.dynamicOptionsShowCommonDataListVC(data: data,
                                                    title: BundleI18n.SKResource.Bitable_SingleOption_FieldInTargetTable,
                                                    action: .updateDynamicOptionConditionLinkTableFieldId,
                                                    relatedItemId: "",
                                                    relatedView: button,
                                                    lastSelectedIndexPath: selectedIndexPath,
                                                    emptyViewType: .searchFailed,
                                                    emptyViewText: BundleI18n.SKResource.Bitable_SingleOption_NoAvailableField_Mobile)
        }

        viewModel.getFieldOperators(tableId: viewModel.dynamicOptionRuleTargetTable,
                                    fieldId: nil,
                                    needUpdate: viewModel.commonData.linkTableFieldOperators.isEmpty,
                                    completion: {
            openPanelBlock()
        })
    }

    //选择规则
    func didClickConditionButton(button: BTConditionSelectButton?, cell: UITableViewCell, cellIndex: Int? = nil) {
        resignInputFirstResponder()
        editingFieldCell = cell
        editingFieldCellIndex = currentTableView.indexPath(for: cell)?.item
        
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            // 级联引用字段无权限以 及 新文档且部分无权限操作下，设置为灰色，点击弹toast
            let shouldShowToast = viewModel.isDynamicFieldDenied || viewModel.isDynamicPartNoPerimission
            if shouldShowToast {
                DocsLogger.info("isDynamicFieldDenied or isDynamicPartNoPerimission toast")
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceField_Tooltip, on: view)
                return
            }
        }

        if let cellIndex = cellIndex {
            editingFieldCellIndex = cellIndex
        }

        guard let index = editingFieldCellIndex,
              index < dynamicOptionsConditions.count else {
            return
        }

        guard !dynamicOptionsConditions[index].fieldId.isEmpty,
              let fieldOperators = viewModel.commonData.linkTableFieldOperators.first(where: { $0.id == dynamicOptionsConditions[index].fieldId }),
              !fieldOperators.isDeniedField else {
            UDToast.showWarning(with: BundleI18n.SKResource.Bitable_SingleOption_SelectFieldThenSelectConditionToast_Mobile, on: self.view)
            return
        }

        let dataList = fieldOperators.operators.filter({ $0.value != .Unkonwn}).compactMap { op -> BTFieldCommonData? in
            let rightIocnType: BTFieldCommonData.RightIconType = op.value.hasNotNextValueType ? .none : .arraw
            let data = BTFieldCommonData(id: op.value.rawValue,
                                         name: op.text,
                                         rightIocnType: rightIocnType,
                                         selectedType: .textHighlight)
            return data
        }

        var selectedIndexPath: IndexPath?
        if let selectedIndex = dataList.firstIndex(where: { $0.id == dynamicOptionsConditions[index].operator.rawValue }) {
            selectedIndexPath = IndexPath(item: selectedIndex, section: 0)
        }

        self.dynamicOptionsShowCommonDataListVC(data: dataList,
                                                title: BundleI18n.SKResource.Bitable_SingleOption_SelectConditionType_Mobile,
                                                action: .updateDynamicOptionCondition,
                                                relatedItemId: "",
                                                relatedView: button,
                                                lastSelectedIndexPath: selectedIndexPath)

    }

    func didClickSelectCurrentTableFieldButton(button: BTConditionSelectButton?, cell: UITableViewCell, cellIndex: Int? = nil) {
        //选择当前表的字段
        resignInputFirstResponder()
        editingFieldCell = cell
        editingFieldCellIndex = currentTableView.indexPath(for: cell)?.item
        
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            // 级联引用字段无权限以 及 新文档且部分无权限操作下，设置为灰色，点击弹toast
            let shouldShowToast = viewModel.isDynamicFieldDenied || viewModel.isDynamicPartNoPerimission
            if shouldShowToast {
                DocsLogger.info("isDynamicFieldDenied or isDynamicPartNoPerimission toast")
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceField_Tooltip, on: view)
                return
            }
        }

        delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                     params: ["click": "select_field",
                                              "target": "none"],
                                     fieldEditModel: viewModel.fieldEditModel)

        if let cellIndex = cellIndex {
            editingFieldCellIndex = cellIndex
        }

        let openPanelBlock = { [weak self] in
            guard let self = self else { return }

            let data = self.viewModel.commonData.currentTableFieldOperators.compactMap { field -> BTFieldCommonData? in
                guard field.id != self.viewModel.fieldEditModel.fieldId,
                      !field.isDeniedField else {
                    //过滤掉当前字段
                    return nil
                }
                let icon = field.compositeType.icon()
                let tableName = self.viewModel.commonData.tableNames.first(where: { $0.tableId == self.viewModel.fieldEditModel.tableId })?.tableName ?? ""
                let data = BTFieldCommonData(id: field.id,
                                             name: field.name,
                                             groupId: tableName,
                                             icon: icon,
                                             showLighting: field.isSync,
                                             rightIocnType: .none,
                                             selectedType: .textHighlight)
                return data
            }

            guard let index = self.editingFieldCellIndex,
                  index < self.dynamicOptionsConditions.count else {
                DocsLogger.btError("dynamic option get fields is empty")
                return
            }

            var selectedIndexPath: IndexPath?
            if let selectedIndex = data.firstIndex(where: { $0.id == self.dynamicOptionsConditions[index].value }) {
                selectedIndexPath = IndexPath(item: selectedIndex, section: 0)
            }

            self.dynamicOptionsShowCommonDataListVC(data: data,
                                                    title: BundleI18n.SKResource.Bitable_SingleOption_FieldInCurrentTable,
                                                    action: .updateDynamicOptionConditionCurrentTableFieldId,
                                                    relatedItemId: "",
                                                    relatedView: button,
                                                    lastSelectedIndexPath: selectedIndexPath,
                                                    emptyViewType: .searchFailed,
                                                    emptyViewText: BundleI18n.SKResource.Bitable_SingleOption_NoAvailableField_Mobile)
        }

        viewModel.getFieldOperators(tableId: viewModel.fieldEditModel.tableId,
                                    fieldId: nil,
                                    needUpdate: viewModel.commonData.currentTableFieldOperators.isEmpty,
                                    completion: {
            openPanelBlock()
        })
    }

    func dynamicOptionsShowCommonDataListVC(data: [BTFieldCommonData],
                                            title: String,
                                            action: BTFieldEditDataListViewAction,
                                            shouldShowDragBar: Bool = false,
                                            relatedItemId: String = "",
                                            relatedView: UIView? = nil,
                                            disableItemClickBlock: ((UIViewController, BTFieldCommonData) -> Void)? = nil,
                                            lastSelectedIndexPath: IndexPath? = nil,
                                            emptyViewType: UDEmptyType = .noContent,
                                            emptyViewText: String = "",
                                            showHiddenTableFooter: Bool = false) {

        let initViewHeightBlock: (() -> CGFloat) = { [weak self] in
            (self?.view.window?.bounds.height ?? SKDisplay.activeWindowBounds.height) * 0.8
        }

        let shouldShowDoneButton = self.presentedViewController != nil

        let commonDataList = BTFieldCommonDataListController(data: data,
                                                             title: title,
                                                             action: action.rawValue,
                                                             shouldShowDragBar: shouldShowDragBar,
                                                             shouldShowDoneButton: shouldShowDoneButton,
                                                             relatedItemId: relatedItemId,
                                                             relatedView: relatedView,
                                                             disableItemClickBlock: disableItemClickBlock,
                                                             lastSelectedIndexPath: lastSelectedIndexPath,
                                                             emptyViewType: emptyViewType,
                                                             emptyViewText: emptyViewText,
                                                             initViewHeightBlock: initViewHeightBlock,
                                                             showHiddenTableFooter: showHiddenTableFooter)
        commonDataList.delegate = self


        if let topVC = self.presentedViewController as? SKNavigationController {
            topVC.pushViewController(commonDataList, animated: true)
        } else {
            safePresent { [weak self] in
                guard let self = self else { return }
                BTNavigator.presentDraggableVCEmbedInNav(commonDataList, from: UIViewController.docs.topMost(of: self) ?? self)
            }
        }
    }

    func responseHandler(result: Result<BTAsyncResponseModel, BTAsyncRequestError>) {
        //前端异步请求回调
        switch result {
        case .success(let data):
            handleAsyncResponse(data: data)
        case .failure(let error):
            DocsLogger.btError("btfieldEdit asyncRequest failed error:\(error.description))")
        }
    }

    private func handleAsyncResponse(data: BTAsyncResponseModel) {        
        guard data.result == 0 else {
            DocsLogger.btError("BTAsyncRequest] btfieldEdit failed data:\(data.toJSONString() ?? "")")
            return
        }

        guard let optionData = data.data["options"] as? [[String: Any]],
              let options = [BTOptionModel].deserialize(from: optionData)?.compactMap({ $0 }) else {
            DocsLogger.btError("[BTAsyncRequest] btfieldEdit BTOptionModel deserialize failed data:\(data.toJSONString() ?? "")")
            return
        }
        let args = BTGetBitableCommonDataArgs(type: .getNewOptionId,
                                              tableID: viewModel.fieldEditModel.tableId,
                                              viewID: viewModel.fieldEditModel.viewId,
                                              fieldID: viewModel.fieldEditModel.fieldId,
                                              extraParams: ["total": options.count])
        self.dataService?.getBitableCommonData(args: args) { [weak self] result, error in
            guard let self = self else { return }
            guard error == nil,
                  let optionIds = result as? [String] else {
                DocsLogger.info("bitable optionPanel getOptionId failed")
                return
            }

            guard optionIds.count == options.count else {
                DocsLogger.info("bitable optionPanel getOptionId count not match")
                return
            }

            self.viewModel.options.removeAll()
            for (i, op) in options.enumerated() where i < optionIds.count {
                var newOption = op
                newOption.id = optionIds[i]
                self.viewModel.options.append(newOption)
            }
            self.currentTableView.reloadData()
        }
    }

    //上报选项字段编辑页面停留时间
    func trackStadingOptionTypeTime() {
        guard viewModel.fieldEditModel.compositeType.classifyType == .option, let optionTypeOpenTime = optionTypeOpenTime else { return }
        delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyDuration,
                                     params: ["field_type": viewModel.fieldEditModel.fieldTrackName,
                                              "duration": (Date().timeIntervalSince1970 - optionTypeOpenTime) * 1000],
                                     fieldEditModel: viewModel.fieldEditModel)
    }
}
