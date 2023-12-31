//
//  BTFieldEditConfig.swift
//  SKBitable
//
//  Created by yinyuan on 2023/3/1.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignIcon

/// 将不同字段的配置，内聚到不同字段的 Config 中，配置化管理，便于维护管理，实现相同字段的编辑逻辑高内聚，不同字段的编辑逻辑低耦合。
/// 不同的字段，请实现不同的字类型，参考 BTRatingFieldEditConfig
class BTFieldEditConfig {
    
    private(set) var commonDataModel: BTCommonDataModel?
    
    private(set) weak var viewController: BTFieldEditController?
    
    var viewModel: BTFieldEditViewModel? {
        viewController?.viewModel
    }
    
    init() {
    }
    
    /// 构造当前列表数据，每次 updateUI 时会调用到这里
    /// 新增字段需要采用该新设计，有疑问可联系 yinyuan.0
    /// 该方法存在计算耗时，仅在必要刷新 UI 的地方调用，如果只是为了获取数据，请调用 commonDataModel 属性
    func updateConfig(viewController: BTFieldEditController) {
        self.viewController = viewController
        self.commonDataModel = getData()
    }
    
    // MARK: - 下方是你需要在新增字段时修改的方法
    
    /// 切换类型时，需要重置字段属性
    /// 由于 viewModel 是公用的数据，一般来说，你都需要在切换新字段时重置所有属性，避免出现不同字段的相同属性在不同的类型下不兼容引发系列问题
    /// 你需要认真考虑并对待此问题
    static func resetPropertiesBeforeChangeType(viewModel: BTFieldEditViewModel, toType: BTFieldCompositeType) {
        viewModel.fieldEditModel.fieldProperty.multiple = false
        switch toType.uiType {
        case .notSupport, .text, .singleSelect,
                .multiSelect, .dateTime, .checkbox, .phone, .url,
                .attachment, .lookup, .formula,
                .location, .createTime, .lastModifyTime,
                .user, .createUser, .lastModifyUser, .autoNumber,
                .button, .barcode, .currency, .stage, .email:
            break
        case .singleLink, .duplexLink:
            // 这些字段默认开启多选
            viewModel.fieldEditModel.fieldProperty.multiple = true
        case .group:
                // linzhipeng 和PM linzhifeng确认，这里默认就需要改成单选，而且不和一行一群需求绑定，加个反向FG控制下
                viewModel.fieldEditModel.fieldProperty.multiple = false
            
        case .rating:
            viewModel.fieldEditModel.fieldProperty.formatter = viewModel.commonData.fieldConfigItem.getRatingDefaultFormat()
            viewModel.fieldEditModel.fieldProperty.min = Double(viewModel.commonData.fieldConfigItem.getRatingDefaultRangeConfig().min)
            viewModel.fieldEditModel.fieldProperty.max = Double(viewModel.commonData.fieldConfigItem.getRatingDefaultRangeConfig().max)
        case .progress:
            viewModel.fieldEditModel.fieldProperty.formatter = viewModel.commonData.fieldConfigItem.getProgressDefaultFormat()
            viewModel.fieldEditModel.fieldProperty.rangeCustomize = nil
            viewModel.fieldEditModel.fieldProperty.min = nil
            viewModel.fieldEditModel.fieldProperty.max = nil
            viewModel.fieldEditModel.fieldProperty.progress = nil
            let rangeConfig = viewModel.commonData.fieldConfigItem.getCurrentRangeConfig(fieldEditModel: viewModel.fieldEditModel)
            // 保证range由初始化值
            viewModel.fieldEditModel.fieldProperty.rangeCustomize = rangeConfig.rangeCustomize
            viewModel.fieldEditModel.fieldProperty.min = rangeConfig.min
            viewModel.fieldEditModel.fieldProperty.max = rangeConfig.max
            if let colorConfig = viewModel.commonData.fieldConfigItem.getCurrentColorConfig(fieldEditModel: viewModel.fieldEditModel) {
                viewModel.fieldEditModel.fieldProperty.progress = BTProgressModel(color: colorConfig.selectedColor)
            }
        case .number:
            viewModel.fieldEditModel.fieldProperty.formatter = viewModel.commonData.fieldConfigItem.getNumberDefaultFormat()
        }
    }
    
    /// 如果新字段需要红点引导，请配置一下内容。如果你不确定，请联系需求 PM。
    static func onBoardingID(fieldType: BTFieldCompositeType) -> OnboardingID? {
        switch fieldType.uiType {
        case .notSupport, .text, .number, .singleSelect,
                .multiSelect, .dateTime, .checkbox, .phone, .url,
                .attachment, .singleLink, .lookup, .formula,
                .duplexLink, .location, .createTime, .lastModifyTime,
                .lastModifyUser, .autoNumber, .button, .stage:
            return nil
        case .user, .createUser:
            return OnboardingID.bitableUserFieldExtendNew
        case .barcode:
            return OnboardingID.bitableBarcodeFieldNew
        case .currency:
            return OnboardingID.bitableCurrencyFieldNew
        case .progress:
            return OnboardingID.bitableProgressFieldNew
        case .group:
            return OnboardingID.bitableGroupFieldNew
        case .rating:
            return OnboardingID.bitableRatingFieldNew
        case .email:
            return OnboardingID.bitableEmailFieldNew
        }
    }

    // MARK: - 下方是你需要在新增字段时必须子类重写实现的方法
    /// 计算最新列表数据，请在子类重写该方法并返回列表数据
    func getData() -> BTCommonDataModel? {
        return nil
    }
    
    /// 计算点击保存时需要提交数据，请在子类重写该方法并返回数据
    func createNormalCommitChangeProperty() -> [String: Any]? {
        return nil
    }
    
    /// 点击保存按钮时埋点，请在子类重写该方法并进行埋点
    func trackOnSaveButtonClick() {
        
    }
    
    // MARK: - 下方是你需要在新增字段时可选子类重写实现的方法
    /// 在保存数据之前，检查是否允许保存
    /// callback 用于异步回调是否要继续保存
    func checkBeforeSave(_ callback: @escaping (_ continueSave: Bool) -> Void) {
        callback(true)
    }
}
