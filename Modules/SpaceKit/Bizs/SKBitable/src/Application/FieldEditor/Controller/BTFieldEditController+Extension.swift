//
//  BTFieldEditController+Extension.swift
//  SKBitable
//
//  Created by zoujie on 2022/1/18.
//  swiftlint:disable file_length


import SKFoundation
import SKBrowser
import SKCommon
import SKResource
import EENavigator
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignDialog
import SKUIKit
import UIKit

enum BTFieldEditDataListViewAction: String {
    //字段编辑面板
    case updateFieldType //更新字段类型
    case updateNumberFormat //更新数字格式
    case updateCurrencyType //更新货币格式
    case updateProgressNumberType //更新进度条类型
    case updateProgressNumberDigits //更新进度条小数位数
    case updateRatingMin //更新评分最小值
    case updateRatingMax //更新评分最大值
    case updateDateFormat  //更新日期格式
    case updateRelatedTable //更新关联表
    
    //自动编号
    case updateAutoNumberRuleDateFormat //更新自动编号日期格式
    
    //级联选项
    case updateDynamicOptionCondition //更新级联选项引用条件
    case updateDynamicOptionTargetTableId //更新级联选项引用表Id
    case updateDynamicOptionTargetFieldId //更新级联选项引用表内字段Id
    case updateDynamicOptionConditionLinkTableFieldId //更新级联选项引用条件引用数据表字段Id
    case updateDynamicOptionConditionCurrentTableFieldId //更新级联选项引用条件当前表字段Id
    
    // 扩展字段
    case updateFieldExtendType //从当前字段扩展子字段
}

enum BTFieldEditPageAction: String {
    //自动编号
    case autoNumberTypeSelect //自动编号类型选择
    case autoNumberRuleSelect //自动编号添加规则
    
    //级联选项
    case optionsTypeSelect //选项类型选择
    case dynamicOptionsConjunctionSelect //更新级联选项条件组合方式
    
    //关联表
    case linkTableFilterTypeSelect // 关联表所有数据/筛选数据
    case linkTableFilterConjunctionSelect // 关联表筛选条件任一/所有条件
    
    //地理位置
    case geoLocationInputTypeSelect //地理位置输入选择
}

extension BTFieldEditController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.isCurrentExtendChildType {
            // 扩展子字段配置是只读的，不可编辑
            return 0
        }
        if let commonDataModel = viewModel.fieldEditConfig.commonDataModel {
            return commonDataModel.groups.count
        }
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.isCurrentExtendChildType {
            // 扩展子字段配置是只读的，不可编辑
            return 0
        }
        if let commonDataModel = viewModel.fieldEditConfig.commonDataModel, section < commonDataModel.groups.count {
            let group = commonDataModel.groups[section]
            return group.items.count
        }
        if viewModel.fieldEditModel.compositeType.uiType == .autoNumber {
            return viewModel.fieldEditModel.fieldProperty.isAdvancedRules ? auotNumberRuleList.count : 0
        } else if viewModel.fieldEditModel.compositeType.classifyType == .option {
            if LKFeatureGating.bitableDynamicOptionsEnable,
               viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption {
                let tableId = viewModel.dynamicOptionRuleTargetTable
                
                setSaveButtonEnable()
                if let linkTable = viewModel.commonData.tableNames.first(where: { $0.tableId == tableId }),
                   !linkTable.readPerimission {
                    return 0
                }
                return dynamicOptionsConditions.count
            }
            return viewModel.options.count
        } else if viewModel.fieldEditModel.compositeType.classifyType == .link {
            if viewModel.fieldEditModel.isLinkAllRecord {
                return 0
            }
            return viewModel.linkFieldFilterCellModels.count
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var currentReuseID = reuseID
        if let commonDataModel = viewModel.fieldEditConfig.commonDataModel {
            if indexPath.section < commonDataModel.groups.count {
                let group = commonDataModel.groups[indexPath.section]
                if indexPath.row < group.items.count {
                    let item = group.items[indexPath.row]
                    
                    if let customCell = item.customCell {
                        // 使用自定义的 cell
                        currentReuseID += customCell.reuseID
                    } else {
                        currentReuseID += ".common"
                    }
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: currentReuseID, for: indexPath)
                    
                    if let cell = cell as? BTCommonCell {
                        cell.update(item: item, group: group, indexPath: indexPath)
                    }
                    return cell
                }
            }
            // 正常情况不会走到这里
            spaceAssertionFailure("item not found, please check the data!")
            return tableView.dequeueReusableCell(withIdentifier: currentReuseID + ".common", for: indexPath)
        }
        if viewModel.fieldEditModel.compositeType.classifyType == .option {
            var suffix = ".staticOption"
            if LKFeatureGating.bitableDynamicOptionsEnable, viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption {
                suffix = ".condition"
            }
            
            currentReuseID += suffix
        } else if viewModel.fieldEditModel.compositeType.uiType == .autoNumber {
            currentReuseID += ".autoNumber"
        } else if viewModel.fieldEditModel.compositeType.classifyType == .link {
            currentReuseID += ".condition"
        } else {
            return UITableViewCell()
        }

        if viewModel.fieldEditModel.compositeType.classifyType == .option,
           LKFeatureGating.bitableDynamicOptionsEnable,
           viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute { // 级联，筛选字段无权限不展示条件，只展示无权限cell
                guard indexPath.row < dynamicOptionsConditions.count else { return UITableViewCell() }
                let item = dynamicOptionsConditions[indexPath.row]
                if let linkField = viewModel.commonData.linkTableFieldOperators.first(where: { $0.id == item.fieldId }) {
                    if linkField.isDeniedField {
                        var reID = reuseID
                        reID += ".noPermission"
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: reID, for: indexPath) as? BTConditionNoPermissionCell else { return UITableViewCell() }
                        // 单条件无权限文案是特化的，不显示数字
                        if self.dynamicOptionsConditions.count == 1 {
                            cell.configText(BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessFieldDueToInaccessibleReferencedData_Tooltip)
                        } else {
                            let num = indexPath.row + 1
                            let str = String(num)
                            cell.configText(BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessFieldDueToInaccessibleNumReferenceCondition(str))
                        }
                        cell.isFirstCell = indexPath.row == 0
                        cell.delegate = self
                        // 产品逻辑，仅一个不能删除
                        if viewModel.linkTableFilterInfo?.conditions.count != 1 {
                            cell.deleteButton.isHidden = false
                        } else {
                            cell.deleteButton.isHidden = true
                        }
                        return cell
                    }
                }
            }
            guard let cell = tableView.dequeueReusableCell(withIdentifier: currentReuseID, for: indexPath) as? BTConditionSelectCell else { return UITableViewCell() }
            return configDynamicOptionConditionCell(indexPath: indexPath, cell: cell)
        }
        
        if viewModel.fieldEditModel.compositeType.classifyType == .link {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute { // 单双向关联，筛选字段无权限不展示条件，只展示无权限cell
                guard viewModel.linkFieldFilterCellModels.count > 0 else { return UITableViewCell() }
                let model = viewModel.linkFieldFilterCellModels[indexPath.row]
                let isFieldNoPermission = (model.invalidType == .fieldUnreadable || model.invalidType == .partNoPermission)
                let noPerm: Bool
                    let linkTableNoRead = !viewModel.linkTableReadPerimission
                    noPerm = linkTableNoRead || isFieldNoPermission
                if noPerm {
                    var reID = reuseID
                    reID += ".noPermission"
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: reID, for: indexPath) as? BTConditionNoPermissionCell else { return UITableViewCell() }
                    // 单条件无权限文案是特化的，不显示数字
                    if viewModel.linkFieldFilterCellModels.count == 1 {
                        cell.configText(BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessFieldDueToInaccessibleFilterCondition_Tooltip)
                    } else {
                        let num = indexPath.row + 1
                        let str = String(num)
                        cell.configText(BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToAccessFieldDueToInaccessibleNumFilterCondition(str))
                    }
                    cell.isFirstCell = indexPath.row == 0
                    cell.delegate = self
                    // 产品逻辑，仅一个不能删除
                    if viewModel.linkTableFilterInfo?.conditions.count != 1 {
                        cell.deleteButton.isHidden = false
                    } else {
                        cell.deleteButton.isHidden = true
                    }
                    return cell
                }
            }
            guard let cell = tableView.dequeueReusableCell(withIdentifier: currentReuseID, for: indexPath) as? BTConditionSelectCell else { return UITableViewCell() }
            return configLinkTableFilterConditionCell(indexPath: indexPath, cell: cell)
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: currentReuseID, for: indexPath) as? BTFieldEditCell else { return UITableViewCell() }
        
        var tableViewCell = cell
        if viewModel.fieldEditModel.compositeType.uiType == .autoNumber {
            tableViewCell = configAutoNumberCell(indexPath: indexPath, cell: cell)
        } else if viewModel.fieldEditModel.compositeType.classifyType == .option {
            tableViewCell = configOptionCell(indexPath: indexPath, cell: cell)
        }
        
        tableViewCell.slideItemProvider = { [weak self] mutexHandler in
            guard let self = self else { return (nil, nil) }
            self.slideMutexHelper.startSliding(mutexHandler: mutexHandler)
            self.resignInputFirstResponder()
            return (self.swipeActionsForRowAt(indexPath: indexPath, enable: tableViewCell.deleteable), self.slideMutexHelper)
        }
        
        return tableViewCell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.fieldEditModel.compositeType.classifyType == .option,
           LKFeatureGating.bitableDynamicOptionsEnable,
           viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                let item = dynamicOptionsConditions[indexPath.row]
                if let linkField = viewModel.commonData.linkTableFieldOperators.first(where: { $0.id == item.fieldId }) {
                    if linkField.isDeniedField {
                        if indexPath.row == 0 {
                            return 52
                        } else {
                            return 62
                        }
                    }
                }
            }
            return cellHeight[indexPath.row] ?? 140
        }
        if viewModel.fieldEditModel.compositeType.classifyType == .link {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                let model = viewModel.linkFieldFilterCellModels[indexPath.row]
                let isFieldNoPermission = (model.invalidType == .fieldUnreadable)
                if isFieldNoPermission {
                    return 52
                }
            }
            return cellHeight[indexPath.row] ?? 88
        }
        return editingFieldCellHasErrorIndexs.contains(indexPath.row) ? 82 : 52
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let commonDataModel = viewModel.fieldEditConfig.commonDataModel else {
            return nil
        }
        let wrapper = UIView()
        if section < commonDataModel.groups.count {
            let group = commonDataModel.groups[section]
            if let groupName = group.groupName, !groupName.isEmpty {
                // 显示 section 标题
                let view = UILabel()
                view.text = group.groupName
                view.font = UIFont.systemFont(ofSize: 14)
                view.textColor = .ud.textPlaceholder
                wrapper.addSubview(view)
                view.snp.makeConstraints { make in
                    make.bottom.equalToSuperview().inset(2)
                    make.left.right.equalToSuperview()
                    make.height.equalTo(20)
                }
            }
        }
        return wrapper
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let commonDataModel = viewModel.fieldEditConfig.commonDataModel else {
            return 0
        }
        if section < commonDataModel.groups.count {
            let group = commonDataModel.groups[section]
            if let groupName = group.groupName, !groupName.isEmpty {
                // 显示 section 标题
                // 14(文本顶部间距) + 20(文本高度) + 2(文本底部间距)
                return 14 + 20 + 2
            } else {
                // 不显示 section 标题
                // 14(section 间距)
                return 14
            }
        }
        // 14(section 间距)
        return 14
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard viewModel.fieldEditConfig.commonDataModel != nil else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        slideMutexHelper.tableViewDidScroll()
    }
    
    func swipeActionsForRowAt(indexPath: IndexPath, enable: Bool) -> [SKSlidableTableViewCellItem]? {
        return [SKSlidableTableViewCellItem(icon: UDIcon.getIconByKey(.deleteTrashOutlined, iconColor: UDColor.primaryOnPrimaryFill, size: CGSize(width: 20, height: 20)),
                                            backgroundColor: enable ? UDColor.functionDangerContentDefault : UDColor.textDisabled,
                                            handler: { [weak self] _, _ in
            self?.slideMutexHelper.didClickSlideMenuAction()
            
            guard enable else { return }
            self?.didClickDeletedButton(index: indexPath)
        })]
    }
    
    func configAutoNumberCell(indexPath: IndexPath,
                              cell: BTFieldEditCell) -> BTFieldEditCell {
        guard indexPath.row < auotNumberRuleList.count,
              let cell = cell as? BTAutoNumberTableCell else { return cell }
        
        let autoNumberRule = auotNumberRuleList[indexPath.row]
        cell.setUIConfig(type: autoNumberRule.type,
                         text: autoNumberRule.value,
                         name: autoNumberRule.title,
                         editable: !isPhoneLandscape,
                         hasError: editingFieldCellHasErrorIndexs.contains(indexPath.row),
                         baseContext: self.baseContext
        )
        cell.id = autoNumberRule.id
        cell.descriptionStr = autoNumberRule.description
        cell.hostVC = self
        cell.delegate = self
        
        let isFirstItem = indexPath.row == 0
        let isLastItem = indexPath.row == auotNumberRuleList.count - 1
        var corners: CACornerMask = []
        if isFirstItem {
            corners.insert(.top)
        }
        if isLastItem {
            corners.insert(.bottom)
            cell.separator.isHidden = true
        } else {
            cell.separator.isHidden = false
        }
        cell.update(roundCorners: corners)
        
        if autoNumberRule.id == newItemID {
            //新增的固定数字和固定字符规则直接进入编辑态
            cell.isNewItem = true
            newItemID = ""
        }
        
        return cell
    }
    
    func configOptionCell(indexPath: IndexPath,
                          cell: BTFieldEditCell) -> BTFieldEditCell {
        guard indexPath.row < viewModel.options.count,
              let cell = cell as? BTOptionTableCell else { return cell }
        let option = viewModel.options[indexPath.row]
        let colorId = option.color
        if let color = viewModel.commonData.colorList.first(where: { $0.id == colorId }) {
            cell.setUIConfig(color: UIColor.docs.rgb(color.color),
                             text: option.name,
                             editable: !isPhoneLandscape,
                             baseContext: self.baseContext
            )
            cell.optionID = option.id
            cell.hostVC = self
            cell.delegate = self
            
            let isFirstItem = indexPath.row == 0
            let isLastItem = indexPath.row == viewModel.options.count - 1
            var corners: CACornerMask = []
            if isFirstItem {
                corners.insert(.top)
            }
            if isLastItem {
                corners.insert(.bottom)
                cell.separator.isHidden = true
            } else {
                cell.separator.isHidden = false
            }
            cell.update(roundCorners: corners)
        }
        
        if option.id == newItemID {
            //新增选项直接进入编辑态
            cell.isNewItem = true
            newItemID = ""
        }
        
        return cell
    }
    
    ///拖动选项cell超出边界，恢复拖动前的cell状态，重制变量
    func resetParams() {
        snapView?.isHidden = true
        snapView?.removeFromSuperview()
        snapView = nil
        
        if let startIndex = startIndex,
           let startCell = currentTableView.cellForRow(at: startIndex) {
            self.startIndex = nil
            startCell.alpha = 1
        }
        
        if let endIndex = endIndex, let endCell = currentTableView.cellForRow(at: endIndex) {
            self.endIndex = nil
            endCell.alpha = 1
        }
        
        currentTableView.reloadData()
        currentTableView.isScrollEnabled = true
    }
}

extension BTFieldEditController: BTOptionTableCellDelegate {
    func didChangeOptionName(optionID: String, optionName: String?) {
        hasFieldSubSettingClick = true
        delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                     params: ["click": "title",
                                              "target": "none"],
                                     fieldEditModel: viewModel.fieldEditModel)
        viewModel.options = viewModel.options.map { option in
            if option.id == optionID {
                var newOption = option
                newOption.name = optionName ?? ""
                return newOption
            }
            
            return option
        }
    }
    
    func didClickColorView(optionID: String, colorView: UIView) {
        guard let index = viewModel.options.firstIndex(where: { $0.id == optionID }) else {
            return
        }
        
        hasFieldSubSettingClick = true
        
        delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                     params: ["click": "change_color",
                                              "target": "ccm_bitable_color_board_view"],
                                     fieldEditModel: viewModel.fieldEditModel)
        
        let colorId = viewModel.options[index].color
        guard let selectedColor = viewModel.commonData.colorList.first(where: { $0.id == colorId }) else {
            return
        }
        
        let colorSelectView = BTOptionColorSelectController(colors: viewModel.commonData.colorList,
                                                            selectedColor: selectedColor,
                                                            text: viewModel.options[index].name,
                                                            optionID: optionID,
                                                            shouldShowBackButton: false,
                                                            hostVC: self)
        
        
        
        colorSelectView.delegate = self
        
        if self.view.isMyWindowRegularSize() {
            colorSelectView.modalPresentationStyle = .popover
            colorSelectView.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            colorSelectView.popoverPresentationController?.sourceView = colorView
            colorSelectView.popoverPresentationController?.sourceRect = colorView.bounds
            colorSelectView.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            colorSelectView.preferredContentSize = CGSize(width: 375, height: 180)
        } else {
            colorSelectView.modalPresentationStyle = .overFullScreen
            colorSelectView.transitioningDelegate = colorSelectView.panelTransitioningDelegate
        }
        
        safePresent { [weak self] in
            guard let self = self else { return }
            Navigator.shared.present(colorSelectView, from: self) { _ in
                self.delegate?.trackEditViewEvent(eventType: .bitableOptionFieldOpenColorSelectView,
                                                  params: [:],
                                                  fieldEditModel: self.viewModel.fieldEditModel)
                
            }
        }
    }
    
    func didBeginEditOptionName(optionID: String, cell: BTOptionTableCell) {
        hasFieldSubSettingClick = true
        editingFieldCell = cell
        if let index = viewModel.options.firstIndex(where: { $0.id == optionID }) {
            editingFieldCellIndex = index
        }
    }
    
    func didEndEditOptionName(optionID: String, cell: BTOptionTableCell) {
        hasFieldSubSettingClick = true
        if let index = editingFieldCellIndex {
            currentTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
        
        editingFieldCell = nil
        editingFieldCellIndex = nil
    }
    
    func longPress(_ sender: UILongPressGestureRecognizer, cell: BTFieldEditCell) {
        let location = sender.location(in: currentTableView)
        guard currentTableView.bounds.contains(location),
              false == currentTableView.tableHeaderView?.frame.contains(location),
              false == currentTableView.tableFooterView?.frame.contains(location) else {
            resetParams()
            return
        }
        
        switch sender.state {
        case .began:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            snapView = cell.snapshotView(afterScreenUpdates: true)
            snapView?.layer.ud.setShadow(type: .s3Down)
            guard let snapView = snapView else {
                return
            }
            
            cell.alpha = 0
            currentTableView.isScrollEnabled = false
            currentTableView.addSubview(snapView)
            snapView.center = cell.center
            startIndex = currentTableView.indexPath(for: cell)
        case .changed:
            snapView?.center.y = location.y
            guard let startIndex = startIndex,
                  let endIndex = currentTableView.indexPathForRow(at: location),
                  startIndex != endIndex,
                  let endCell = currentTableView.cellForRow(at: endIndex),
                  let startCell = currentTableView.cellForRow(at: startIndex),
                  endIndex != self.endIndex else {
                return
            }
            
            hasFieldSubSettingClick = true
            
            self.delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                              params: ["click": "option_drag",
                                                       "target": "none",
                                                       "form_option_idx": "\(startIndex.row)",
                                                       "to_option_idx": "\(endIndex.row)"],
                                              fieldEditModel: viewModel.fieldEditModel)
            DocsLogger.btInfo("bitable fieldEdit option drag from:\(startIndex.row) to:\(endIndex.row)")
            //先更新数据源
            if viewModel.fieldEditModel.compositeType.uiType == .autoNumber {
                auotNumberRuleList.swapAt(startIndex.row, endIndex.row)
                DocsLogger.btInfo("bitable fieldEdit option drag tableView editingFieldCellHasErrorIndexs start:\(editingFieldCellHasErrorIndexs)")
                //分两种情况
                if editingFieldCellHasErrorIndexs.contains(startIndex.row) &&
                    !editingFieldCellHasErrorIndexs.contains(endIndex.row) {
                    editingFieldCellHasErrorIndexs.removeAll(where: { $0 == startIndex.row })
                    editingFieldCellHasErrorIndexs.append(endIndex.row)
                } else if editingFieldCellHasErrorIndexs.contains(endIndex.row) &&
                            !editingFieldCellHasErrorIndexs.contains(startIndex.row) {
                    editingFieldCellHasErrorIndexs.removeAll(where: { $0 == endIndex.row })
                    editingFieldCellHasErrorIndexs.append(startIndex.row)
                }
                
                DocsLogger.btInfo("bitable fieldEdit option drag tableView editingFieldCellHasErrorIndexs end:\(editingFieldCellHasErrorIndexs)")
            } else if viewModel.fieldEditModel.compositeType.classifyType == .option {
                viewModel.options.swapAt(startIndex.row, endIndex.row)
            }
            
            currentTableView.moveRow(at: startIndex, to: endIndex)
            
            endCell.alpha = 1
            startCell.alpha = 0
            self.endIndex = endIndex
            self.startIndex = endIndex
            
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        default:
            resetParams()
        }
    }
    
    func changeTypeConfirmDialog(completion: (() -> Void)? = nil) {
        if viewModel.fieldEditModel.compositeType.classifyType == .option,
          !viewModel.fieldEditModel.dependentTables.isEmpty {
            let concatenatedString = viewModel.fieldEditModel.dependentTables.reduce("", { (partialResult, newStr) -> String in
                if partialResult.isEmpty {
                    return "\(newStr)"
                } else {
                    return "\(partialResult),\(newStr)"
                }
            })
            
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.SKResource.Bitable_SingleOption_ChangeFieldTypePopupTitle_Mobile)
            dialog.setContent(text: BundleI18n.SKResource.Bitable_SingleOption_ChangeFieldTypePopupContent_Mobile(concatenatedString))
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                let trackString = self.viewModel.fieldEditModel.fieldTrackName
                self.delegate?.trackEditViewEvent(eventType: .bitableFieldModifyDynamicOptionsWarningViewClick,
                                                  params: ["click": "cancel",
                                                           "field_type": trackString],
                                                  fieldEditModel: self.viewModel.fieldEditModel)
            })
            dialog.addDestructiveButton(text: BundleI18n.SKResource.Bitable_SingleOption_ChangeFieldTypePopupButtonModify_Mobile, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                let trackString = self.viewModel.fieldEditModel.fieldTrackName
                self.delegate?.trackEditViewEvent(eventType: .bitableFieldModifyDynamicOptionsWarningViewClick,
                                                  params: ["click": "modify",
                                                           "field_type": trackString],
                                                  fieldEditModel: self.viewModel.fieldEditModel)

                completion?()
            })
            
            safePresent { [weak self] in
                guard let self = self else { return }
                let trackString = self.viewModel.fieldEditModel.fieldTrackName
                self.present(dialog, animated: true, completion: {
                    self.delegate?.trackEditViewEvent(eventType: .bitableFieldModifyDynamicOptionsWarningView,
                                                      params: ["field_type": trackString],
                                                      fieldEditModel: self.viewModel.fieldEditModel)
                })
            }
            return
        }
        
        completion?()
    }
}

extension BTFieldEditController: BTFieldCommonDataListDelegate {
    func didSelectedItem(_ item: BTFieldCommonData,
                         relatedItemId: String,
                         relatedView: UIView?,
                         action: String,
                         viewController: UIViewController,
                         sourceView: UIView? = nil) {
        guard let fieldEditAction = BTFieldEditDataListViewAction(rawValue: action) else {
            return
        }
        switch fieldEditAction {
        case .updateDateFormat:
            guard let button = relatedView as? BTFieldCustomButton,
                  let dateItem = viewModel.commonData.fieldConfigItem.commonDateTimeList.first(where: { $0.id == item.id }) else {
                return
            }
            let trackString = self.viewModel.fieldEditModel.fieldTrackName
            viewModel.fieldEditModel.fieldProperty.updateDateFormat(with: dateItem)
            button.setTitleString(text: dateItem.text)
            let timeFormat = dateItem.timeFormat.isEmpty ? "" : " " + dateItem.timeFormat
            let gmtFormat = dateItem.displayTimeZone ? "(GMT+N)" : ""
            delegate?.trackEditViewEvent(eventType: .bitableTimeFieldFormatModifyViewClick,
                                         params: ["click": dateItem.dateFormat + timeFormat + gmtFormat,
                                                  "field_type": trackString,
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
            viewController.dismiss(animated: true)
        case .updateNumberFormat, .updateCurrencyType:
            changeNumberType(item,
                             relatedItemId: relatedItemId,
                             relatedView: relatedView,
                             action: fieldEditAction,
                             viewController: viewController)        
        case .updateProgressNumberType, .updateProgressNumberDigits:
            guard let button = relatedView as? BTFieldCustomButton else {
                return
            }
            
            viewModel.fieldEditModel.fieldProperty.formatter = item.id
            button.setTitleString(text: item.name)
            
            if let currentConfig = viewModel.commonData.fieldConfigItem.getCurrentFormatConfig(fieldEditModel: viewModel.fieldEditModel) {
                if fieldEditAction == .updateProgressNumberType {
                    delegate?.trackEditViewEvent(eventType: .bitableProgressFieldModifyClick,
                                                 params: ["click": "number_format", // number_format: 点击数字格式下拉框时上报
                                                          "number_format_type": currentConfig.typeConfig.type?.tracingString() ?? "",
                                                          "target": "none"],
                                                 fieldEditModel: viewModel.fieldEditModel)
                } else if fieldEditAction == .updateProgressNumberDigits {
                    delegate?.trackEditViewEvent(eventType: .bitableProgressFieldModifyClick,
                                                 params: ["click": "decimal_digits", // decimal_digits: 点击小数位数下拉框时上报
                                                          "decimal_digits_type": BTFormatTypeConfig.getDecimalDigitsTracingString(currentConfig.decimalDigits),
                                                          "target": "none"],
                                                 fieldEditModel: viewModel.fieldEditModel)
                }
            }
            updateUI(fieldEditModel: viewModel.fieldEditModel)
            viewController.dismiss(animated: true)
        case .updateRelatedTable:
            guard let button = relatedView as? BTFieldCustomButton else {
                return
            }
            viewModel.fieldEditModel.fieldProperty.tableId = item.id
            // 切换关联表时，清空当前表筛选数据
            viewModel.fieldEditModel.fieldProperty.filterInfo = nil
            viewModel.fieldEditModel.isLinkAllRecord = true
            updateCellViewData()
            updateUI(fieldEditModel: viewModel.fieldEditModel)
            if let relatedTableName = viewModel.fieldEditModel.tableNameMap.first(where: { $0.tableId == item.id })?.tableName {
                button.setSubTitleString(text: relatedTableName)
                button.setTitleColor(color: UDColor.textTitle)
            }
            viewController.dismiss(animated: true)
        case .updateAutoNumberRuleDateFormat:
            guard let index = auotNumberRuleList.firstIndex(where: { $0.id == relatedItemId }) else { return }
            auotNumberRuleList[index].value = item.name
            
            viewController.dismiss(animated: true)
            
            currentTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        case .updateFieldType:
            if UserScopeNoChangeFG.QYK.btChatAIExtension {
                var targetUIType = item.name
                var ids = item.id.split(separator: "#")
                if ids.count > 1 {
                    targetUIType = String(ids[1])
                }
                guard let sourceView = sourceView else {
                    DocsLogger.btError("Error: can not get target source View")
                    return
                }
                self.checkFieldTypeChange(targetUIType: targetUIType, fieldType: item.name, sourceView: sourceView) { [weak self] in
                    guard let self = self else { return }
                    self.updateFieldType(item: item,
                                    relatedItemId: relatedItemId,
                                    relatedView: relatedView,
                                    action: action,
                                    viewController: viewController,
                                    sourceView: sourceView)
                }
                return
            }
            self.updateFieldType(item: item,
                            relatedItemId: relatedItemId,
                            relatedView: relatedView,
                            action: action,
                            viewController: viewController,
                            sourceView: sourceView)
        case .updateFieldExtendType:
            viewController.navigationController?.popToViewController(self, animated: true)
            guard let (origin, configItem) = item.reference as? (FieldExtendOrigin, FieldExtendConfigItem) else {
                spaceAssertionFailure("origin item should not be nil!")
                return
            }
            viewModel.fieldEditModel.fieldExtendInfo = FieldExtendInfo(
                originField: FieldExtendInfo.OriginInfo(
                    fieldId: origin.fieldId,
                    fieldName: origin.fieldName,
                    fieldType: origin.fieldType,
                    fieldUIType: origin.fieldUIType
                ),
                editable: true,
                extendInfo: FieldExtendInfo.ExtendInfo(
                    extendFieldType: configItem.extendFieldType,
                    originFieldId: origin.fieldId,
                    originFieldUIType: origin.fieldUIType
                )
            )
            extendManager.trackExtendSubTypePanelClick(origin: origin, item: configItem, sceneType: self.sceneType)
            guard let types = BTFieldCompositeType.getTypesFormId(item.id) else { return }
            changeFieldType(typeValue: types.0, uiTypeValue: types.1, hasNewTag: item.isShowNew)
        case .updateDynamicOptionCondition,
                .updateDynamicOptionTargetTableId,
                .updateDynamicOptionTargetFieldId,
                .updateDynamicOptionConditionLinkTableFieldId,
                .updateDynamicOptionConditionCurrentTableFieldId:
            didSelectedDynamicOptionItem(item,
                                         relatedItemId: relatedItemId,
                                         relatedView: relatedView,
                                         action: fieldEditAction,
                                         viewController: viewController)
        default:
            // 后续新增请 FieldEditConfig 模式
            break
        }
    }

    private func changeFieldType(typeValue: Int, uiTypeValue: String?, hasNewTag: Bool, completion: (() -> Void)? = nil) {
        guard let type = BTFieldType(rawValue: typeValue) else {
            DocsLogger.btError("field edit change type error not support fieldType")
            return
        }

        let newCompositeType = BTFieldCompositeType(fieldTypeValue: typeValue, uiTypeValue: uiTypeValue)
        if let onBoardingID = BTFieldEditConfig.onBoardingID(fieldType: newCompositeType) {
            OnboardingManager.shared.markFinished(for: [onBoardingID])
        }

        //单多选切换到其它类型，立即上报停留时长
        if viewModel.fieldEditModel.compositeType.classifyType == .option, !(newCompositeType.classifyType == .option) {
            trackStadingOptionTypeTime()
        }

        //其它字段切换到单多选字段，重置计时
        if !(viewModel.fieldEditModel.compositeType.classifyType == .option), newCompositeType.classifyType == .option {
            optionTypeOpenTime = Date().timeIntervalSince1970
        }
        
        // 字段类型发生变化，重置属性
        if viewModel.fieldEditModel.compositeType.uiType != newCompositeType.uiType {
            BTFieldEditConfig.resetPropertiesBeforeChangeType(viewModel: viewModel, toType: newCompositeType)
        }
        
        let filedItem = viewModel.commonData.fieldConfigItem.fieldItems.first(where: { $0.compositeType == newCompositeType })

        changeTypeConfirmDialog { [weak self] in
            guard let self = self else { return }
            if self.viewModel.fieldEditModel.compositeType != newCompositeType {
                self.hasFieldSubSettingClick = false // 更新字段类型要重置该字段
            }
            
            self.viewModel.covertNumberAndCurrency(fieldType: type, uiType: newCompositeType.uiType.rawValue)
            self.viewModel.fieldEditModel.update(fieldType: type, uiType: newCompositeType.uiType.rawValue)
            if self.viewModel.isCurrentExtendChildType {
                self.viewModel.fieldEditModel.allowedEditModes = self.extendManager.allowEditModes
            } else {
                self.viewModel.fieldEditModel.allowedEditModes = filedItem?.allowedEditModes
            }
            if type == .autoNumber,
               self.viewModel.fieldEditModel.fieldProperty.defaultAutoNumberRuleTypeIndex < self.viewModel.commonData.fieldConfigItem.commonAutoNumberRuleTypeList.count {
                let autoNumberDefaultType = self.viewModel.commonData.fieldConfigItem.commonAutoNumberRuleTypeList[self.viewModel.fieldEditModel.fieldProperty.defaultAutoNumberRuleTypeIndex]
                self.viewModel.fieldEditModel.fieldProperty.isAdvancedRules = autoNumberDefaultType.isAdvancedRules
            }
            
            self.updateUI(fieldEditModel: self.viewModel.fieldEditModel)
            
            // 更新新字段类型的扩展配置信息
            self.asyncReloadExtendConfigsDueToFieldTypeChange()
            
            let trackString = self.viewModel.fieldEditModel.fieldTrackName
            var params = ["click": trackString,
                          "target": "none",
                          "edit_type": self.editTypeStringForTracking,
                          "is_new_tag": DocsTracker.toString(value: hasNewTag),
                          "scene_type": self.sceneType]
            params["from_field_type"] = self.currentMode != .add ? self.viewModel.oldFieldEditModel.fieldTrackName : nil
            if self.viewModel.isCurrentExtendChildTypeChanged, let extInfo = self.viewModel.fieldEditModel.fieldExtendInfo?.extendInfo {
                params["click"] = "hover_extend_field"
                params["hover_field_type"] = extInfo.originFieldUIType.fieldTrackName
                params["target"] = "ccm_bitable_field_extend_modify_view"
            }
            self.delegate?.trackEditViewEvent(eventType: .bitableFieldTypeModifyViewClick,
                                              params: params,
                                              fieldEditModel: self.viewModel.fieldEditModel)
            completion?()
        }
    }

    //更改数字字段格式
    private func changeNumberType(_ item: BTFieldCommonData,
                                  relatedItemId: String,
                                  relatedView: UIView?,
                                  action: BTFieldEditDataListViewAction,
                                  viewController: UIViewController) {
        switch action {
        case .updateNumberFormat:
            guard let button = relatedView as? BTFieldCustomButton else {
                return
            }
            
            if viewModel.fieldEditModel.compositeType.uiType == .currency {
                let currencyCode = viewModel.fieldEditModel.fieldProperty.currencyCode
                viewModel.updateCurrencyProperty(formatter: item.id, currencyCode: currencyCode)
            } else {
                viewModel.fieldEditModel.fieldProperty.formatter = item.id
            }
            button.setTitleString(text: item.name)
            
            if let selectedNumberType = viewModel.commonData.fieldConfigItem.commonNumberFormatList.first(where: { $0.formatCode == item.id
            }) {
                delegate?.trackEditViewEvent(eventType: .bitableNumberFieldModifyViewClick,
                                             params: ["click": selectedNumberType.formatterName,
                                                      "target": "none"],
                                             fieldEditModel: viewModel.fieldEditModel)
            }
            viewController.dismiss(animated: true)
        case .updateCurrencyType:
            guard let button = relatedView as? BTFieldCustomButton else {
                return
            }
            
            let formatter = viewModel.fieldEditModel.fieldProperty.formatter
            viewModel.updateCurrencyProperty(formatter: formatter, currencyCode: item.id)

            button.setTitleString(text: item.name)
            button.setSubTitleString(text: item.rightSubtitle ?? "")
            
            viewController.dismiss(animated: true)
        default:
            break
        }
    }

    func didClickBackPage(relatedItemId: String,
                          action: String) {
        let fieldEditAction = BTFieldEditDataListViewAction(rawValue: action)
        switch fieldEditAction {
        case .updateFieldType:
            var params = ["click": "back",
                          "target": "ccm_bitable_field_modify_view",
                          "edit_type": self.editTypeStringForTracking,
                          "scene_type": self.sceneType]
            params["from_field_type"] = self.currentMode != .add ? self.viewModel.oldFieldEditModel.fieldTrackName : nil
            delegate?.trackEditViewEvent(eventType: .bitableFieldTypeModifyViewClick,
                                         params: params,
                                         fieldEditModel: self.viewModel.fieldEditModel)
        default:
            break
        }
    }
    
    func didClickDone(relatedItemId: String,
                      action: String) {}
    
    func didClickClose(relatedItemId: String,
                       action: String) {}
    
    func didClickMask(relatedItemId: String,
                      action: String) {}
    
    func checkFieldTypeChange(targetUIType: String, fieldType: String, sourceView: UIView, completion: @escaping () -> Void) {
        var args = BTFieldTypeChangeArgs(fieldId: self.viewModel.fieldEditModel.fieldId,
                                                             tableId: self.viewModel.fieldEditModel.tableId,
                                                             targetUIType: targetUIType)
        // 新增字段不用校验，直接change
        guard self.currentMode == .edit else {
            DocsLogger.btInfo("checkFieldTypeChange: current mode is not edit")
            completion()
            return
        }
        
        guard let dataService = dataService else {
            DocsLogger.btError("checkFieldTypeChange error, dataService is nil")
            return
        }
        
        dataService.checkFieldTypeChangeAPI(args: args) { [weak self] result in
            guard let extra = result["extra"] as? [String: Any] else {
                DocsLogger.btError("checkFieldTypeChange error, result is nil")
                return
            }
            
            guard let checkTypeConvert = extra["checkTypeConvert"] as? Bool else {
                DocsLogger.btError("checkFieldTypeChange error, checkTypeConvert is nil")
                return
            }
            
            if checkTypeConvert {
                DocsLogger.btInfo("checkFieldTypeChange: show UDActionSheet For Type Change")
                self?.showUDActionSheetForTypeChange(targetUIType: targetUIType, fieldType: fieldType, sourceView: sourceView, extra: extra) {
                    completion()
                }
            } else {
                DocsLogger.btInfo("checkFieldTypeChange: handle for type change with no UDActionSheet")
                if let supportAIConfig = extra["supportAIConfig"] as? Bool {
                    self?.viewModel.fieldEditModel.canShowAIConfig = supportAIConfig
                }
                completion()
            }
        }
    }
}

extension BTFieldEditController: BTOptionColorSelectDelegate {
    func didClickColor(color: BTColorModel, optionID: String) {
        guard let index = self.viewModel.options.firstIndex(where: { $0.id == optionID }) else { return }
        
        viewModel.options = viewModel.options.map { option in
            if option.id == optionID {
                var newOption = option
                newOption.color = color.id
                return newOption
            }
            
            return option
        }
        
        currentTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    private func updateFieldType(item: BTFieldCommonData,
                                 relatedItemId: String,
                                 relatedView: UIView?,
                                 action: String,
                                 viewController: UIViewController,
                                 sourceView: UIView?) {
        if let origin = item.reference as? FieldExtendOrigin {
            let data: [BTFieldCommonData] = origin.configs.reduce([]) { (partialResult, config) in
                partialResult + config.extendItems.map({ item in
                    BTFieldCommonData(
                        id: item.compositeType.typesId,
                        name: item.name,
                        groupId: config.fromInfo,
                        enable: !item.isChecked,
                        icon: item.compositeType.icon(),
                        showLighting: true,
                        selectedType: .none,
                        reference: (origin, item)
                    )
                })
            }
            let height = viewController.view.bounds.height
            let vc = BTFieldCommonDataListController(
                data: data,
                title: BundleI18n.SKResource.Bitable_PeopleField_ExtendableField_Title,
                action: BTFieldEditDataListViewAction.updateFieldExtendType.rawValue,
                disableItemClickBlock: { (sender, data) in
                    guard let (_, item) = data.reference as? (FieldExtendOrigin, FieldExtendConfigItem) else {
                        return
                    }
                    let fieldName = item.fieldName ?? item.name
                    let tips = BundleI18n.SKResource.Bitable_PeopleField_FieldHasCreated_Tooltip(fieldName)
                    UDToast.showTips(with: tips, on: sender.view)
                },
                initViewHeightBlock: { height }
            )
            vc.delegate = self
            Navigator.shared.push(vc, from: viewController)
            self.extendManager.trackExtendSubTypePanelView(origin: origin, sceneType: self.sceneType)
            OnboardingManager.shared.markFinished(for: [OnboardingID.bitableUserFieldExtendNew])
            return
        }
        self.viewModel.fieldEditModel.fieldExtendInfo = nil
        guard let types = BTFieldCompositeType.getTypesFormId(item.id) else { return }
        if UserScopeNoChangeFG.ZYS.fieldSupportExtend {
            let cpType = BTFieldCompositeType(fieldTypeValue: types.0, uiTypeValue: types.1)
            if cpType.isSupportFieldExt {
                OnboardingManager.shared.markFinished(for: [OnboardingID.bitableUserFieldExtendNew])
            }
        }
        self.changeFieldType(typeValue: types.0, uiTypeValue: types.1, hasNewTag: item.isShowNew) {
            viewController.navigationController?.popViewController(animated: true)
        }
    }

}

extension BTFieldEditController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        //代码触发的dismiss不会走到这里来
        delegate?.editViewDidDismiss()
        trackStadingOptionTypeTime()
        keyboard.stop()
        
        tracingDurationViewEvent()
        // 整体退出时，如果还显示了类型选择面板，要一起触发
        self.typeChoose?.removeFromParentBlock?()
    }
}

extension BTFieldEditController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        titleInputTextView.resignFirstResponder()
        return true
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if isPhoneLandscape {
            UDToast.showWarning(with: BundleI18n.SKResource.Doc_Block_NotSupportEditInLandscape, on: self.view)
        }
        return !isPhoneLandscape
    }
}

extension BTFieldEditController: BTAutoNumberTableCellDelegate {
    func didClickNoticeButton(id: String,
                              noticeButton: UIView,
                              cell: BTAutoNumberTableCell) {
        
        hasFieldSubSettingClick = true
        UDToast.showTips(with: cell.descriptionStr, on: self.view)
    }
    
    func didClickExpandButton(id: String, expandButton: UIView) {
        hasFieldSubSettingClick = true
        //打开日期格式选择列表
        resignFirstResponder()
        guard let dateList = viewModel.commonData.fieldConfigItem.commonAutoNumberRuleTypeList.last?.ruleFieldOptions.first(where: { $0.type == .createdTime })?.optionList else {
            return
        }
        let data = dateList.map { date in
            return BTFieldCommonData(id: date.format, name: date.text)
        }
        
        var selectedIndex = 0
        if let currentRuleValue = auotNumberRuleList.first(where: { $0.id == id })?.value {
            selectedIndex = dateList.firstIndex(where: { $0.text == currentRuleValue }) ?? 0
        }
        
        let dateFormateChooseList = BTFieldCommonDataListController(data: data,
                                                                    title: BundleI18n.SKResource.Bitable_BTModule_DateTimeFormat,
                                                                    action: BTFieldEditDataListViewAction.updateAutoNumberRuleDateFormat.rawValue,
                                                                    relatedItemId: id,
                                                                    lastSelectedIndexPath: IndexPath(row: selectedIndex, section: 0))
        dateFormateChooseList.delegate = self
        
        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentDraggableVCEmbedInNav(dateFormateChooseList, from: UIViewController.docs.topMost(of: self) ?? self)
        }
    }
    
    func didChangeRuleValue(id: String, value: String?) {
        hasFieldSubSettingClick = true
        //修改规则值
        auotNumberRuleList = auotNumberRuleList.map { rule in
            if rule.id == id {
                var rule = rule
                rule.value = value ?? ""
                return rule
            }
            
            return rule
        }
    }
    
    func didBeginEditRuleValue(id: String, cell: BTAutoNumberTableCell) {
        hasFieldSubSettingClick = true
        //开始编辑规则值
        editingFieldCell = cell
        if let index = auotNumberRuleList.firstIndex(where: { $0.id == id }) {
            editingFieldCellIndex = index
        }
    }
    
    func didEndEditRuleValue(id: String, cell: BTAutoNumberTableCell) {
        hasFieldSubSettingClick = true
        if let index = editingFieldCellIndex, index < auotNumberRuleList.count {
            currentTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
        
        editingFieldCell = nil
        editingFieldCellIndex = nil
    }
    
    func didChangeValue(id: String, cell: BTFieldEditCell) {
        guard let index = editingFieldCellIndex, let cell = editingFieldCell as? BTAutoNumberTableCell else { return }
        hasFieldSubSettingClick = true
        let showError = cell.hasError
        let cellHeight = cell.frame.height
        
        if (cellHeight == 52 && showError) || (cellHeight == 82 && !showError) {
            if showError {
                editingFieldCellHasErrorIndexs.append(index)
            } else {
                editingFieldCellHasErrorIndexs.removeAll(where: { $0 == index })
            }
            setSaveButtonEnable(enable: editingFieldCellHasErrorIndexs.count == 0)
            
            //不触发cellForRowAt，触发cellForRowAt会导致输入框失焦
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            currentTableView.performBatchUpdates(nil)
            CATransaction.commit()
            cell.showErrorLabel(show: showError, text: BundleI18n.SKResource.Bitable_Field_AutoIdReachCharacterLimit(18))
            currentTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .bottom, animated: false)
        }
    }
}

//埋点上报
extension BTFieldEditController {
    func tracingSpecialFieldTypeSaveEvent() {
        var eventType: DocsTracker.EventType?
        var params: [String: Any] = ["click": "confirm",
                                     "target": "none"]

        let stringForTrack = self.viewModel.fieldEditModel.fieldTrackName
        
        switch viewModel.fieldEditModel.compositeType.uiType {
        case .attachment:
            eventType = .bitableAttachmentFieldModifyViewClick
            params["is_phone_restricted"] = viewModel.fieldEditModel.fieldProperty.capture.count > 0
        case .dateTime, .createTime, .lastModifyTime:
            eventType = .bitableTimeFieldModifyClick
            params["field_type"] = stringForTrack
            params["is_auto_add_create_time"] = viewModel.fieldEditModel.fieldProperty.autoFill
        case .user:
            eventType = .bitableMemberFieldModifyViewClick
            params["is_allow_adding_multiple_members"] = viewModel.fieldEditModel.fieldProperty.multiple
        case .group:
            eventType = .bitableGroupFieldModifyViewClick
            params["is_multi_group"] = viewModel.fieldEditModel.fieldProperty.multiple
        case .duplexLink, .singleLink:
            eventType = .bitableFieldModifyViewClick
            params["field_type"] = stringForTrack
            params["is_allow_adding_multiple_records"] = viewModel.fieldEditModel.fieldProperty.multiple
            params["range"] = viewModel.fieldEditModel.isLinkAllRecord ? "all_records" : "specific_records"
            params["condition_num"] = viewModel.fieldEditModel.isLinkAllRecord ? 0 : (viewModel.linkTableFilterInfo?.conditions.count ?? 0)
            params["link_table_id"] = DocsTracker.encrypt(id: viewModel.fieldEditModel.fieldProperty.tableId)
        default:
            break
        }
        
        guard let eventType = eventType else {
            return
        }
        
        self.delegate?.trackEditViewEvent(eventType: eventType,
                                          params: params,
                                          fieldEditModel: viewModel.fieldEditModel)
    }
    
    /// action_type 字段埋点值 https://bytedance.feishu.cn/sheets/shtcncmLQisYoUNgor6E4JvUiGd?sheet=JrmGUA
    var actionTypeStringForTracking: String {
        switch self.currentMode {
        case .edit:
            return "existed_field"
        case .add:
            return "new_field"
        }
    }
    
    /// edit_type 字段埋点值 https://bytedance.feishu.cn/sheets/shtcncmLQisYoUNgor6E4JvUiGd?sheet=JrmGUA
    var editTypeStringForTracking: String {
        switch self.currentMode {
        case .edit:
            return "switch"
        case .add:
            return "new_field"
        }
    }
    
    func tracingFiledSubSettingClick() {
        guard hasFieldSubSettingClick else {
            return
        }
        delegate?.trackEditViewEvent(eventType: .bitableFieldModifyViewClick,
                                          params: ["click": "field_sub_setting",
                                                   "action_type": self.actionTypeStringForTracking,
                                                   "scene_type": self.sceneType,
                                                   "field_type": viewModel.fieldEditModel.fieldTrackName],
                                          fieldEditModel: viewModel.fieldEditModel)
    }
    
    func tracingDurationViewEvent() {
        guard let delegate = delegate else {
            DocsLogger.warning("delegate is nil")
            return
        }
        var params: [String: Any] = [
            "field_type": viewModel.fieldEditModel.fieldTrackName,
            "action_type": self.actionTypeStringForTracking,
            "duration": Int((Date().timeIntervalSince(openTime)) * 1000),
            "is_extend": viewModel.isCurrentExtendChildType ? "true" : "false",
        ]
        if let extInfo = viewModel.fieldEditModel.fieldExtendInfo?.extendInfo {
            params["extend_from_field_type"] = extInfo.originFieldUIType.fieldTrackName
            params["extend_field_type"] = extInfo.extendFieldType
        }
        delegate.trackEditViewEvent(
            eventType: .bitableFieldModifyDurationView,
            params: params,
            fieldEditModel: viewModel.fieldEditModel
        )
    }
}

extension BTFieldEditController {
    func didClickItem(viewIdentify: String, index: Int) {
        guard let fieldEditLynxAction = BTFieldEditPageAction(rawValue: viewIdentify) else {
            return
        }

        let stringForTrack = self.viewModel.fieldEditModel.fieldTrackName
        switch fieldEditLynxAction {
        case .autoNumberTypeSelect, .optionsTypeSelect:
            didClickChangeType(index: index)
        case .autoNumberRuleSelect:
            didClickAddRuleType(index: index)
        case .dynamicOptionsConjunctionSelect:
            //更新级联选项规则组合方式
            viewModel.dynamicOptionRuleConjunction = index == 0 ? "and" : "or"
            delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                         params: ["click": index == 0 ? "all_condition" : "any_condition",
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
            updateUI(fieldEditModel: viewModel.fieldEditModel)
        case .linkTableFilterTypeSelect:
            didChangeLinkTableRange(isLinkAllRecord: index == 0)
            delegate?.trackEditViewEvent(eventType: .bitableRelationFieldModifyViewClick,
                                         params: ["click": index == 0 ? "all_records" : "specific_records",
                                                  "field_type": stringForTrack,
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
        case .linkTableFilterConjunctionSelect:
            let conjunction: BTConjunctionType = index == 0 ? .And : .Or
            didChangeLinkFieldFilterConjunction(conjunction)
            delegate?.trackEditViewEvent(eventType: .bitableRelationFieldModifyViewClick,
                                         params: ["click": index == 0 ? "all_condition" : "any_condition",
                                                  "field_type": stringForTrack,
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
        case .geoLocationInputTypeSelect:
            guard BTGeoLocationInputType.allCases.count > index else {
                DocsLogger.btError("geoLocationInputTypeSelect index error: \(index)")
                return
            }
            let newType = BTGeoLocationInputType.allCases[index]
            self.viewModel.fieldEditModel.fieldProperty.inputType = newType
            self.viewManager?.updateData(commonData: self.viewModel.commonData, fieldEditModel: self.viewModel.fieldEditModel)
        }
    }
    
    func didClickChangeType(index: Int) {
        let fieldType = viewModel.fieldEditModel.compositeType.uiType
        if fieldType == .autoNumber {
            viewModel.fieldEditModel.fieldProperty.isAdvancedRules = index == 1
        } else if fieldType.classifyType == .option {
            viewModel.fieldEditModel.fieldProperty.optionsType = index == 0 ? .staticOption : .dynamicOption

            if viewModel.fieldEditModel.fieldProperty.optionsType == .staticOption,
               viewModel.oldFieldEditModel.fieldProperty.optionsType == .dynamicOption {
                //由级联选项变更为静态选项，需要把级联表格中的选择转换为静态选项
                let params: [String: Any] = ["router": BTAsyncRequestRouter.getBitableFieldOptions.rawValue,
                                             "tableId": viewModel.oldFieldEditModel.tableId,
                                             "data": ["tableId": viewModel.oldFieldEditModel.tableId,
                                                      "fieldId": viewModel.oldFieldEditModel.fieldId,
                                                      "senceType": "fieldEdit"]]
                dataService?.asyncJsRequest(biz: .card,
                                            funcName: .asyncJsRequest,
                                            baseId:  viewModel.oldFieldEditModel.baseId,
                                            tableId: viewModel.oldFieldEditModel.tableId,
                                            params: params,
                                            overTimeInterval: nil,
                                            responseHandler: responseHandler,
                                            resultHandler: nil)
            }
            
            delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                         params: ["click": index == 0 ? "custom_data" : "quote_data",
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
        } else if fieldType.classifyType == .link {
            viewModel.fieldEditModel.isLinkAllRecord = index == 0
        }
        updateUI(fieldEditModel: viewModel.fieldEditModel)
    }
}

extension BTFieldEditController: BTFieldEditViewManagerDelegate {
    
    func setTableHeaderViewHeight(height: CGFloat) {
        self.currentTableView.tableHeaderView?.frame.size.height = height
    }
    
    @objc
    func didClickAiExtensionButton(button sender: BTFieldCustomButton)  {
        let args = BTShowAiConfigFormArgs(isNewField: currentMode == .add,
                                          baseId: self.viewModel.fieldEditModel.baseId,
                                          fieldId: self.viewModel.fieldEditModel.fieldId,
                                          fieldUIType: self.viewModel.fieldEditModel.compositeType.uiType.rawValue)
        
        dataService?.showAiConfigFormAPI(args: args, completion: {})
        
        self.delegate?.trackEditViewEvent(eventType: .bitableFieldModifyViewClick,
                                          params: ["click": "ai_generate",
                                                   "target": "ccm_bitable_ai_generate_field_view",
                                                   "action_type": self.actionTypeStringForTracking,
                                                   "scene_type": self.sceneType,
                                                   "field_type": viewModel.fieldEditModel.fieldTrackName],
                                          fieldEditModel: viewModel.fieldEditModel)
    }
    
    func didClickChooseDateType(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        let dateFormateList = viewModel.commonData.fieldConfigItem.commonDateTimeList
        
        let data = dateFormateList.map { dateFormate in
            return BTFieldCommonData(id: dateFormate.id,
                                     name: dateFormate.text)
        }
        
        let index = dateFormateList.firstIndex {
            viewModel.fieldEditModel.fieldProperty.isMapDateFormat($0)
        }
        
        let tableList = BTFieldCommonDataListController(data: data,
                                                        title: BundleI18n.SKResource.Bitable_BTModule_DateTimeFormat,
                                                        action: BTFieldEditDataListViewAction.updateDateFormat.rawValue,
                                                        shouldShowDoneButton: true,
                                                        relatedView: button,
                                                        lastSelectedIndexPath: IndexPath(row: index ?? 0, section: 0))
        tableList.delegate = self
        
        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentDraggableVCEmbedInNav(tableList, from: UIViewController.docs.topMost(of: self) ?? self, completion: {
                let stringForTrack = self.viewModel.fieldEditModel.fieldTrackName
                self.delegate?.trackEditViewEvent(eventType: .bitableTimeFieldFormatModifyView,
                                                  params: ["time_type": stringForTrack],
                                                  fieldEditModel: self.viewModel.fieldEditModel)})
        }
    }
    
    ///修改数字字段数字格式
    func didClickChooseNumberType(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        var numberFormateList = viewModel.commonData.fieldConfigItem.commonNumberFormatList
        var currency: BTCurrencyCodeList?
        if viewModel.fieldEditModel.compositeType.uiType == .currency {
            numberFormateList = viewModel.commonData.fieldConfigItem.commonCurrencyDecimalList
            let currencyTypeList = viewModel.commonData.fieldConfigItem.commonCurrencyCodeList
            currency = currencyTypeList.first(where: { $0.currencyCode == viewModel.fieldEditModel.fieldProperty.currencyCode })
        }
        
        //数字字段旧数据选中的的非货币格式或新增数字字段，不显示货币格式，
        var shouldShowNumberCurrencyFormatter = false
        if viewModel.oldFieldEditModel.compositeType.uiType == .number,
           let selectedNumberFormatter = numberFormateList.first(where: { $0.formatCode == viewModel.fieldEditModel.fieldProperty.formatter }) {
            //数字字段旧数据选中的为货币格式，显示货币格式，置灰处理
            shouldShowNumberCurrencyFormatter = (selectedNumberFormatter.type == FormatterType.currency.rawValue)
        }
        
        let data = numberFormateList.compactMap { numberFormate in
            if viewModel.fieldEditModel.compositeType.uiType == .currency {
                return BTFieldCommonData(id: numberFormate.formatCode,
                                         name: numberFormate.name, rightSubtitle: (currency?.currencySymbol ?? "") + numberFormate.sample)
            }

            if !shouldShowNumberCurrencyFormatter, numberFormate.type == FormatterType.currency.rawValue {
                return nil
            }
            
            return BTFieldCommonData(id: numberFormate.formatCode,
                                     name: numberFormate.name,
                                     enable: numberFormate.type != FormatterType.currency.rawValue)
        }

        let defaultNumberItem = viewModel.commonData.fieldConfigItem.fieldItems.first(where: { $0.compositeType == viewModel.fieldEditModel.compositeType })
        let defaultIndex = defaultNumberItem?.property.defaultNumberFormatIndex ?? 0
        
        var currencyFormatCode = ""
        
        if let currency = currency {
            currencyFormatCode = currency.formatCode
        }
        
        let index = numberFormateList.firstIndex(where: { currencyFormatCode + $0.formatCode == viewModel.fieldEditModel.fieldProperty.formatter }) ?? defaultIndex
        
        let tableList = BTFieldCommonDataListController(data: data,
                                                        title: BundleI18n.SKResource.Bitable_Field_NumberFormat,
                                                        action: BTFieldEditDataListViewAction.updateNumberFormat.rawValue,
                                                        relatedView: button,
                                                        disableItemClickBlock: { [weak self] (hostVC, item) in
            //旧版数字字段货币格式兼容
            guard let self = self else { return }
            UDToast.showTips(with: BundleI18n.SKResource.Bitable_Currency_NowSupportCurrencyField_Toast,
                             operationText: BundleI18n.SKResource.Bitable_Currency_SwitchToCurrencyField_Button,
                             on: hostVC.view,
                             operationCallBack: { _ in
                //转换到货币字段，需要dismiss之前的VC
                hostVC.dismiss(animated: true)
                self.viewModel.fieldEditModel.fieldProperty.formatter = item.id
                self.viewModel.covertNumberAndCurrency(fieldType: .number, uiType: BTFieldUIType.currency.rawValue)
                self.viewModel.fieldEditModel.update(fieldType: .number, uiType: BTFieldUIType.currency.rawValue)
                self.updateUI(fieldEditModel: self.viewModel.fieldEditModel)
            })
        },
                                                        lastSelectedIndexPath: IndexPath(row: index, section: 0))
        tableList.delegate = self
        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentDraggableVCEmbedInNav(tableList, from: UIViewController.docs.topMost(of: self) ?? self, completion: {
                self.delegate?.trackEditViewEvent(eventType: .bitableNumberFieldModifyView,
                                                  params: [:],
                                                  fieldEditModel: self.viewModel.fieldEditModel)
            })
        }
    }
    
    ///修改货币字段类型
    func didClickChooseCurrencyType(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        let currencyTypeList = viewModel.commonData.fieldConfigItem.commonCurrencyCodeList
        
        let data = currencyTypeList.map { currencyType in
            return BTFieldCommonData(id: currencyType.currencyCode, name: currencyType.currencyCode + "-" + currencyType.currencySymbol, rightSubtitle: currencyType.name)
        }
        
        let index = currencyTypeList.firstIndex(where: { $0.currencyCode == viewModel.fieldEditModel.fieldProperty.currencyCode }) ?? 0
        
        let tableList = BTFieldCommonDataListController(data: data,
                                                        title: BundleI18n.SKResource.Bitable_Currency_Title,
                                                        action: BTFieldEditDataListViewAction.updateCurrencyType.rawValue,
                                                        relatedView: button,
                                                        lastSelectedIndexPath: IndexPath(row: index, section: 0))
        tableList.delegate = self
        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentDraggableVCEmbedInNav(tableList, from: UIViewController.docs.topMost(of: self) ?? self, completion: nil)
        }
    }
    

    ///修改进度条字段数字格式
    func didClickChooseProgressType(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        
        guard let defaultDataItem = viewModel.commonData.fieldConfigItem.fieldItems.first(where: { $0.compositeType == viewModel.fieldEditModel.compositeType }) else {
            DocsLogger.error("defaultDataItem not found")
            return
        }
        guard let types = defaultDataItem.property.formatConfig?.types else {
            DocsLogger.error("defaultDataItem types invalid")
            return
        }
        
        guard let currentConfig = viewModel.commonData.fieldConfigItem.getCurrentFormatConfig(fieldEditModel: viewModel.fieldEditModel) else {
            DocsLogger.error("defaultDataItem currentConfig invalid")
            return
        }
        
        guard let index = types.firstIndex(where: { typeConfig in
            return typeConfig.type == currentConfig.typeConfig.type
        }) else {
            DocsLogger.error("defaultDataItem type index not found")
            return
        }
        
        let data: [BTFieldCommonData] = types.map({ typeConfig in
            return BTFieldCommonData(id: typeConfig.getFormatCode(decimalDigits: typeConfig.defaultDecimalDigits), name: typeConfig.getFormatTypeName())
        })
        
        let tableList = BTFieldCommonDataListController(data: data,
                                                        title: BundleI18n.SKResource.Bitable_Progress_NumberFormat_Title,
                                                        action: BTFieldEditDataListViewAction.updateProgressNumberType.rawValue,
                                                        relatedView: button,
                                                        lastSelectedIndexPath: IndexPath(row: index, section: 0))
        tableList.delegate = self
        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentDraggableVCEmbedInNav(tableList, from: UIViewController.docs.topMost(of: self) ?? self, completion: {
            })
        }
    }
    
    ///修改进度条字段数字小数位数
    func didClickChooseProgressNumberType(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        guard let defaultDataItem = viewModel.commonData.fieldConfigItem.fieldItems.first(where: { $0.compositeType == viewModel.fieldEditModel.compositeType }) else {
            DocsLogger.error("defaultDataItem not found")
            return
        }
        guard let types = defaultDataItem.property.formatConfig?.types else {
            DocsLogger.error("defaultDataItem types invalid")
            return
        }
        
        guard let currentConfig = viewModel.commonData.fieldConfigItem.getCurrentFormatConfig(fieldEditModel: viewModel.fieldEditModel) else {
            DocsLogger.error("defaultDataItem currentConfig invalid")
            return
        }
        
        guard let index = currentConfig.typeConfig.decimalDigits.firstIndex(where: { decimalDigits in
            return decimalDigits == currentConfig.decimalDigits
        }) else {
            DocsLogger.error("defaultDataItem decimalDigits index not found")
            return
        }
        
        let data: [BTFieldCommonData] = currentConfig.typeConfig.decimalDigits.map({ decimalDigits in
            let formatCode = currentConfig.typeConfig.getFormatCode(decimalDigits: decimalDigits)
            let formatName = currentConfig.typeConfig.getFormatDecimalDigitsName(decimalDigits: decimalDigits)
            let formatExample = currentConfig.typeConfig.getFormatExample(decimalDigits: decimalDigits)
            return BTFieldCommonData(
                id: formatCode,
                name: formatName,
                rightSubtitle: formatExample
            )
        })
        
        let tableList = BTFieldCommonDataListController(data: data,
                                                        title: BundleI18n.SKResource.Bitable_Progress_DecimalPlaces_Title,
                                                        action: BTFieldEditDataListViewAction.updateProgressNumberDigits.rawValue,
                                                        relatedView: button,
                                                        lastSelectedIndexPath: IndexPath(row: index, section: 0))
        tableList.delegate = self
        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentDraggableVCEmbedInNav(tableList, from: UIViewController.docs.topMost(of: self) ?? self, completion: {
                
            })
        }
    }
    
    func didClickChooseProgressColor(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        guard let colorConfig = viewModel.commonData.fieldConfigItem.getCurrentColorConfig(fieldEditModel: viewModel.fieldEditModel) else {
            DocsLogger.error("colorConfig invalid")
            return
        }
        let picker = BTProgressColorPickerViewController(
            colors: colorConfig.colors,
            selectedColor: colorConfig.selectedColor,
            relatedView: button
        )
        picker.delegate = self
        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentDraggableVCEmbedInNav(picker, from: UIViewController.docs.topMost(of: self) ?? self, completion: {
            })
        }
    }

    /// 修改关联字段关联数据表
    func didClickChooseRelatedTable(button: BTFieldCustomButton) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        let data: [BTFieldCommonData]
        var lastSelectedIndexPath: IndexPath?
        var showHiddenTableFooter = false
        if UserScopeNoChangeFG.ZYS.integrationBase {
            data = viewModel.fieldEditModel.tableNameMap.compactMap { table in
                if viewModel.fieldEditModel.compositeType.uiType == .duplexLink && table.isSyncTable {
                    // 双向关联不支持选择同步表
                    return nil
                }
                if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                    if table.isPartialDenied == true {
                        // 只要筛掉了部分无权限的表就展示提示
                        showHiddenTableFooter = true
                        // 部分无权限需要筛选
                        return nil
                    }
                }
                return BTFieldCommonData(
                    id: table.tableId,
                    name: table.tableName,
                    icon: UDIcon.getIconByKey(.sheetBitableOutlined, iconColor: UDColor.iconN1)
                )
            }
            if let index = data.firstIndex(where: { $0.id == viewModel.fieldEditModel.fieldProperty.tableId }) {
                lastSelectedIndexPath = IndexPath(row: index, section: 0)
            }
        } else {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                data = viewModel.fieldEditModel.tableNameMap.compactMap { table in
                    if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                        if table.isPartialDenied == true {
                            // 只要筛掉了部分无权限的表就展示提示
                            showHiddenTableFooter = true
                            // 部分无权限需要筛选
                            return nil
                        }
                    }
                    return BTFieldCommonData(id: table.tableId,
                                             name: table.tableName,
                                             icon: UDIcon.getIconByKey(.sheetBitableOutlined, iconColor: UDColor.iconN1))
                }
            } else {
            data = viewModel.fieldEditModel.tableNameMap.map { table in
                return BTFieldCommonData(id: table.tableId,
                                         name: table.tableName,
                                         icon: UDIcon.getIconByKey(.sheetBitableOutlined, iconColor: UDColor.iconN1))
            }
            }
            if let index = viewModel.fieldEditModel.tableNameMap.firstIndex(where: { $0.tableId == viewModel.fieldEditModel.fieldProperty.tableId }) {
                lastSelectedIndexPath = IndexPath(row: index, section: 0)
            }
        }
        let tableList = BTFieldCommonDataListController(data: data,
                                                        title: BundleI18n.SKResource.Bitable_Field_LinkToTable,
                                                        action: BTFieldEditDataListViewAction.updateRelatedTable.rawValue,
                                                        shouldShowDragBar: true,
                                                        relatedView: button,
                                                        lastSelectedIndexPath: lastSelectedIndexPath,
                                                        showHiddenTableFooter: showHiddenTableFooter)
        tableList.delegate = self
        
        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentDraggableVCEmbedInNav(tableList, from: UIViewController.docs.topMost(of: self) ?? self, completion: {
                let stringForTrack = self.viewModel.fieldEditModel.fieldTrackName
                self.delegate?.trackEditViewEvent(eventType: .bitableRelationFieldModifyViewClick,
                                                  params: ["click": "select_table",
                                                           "field_type": stringForTrack,
                                                           "target": "none"],
                                                  fieldEditModel: self.viewModel.fieldEditModel)
            })
        }
    }
    
    ///修改自动编号字段编号类型
    func didClickChooseAutoNumberType() {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        let defaultSelectedIndex = viewModel.fieldEditModel.fieldProperty.isAdvancedRules ? 1 : 0
        var ruleTypeVC: BTPanelController?
        
        let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
            guard let self = self, let itemId = id else { return }
            let index = Int(itemId) ?? 0
            self.didClickItem(viewIdentify: BTFieldEditPageAction.autoNumberTypeSelect.rawValue, index: index)
            // 关闭当前选择面板
            ruleTypeVC?.dismiss(animated: true)
        }
        var index = -1
        let dataList = viewModel.commonData.fieldConfigItem.commonAutoNumberRuleTypeList.compactMap { type -> BTCommonDataItem in
            index =  index + 1
            return BTCommonDataItem(id: String(index),
                                    selectable: false,
                                    selectCallback: selectCallback,
                                    leftIcon: .init(image: index == defaultSelectedIndex ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                                    size: CGSize(width: 20, height: 20),
                                                    alignment: .top(offset: 0)),
                                    mainTitle: .init(text: type.title),
                                    subTitle: .init(text: type.description, lineNumber: 0))
        }
        
        ruleTypeVC = BTPanelController(title: BundleI18n.SKResource.Bitable_SingleOption_SubsetCondition,
                                       data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "autoNumberType",
                                                                                          items: dataList)]),
                                       delegate: nil,
                                       hostVC: self,
                                       baseContext: baseContext)
        ruleTypeVC?.setCaptureAllowed(true)
        ruleTypeVC?.automaticallyAdjustsPreferredContentSize = false
        
        guard let ruleTypeVC = ruleTypeVC else { return }
        
        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentSKPanelVCEmbedInNav(ruleTypeVC, from: UIViewController.docs.topMost(of: self) ?? self)
        }
    }
    
    func didClickCheckBox(isSelected: Bool) {

        hasFieldSubSettingClick = true
        let trackString = self.viewModel.fieldEditModel.fieldTrackName
        switch viewModel.fieldEditModel.compositeType.uiType {
        case let type where type.classifyType == .date:
            viewModel.fieldEditModel.fieldProperty.autoFill = isSelected
            delegate?.trackEditViewEvent(eventType: .bitableTimeFieldModifyClick,
                                         params: ["click": "auto_add_create_time",
                                                  "target": "none",
                                                  "field_type": trackString,
                                                  "is_auto_add_create_time": isSelected],
                                         fieldEditModel: viewModel.fieldEditModel)
        case let type where type.classifyType == .link:
            viewModel.fieldEditModel.fieldProperty.multiple = isSelected
            delegate?.trackEditViewEvent(eventType: .bitableRelationFieldModifyViewClick,
                                         params: ["click": "allow_adding_multiple_records",
                                                  "target": "none",
                                                  "field_type": trackString,
                                                  "is_allow_adding_multiple_records": isSelected],
                                         fieldEditModel: viewModel.fieldEditModel)
        case .attachment:
            viewModel.fieldEditModel.fieldProperty.capture = isSelected ? ["environment", "user"] : []
            delegate?.trackEditViewEvent(eventType: .bitableAttachmentFieldModifyViewClick,
                                         params: ["click": "allow_only_phone_images",
                                                  "target": "none",
                                                  "is_phone_restricted": isSelected],
                                         fieldEditModel: viewModel.fieldEditModel)
        case .user:
            let currentValue = viewModel.fieldEditModel.fieldProperty.multiple
            viewModel.fieldEditModel.fieldProperty.multiple = isSelected
            handleUserMultipleClick(valueChanged: currentValue != isSelected)
            delegate?.trackEditViewEvent(eventType: .bitableMemberFieldModifyViewClick,
                                         params: ["click": "allow_adding_multiple_members",
                                                  "target": "none",
                                                  "is_allow_adding_multiple_members": isSelected],
                                         fieldEditModel: viewModel.fieldEditModel)
        case .group:
            // 群组切换不用埋点
            viewModel.fieldEditModel.fieldProperty.multiple = isSelected
        case .barcode:
            let isManual = !isSelected
            viewModel.fieldEditModel.allowedEditModes?.manual = isManual
            delegate?.trackEditViewEvent(eventType: .bitableScanFieldModifyClick,
                                         params: ["click": (isManual ? "manual_on" : "manual_off")],
                                         fieldEditModel: viewModel.fieldEditModel)
        case .progress:
            viewModel.fieldEditModel.fieldProperty.rangeCustomize = isSelected
            if !isSelected {
                // 关开关就重置为默认值
                viewModel.fieldEditModel.fieldProperty.min = nil
                viewModel.fieldEditModel.fieldProperty.max = nil
                let rangeConfig = viewModel.commonData.fieldConfigItem.getCurrentRangeConfig(fieldEditModel: viewModel.fieldEditModel)
                viewModel.fieldEditModel.fieldProperty.min = rangeConfig.min
                viewModel.fieldEditModel.fieldProperty.max = rangeConfig.max
            }
            updateUI(fieldEditModel: viewModel.fieldEditModel)
            delegate?.trackEditViewEvent(eventType: .bitableProgressFieldModifyClick,
                                         params: ["click": "customized_progress", // customized_progress: 点击开启或关闭「自定义进度条值」时上报
                                                  "switch_type": (isSelected ? "switch_on" : "switch_off"),
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
        default:
            break
        }
    }
    func didClickChooseLocationInputType() {
        
        hasFieldSubSettingClick = true
        let defaultTypeIndex = BTGeoLocationInputType.allCases.firstIndex(where: { $0 == viewModel.fieldEditModel.fieldProperty.inputType }) ?? 0
        var vc: BTPanelController?
        
        let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
            guard let self = self, let itemId = id else { return }
            let index = Int(itemId) ?? 0
            self.didClickItem(viewIdentify: BTFieldEditPageAction.geoLocationInputTypeSelect.rawValue, index: index)
            // 关闭当前选择面板
            vc?.dismiss(animated: true)
        }
        
        var index = -1
        let dataList = BTGeoLocationInputType.allCases.map {
            index =  index + 1
            return BTCommonDataItem(id: String(index),
                                    selectable: false,
                                    selectCallback: selectCallback,
                                    leftIcon: .init(image: index == defaultTypeIndex ? BundleResources.SKResource.Bitable.icon_bitable_selected : BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                                    size: CGSize(width: 20, height: 20)),
                                    mainTitle: .init(text: $0.displayText))
        }
        
        vc = BTPanelController(title: BundleI18n.SKResource.Bitable_Field_LocateMethodMobileVer,
                               data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "locationInputType",
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
    
    func didFieldInputEditBegin(fieldInputView: BTFieldInputView) {
        hasFieldSubSettingClick = true
        editingView = fieldInputView
        
        switch fieldInputView.type {
        case .min:
            editingViewKeyboardSpace = 0.5 + 52.0 + 36.0
            if let min = viewModel.fieldEditModel.fieldProperty.min {
                fieldInputView.inputTextField.text = BTFormatTypeConfig.format(min)
            } else {
                fieldInputView.inputTextField.text = ""
            }
            // 默认光标在末尾
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                let endOfDocument = fieldInputView.inputTextField.endOfDocument
                fieldInputView.inputTextField.selectedTextRange = fieldInputView.inputTextField.textRange(from: endOfDocument, to: endOfDocument)
            }
            CATransaction.commit()
        case .max:
            editingViewKeyboardSpace = 36.0
            if let max = viewModel.fieldEditModel.fieldProperty.max {
                fieldInputView.inputTextField.text = BTFormatTypeConfig.format(max)
            } else {
                fieldInputView.inputTextField.text = ""
            }
            // 默认光标在末尾
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                let endOfDocument = fieldInputView.inputTextField.endOfDocument
                fieldInputView.inputTextField.selectedTextRange = fieldInputView.inputTextField.textRange(from: endOfDocument, to: endOfDocument)
            }
            CATransaction.commit()
        }
    }
    
    func didFieldInputEditEnd(fieldInputView: BTFieldInputView) {
        hasFieldSubSettingClick = true
        if editingView == fieldInputView {
            editingView = nil
        }
        switch fieldInputView.type {
        case .min:
            delegate?.trackEditViewEvent(eventType: .bitableProgressFieldModifyClick,
                                         params: ["click": "min", // min：对「起点值」进行设置
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
            if let text = fieldInputView.inputTextField.text {
                if text.isEmpty {
                    viewModel.fieldEditModel.fieldProperty.min = nil
                } else if let value = Double(text) {
                    viewModel.fieldEditModel.fieldProperty.min = value
                } else {
                    // 数字格式错误什么也不做
                }
            } else {
                fieldInputView.inputTextField.text = ""
                viewModel.fieldEditModel.fieldProperty.min = nil
            }
            updateUI(fieldEditModel: viewModel.fieldEditModel)
        case .max:
            delegate?.trackEditViewEvent(eventType: .bitableProgressFieldModifyClick,
                                         params: ["click": "max", // max：对「终点值」进行设置
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
            if let text = fieldInputView.inputTextField.text {
                if text.isEmpty {
                    viewModel.fieldEditModel.fieldProperty.max = nil
                } else if let value = Double(text) {
                    viewModel.fieldEditModel.fieldProperty.max = value
                } else {
                    // 数字格式错误什么也不做
                }
            } else {
                fieldInputView.inputTextField.text = ""
                viewModel.fieldEditModel.fieldProperty.max = nil
            }
            updateUI(fieldEditModel: viewModel.fieldEditModel)
        }
    }
}

extension BTFieldEditController: BTProgressColorPickerViewControllerDelegate {
    func didSelectedColor(color: BTColor, relatedView: UIView?) {
        hasFieldSubSettingClick = true
        delegate?.trackEditViewEvent(eventType: .bitableProgressFieldModifyClick,
                                     params: ["click": "color", // color: 选择进度条颜色时上报
                                              "color_id": color.id,
                                              "target": "none"],
                                     fieldEditModel: viewModel.fieldEditModel)
        
        
        guard let button = relatedView as? BTFieldColorButton else {
            DocsLogger.error("relatedView invalid")
            return
        }
        
        if var progress = viewModel.fieldEditModel.fieldProperty.progress {
            progress.color = color
        } else {
            viewModel.fieldEditModel.fieldProperty.progress = BTProgressModel(color: color)
        }
        viewModel.fieldEditModel.fieldProperty.progress?.color = color
        button.colorView.progressColor = color
        button.setTitleString(text: color.name ?? "")
    }
}
