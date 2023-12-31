//
//  BTFieldEditController+FieldExtend.swift
//  SKBitable
//
//  Created by zhysan on 2023/3/31.
//

import SKFoundation
import EENavigator
import UniverseDesignToast
import UniverseDesignNotice
import SKResource

extension BTFieldEditController {
    func extendDataInit() {
        extendManager.asyncUpdateFieldExtendConfigs(editModel: viewModel.fieldEditModel)
        extendManager.asyncUpdateExtendableFields(editModel: viewModel.fieldEditModel)
    }
    
    func asyncReloadExtendConfigsDueToFieldTypeChange() {
        extendManager.resetFieldExtendContext()
        extendManager.asyncUpdateFieldExtendConfigs(editModel: viewModel.fieldEditModel)
    }
    
    func insertExtendConfigDisableReason(_ reason: ExtraExtendDisableReason) {
        footerView.extFooter.insertDisableReason(reason)
    }
    
    func removeExtendConfigDisableReason(_ reason: ExtraExtendDisableReason) {
        footerView.extFooter.removeDisableReason(reason)
    }
    
    func handleUserMultipleClick(valueChanged: Bool) {
        let supportMultiple = viewModel.fieldEditModel.fieldProperty.multiple
        if supportMultiple  {
            insertExtendConfigDisableReason(.notSupportMultiple)
        } else {
            removeExtendConfigDisableReason(.notSupportMultiple)
        }
        if valueChanged, extendManager.clearOperations() {
            // 单选多选切换，清空用户的扩展配置操作，重置为默认配置
            updateUI(fieldEditModel: viewModel.fieldEditModel)
        }
        guard !valueChanged, extendManager.extendConfigs?.isOwner == false else {
            return
        }
        // value 没有变化，说明开关被禁用了，只有存在已扩展字段，且当前用户不是 owner 时会出现
        UDToast.showTips(with: BundleI18n.SKResource.Bitable_PeopleField_NoPermToAllowAddingMultiplePerson_Description, on: self.view)
    }
}

extension BTFieldEditController: BTFieldExtendManagerDelegate {
    func managerDidUpdateExtendInfo(_ manager: BTFieldExtendManager) {
        updateUI(fieldEditModel: viewModel.fieldEditModel)
        // 背景：扩展字段不支持人员多选
        if extendManager.extendConfigs?.configs.contains(where: { $0.extendState }) == true {
            // 存在已扩展字段，仅 owner 可操作多、单选状态
            if manager.extendConfigs?.isOwner == true {
                // Owner 可以切换多选开关
                viewManager?.disableUserFieldMultipleSwitch(false)
            } else {
                // 非 Owner 不可以切换多选开关
                viewManager?.disableUserFieldMultipleSwitch(true)
            }
        } else {
            // 没有已扩展字段，只要有字段操作权限，都可以操作多选开关
            viewManager?.disableUserFieldMultipleSwitch(false)
        }
    }
    
    func managerDidUpdateExtendableFields(_ manager: BTFieldExtendManager) {

    }
    
    func managerDidFinishRefreshExtendData(_ manager: BTFieldExtendManager, error: Error?) {

    }
}

extension BTFieldEditController: BTFieldEditFooterDelegate {
    func footerHeightDidChange(_ footer: BTFieldEditFooter) {
        adjustFooterContentHeight()
    }
    
    func onExtFooterConfigSwitchTap(_ footer: BTFieldEditExtendFooter, config: FieldExtendConfig, valueChanged: Bool) {
        guard valueChanged else {
            showExtendFooterUneditableToast(footer, config: config)
            return
        }
        if config.extendState {
            extendManager.appendExtendConfigItems(config.extendItems.filter({ $0.isChecked }), currentFieldEditInfo: viewModel.fieldEditModel)
        } else {
            extendManager.deleteExtendConfigItems(config.extendItems.filter({ $0.isChecked }))
        }
        guard let start = extendManager.extendConfigs?.configs.first, let end = footer.configs.first else {
            return
        }
        extendManager.trackExtendSwitchChange(model: viewModel.fieldEditModel, start: start, end: end)
    }
    
    func onExtFooterConfigItemCheckboxTap(_ footer: BTFieldEditExtendFooter, config: FieldExtendConfig, item: FieldExtendConfigItem, valueChanged: Bool) {
        guard valueChanged else {
            showExtendFooterUneditableToast(footer, config: config)
            return
        }
        if item.isChecked {
            extendManager.appendExtendConfigItems([item], currentFieldEditInfo: viewModel.fieldEditModel)
        } else {
            extendManager.deleteExtendConfigItems([item])
        }
    }
    
    func extFooterOriginRefreshButtonDidTap(_ footer: BTFieldEditExtendFooter, extendInfo: FieldExtendInfo?) {
        extendManager.asyncRefreshFieldExtendData(editModel: viewModel.fieldEditModel)
        if let extInfo = viewModel.fieldEditModel.fieldExtendInfo {
            extendManager.trackExtendRefreshButtonClick(model: viewModel.fieldEditModel, extendInfo: extInfo)
        }
    }
    
    private func showExtendFooterUneditableToast(_ footer: BTFieldEditExtendFooter, config: FieldExtendConfig) {
        if !config.editable {
            UDToast.showTips(with: BundleI18n.SKResource.Bitable_PeopleField_NoPermToPerformThisAction_Tooltip, on: self.view)
        } else if footer.extraDisableReason.contains(.notSupportMultiple) {
            UDToast.showTips(with: BundleI18n.SKResource.Bitable_PeopleField_CannotRetrievePersonInfoInMultipleSelection_Tooltip, on: self.view)
        }
    }
}

extension BTFieldEditController: BTExtendNoticeViewDelegate {
    func onNoticeViewActionButtonClick(_ sender: BTExtendNoticeView) {
        guard let notice = viewModel.fieldEditModel.editNotice else {
            return
        }
        switch notice {
        case .noExtendFieldPermForOwner:
            // 同步 owner
            guard let service = viewModel.dataService?.jsFuncService else {
                return
            }
            extendManager.trackExtendNoticeClick(model: viewModel.fieldEditModel, notice: notice)
            // loading 和 toast 在前端处理
            service.callFunction(.syncFieldExtendOwner, params: [
                "tableId": viewModel.oldFieldEditModel.tableId
            ], completion: nil)
        case .originDeleteForOwner:
            extendManager.trackExtendNoticeClick(model: viewModel.fieldEditModel, notice: notice)
            // 转换为普通字段
            viewModel.fieldEditModel.fieldExtendInfo = nil
            // 与其它端对齐，转换后 banner 不消失
            viewModel.fieldEditModel.editNotice = nil
            updateUI(fieldEditModel: viewModel.fieldEditModel)
        case .noExtendFieldPermForUser, .originDeleteForUser, .originMultipleEnable:
            // 没有 action
            break;
        }
    }
}
