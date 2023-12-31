//
//  BTFIlterManagerExtensions.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/28.
//  


import SKFoundation
import SKUIKit
import UniverseDesignToast


extension BTFilterManager {
    
    // 这里是对业务的扩展方法，为了复用
    func ex_showFilterFlowPanel(conditionIndex: Int,
                                conditionCell: UITableViewCell,
                                subCellIndex: Int,
                                subCell: UICollectionViewCell?,
                                filterInfos: BTFilterInfos,
                                filterOptions: BTFilterOptions,
                                linkCellModels: [BTLinkFieldFilterCellModel],
                                hostVC: UIViewController,
                                successHanler: ((BTFilterCondition) -> Void)?,
                                failHandler: (() -> Void)?) {
        let conditions = filterInfos.conditions
        guard conditions.count == linkCellModels.count,
              conditions.count > conditionIndex else {
            DocsLogger.btError("showFilterFlowPanel conditionIndex wrong")
            failHandler?()
            return
        }
        let cellModel = linkCellModels[conditionIndex]
        var filterCondition = conditions[conditionIndex]
        let step = BTFilterHelper.getFilterStep(by: subCellIndex)
        let result = BTFilterHelper.checkFilterConditionStepValid(step: step,
                                                                  filterCondition: &filterCondition,
                                                                  filterOptions: filterOptions,
                                                                  fieldErrorType: cellModel.fieldErrorType)
        guard result.isValid else {
            // 字段删除场景，需先选择字段
            if let toast = result.toast {
                UDToast.showWarning(with: toast, on: hostVC.view)
            }
            failHandler?()
            return
        }
        if cellModel.valueFieldType == .checkbox && subCellIndex != 0 {
            // CheckBox 类型
            guard let subCell = subCell as? BTConditionCheckBoxCell else {
                failHandler?()
                return
            }
            let newValue = subCell.checkButton.isSelected ? [false] : [true]
            filterCondition.value = newValue
            successHanler?(filterCondition)
            return
        }
        
        var popoverArgs: BTFilterPopoverArgs?
        if SKDisplay.pad && hostVC.isMyWindowRegularSize() {
            let sourceView = subCell ?? conditionCell
            popoverArgs = BTFilterPopoverArgs(sourceView: sourceView, sourceRect: sourceView.bounds)
        }
        self.showFilterFlowPanel(startStep: step,
                                 condition: filterCondition,
                                 popoverArgs: popoverArgs,
                                 finishSelectHandler: successHanler,
                                 cancelHandler: failHandler)
    }
}
