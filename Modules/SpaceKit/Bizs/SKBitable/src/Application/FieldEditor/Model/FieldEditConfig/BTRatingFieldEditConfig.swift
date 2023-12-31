//
//  BTRatingFieldEditConfig.swift
//  SKBitable
//
//  Created by yinyuan on 2023/3/1.
//

import Foundation
import SKFoundation
import SKResource
import UniverseDesignIcon
import UniverseDesignDialog

final class BTRatingFieldEditConfig: BTFieldEditConfig {
    
    override func getData() -> BTCommonDataModel? {
        guard let viewModel = viewModel else {
            return nil
        }
        let ratingSymbolConfig = viewModel.commonData.fieldConfigItem.getCurrentRatingSymbolConfig(fieldEditModel: viewModel.fieldEditModel)
        let ratingRangeConfig = viewModel.commonData.fieldConfigItem.getCurrentRatingRangeConfig(fieldEditModel: viewModel.fieldEditModel)
        let ratingSymbol = ratingSymbolConfig?.selectedSymbol.symbol ?? BTRatingModel.defaultSymbol
        return BTCommonDataModel(groups: [
            .init(groupName: BundleI18n.SKResource.Bitable_Rating_Icon_Title, items: [
                .init(
                    selectCallback: { [weak self] cell, id, userInfo in
                        self?.didClickChooseRatingSymbol(cell: cell)
                    },
                    leftIcon: .init(image: nil, size: CGSize(width: 218, height: 18), customRender: { imageView in
                        let ratingView: BTRatingView
                        if imageView.subviews.count > 0, let targetView = imageView.subviews[0] as? BTRatingView {
                            ratingView = targetView
                        } else {
                            imageView.subviews.forEach { view in
                                view.removeFromSuperview()
                            }
                            ratingView = BTRatingView()
                            imageView.addSubview(ratingView)
                        }
                        ratingView.snp.makeConstraints { make in
                            make.left.top.bottom.equalToSuperview()
                        }
                        ratingView.isUserInteractionEnabled = false
                        let config = BTRatingView.Config(
                            minValue: 1,
                            maxValue: 5,
                            iconWidth: 20,
                            iconSpacing: 2,
                            iconPadding: 1,
                            iconBuilder: { value in
                                return BitableCacheProvider.current.ratingIcon(symbol: ratingSymbol, value: value)
                            }
                        )
                        ratingView.update(config, 3)
                    }),
                    rightIcon: .init(image: UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)))
            ]),
            .init(groupName: BundleI18n.SKResource.Bitable_Rating_Minimum_Title, items: [
                .init(
                    selectCallback: { [weak self] cell, id, userInfo in
                        self?.didClickChooseRatingMin(cell: cell)
                    },
                    mainTitle: .init(text: String(ratingRangeConfig.min)),
                    rightIcon: .init(image: UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)))
            ]),
            .init(groupName: BundleI18n.SKResource.Bitable_Rating_Maximum_Title, items: [
                .init(
                    selectCallback: { [weak self] cell, id, userInfo in
                        self?.didClickChooseRatingMax(cell: cell)
                    },
                    mainTitle: .init(text: String(ratingRangeConfig.max)),
                    rightIcon: .init(image: UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)))
            ])
        ])
    }
    
    override func createNormalCommitChangeProperty() -> [String : Any]? {
        guard let viewModel = viewModel else {
            return nil
        }
        // 需要保证所有的值都有，即使没有修改也得有，如果有值不合法，将会导致文档卡死的致命异常
        var property: [String: Any] = [:]
        var formatter: String = viewModel.fieldEditModel.fieldProperty.formatter
        if formatter.isEmpty {
            formatter = viewModel.commonData.fieldConfigItem.getRatingDefaultFormat()
        }
        let rangeConfig = viewModel.commonData.fieldConfigItem.getCurrentRatingRangeConfig(fieldEditModel: viewModel.fieldEditModel)
        let min: Int = rangeConfig.min
        let max: Int = rangeConfig.max
        let enumerable: Bool = viewModel.fieldEditModel.fieldProperty.enumerable ?? true
        let rangeLimitMode: String = viewModel.fieldEditModel.fieldProperty.rangeLimitMode ?? "all"
        let rating: BTRatingModel = viewModel.fieldEditModel.fieldProperty.rating ?? BTRatingModel(symbol: BTRatingModel.defaultSymbol)
        let ratingJson = rating.toJSON()
        if ratingJson == nil || ratingJson.isEmpty {
            spaceAssertionFailure("rating property invalid")
        }
        
        property["formatter"] = formatter
        property["min"] = min
        property["max"] = max
        property["enumerable"] = enumerable
        property["rangeLimitMode"] = rangeLimitMode
        property["rating"] = ratingJson
        
        DocsLogger.info("rating property: formatter:\(formatter) min:\(min) max:\(max) enumerable:\(enumerable) rangeLimitMode:\(rangeLimitMode) rating:\(String(describing: ratingJson))")
        return property
    }
    
    override func trackOnSaveButtonClick() {
        guard let viewModel = viewModel else {
            return
        }
        var params: [String: Any] = [
            "click": "confirm"
        ]
        if let ratingSymbolConfig = viewModel.commonData.fieldConfigItem.getCurrentRatingSymbolConfig(fieldEditModel: viewModel.fieldEditModel) {
            params["mark_type"] = ratingSymbolConfig.selectedSymbol.symbol
        }
        trackEditViewEvent(eventType: .bitableRatingFieldModifyClick, params: params)
    }
    
    override func checkBeforeSave(_ callback: @escaping (Bool) -> Void) {
        guard let viewController = viewController, let viewModel = viewModel else {
            callback(true)
            return
        }
        if viewController.currentMode == .edit {
            let oldRange = viewModel.commonData.fieldConfigItem.getCurrentRatingRangeConfig(fieldEditModel: viewModel.oldFieldEditModel)
            let newRange = viewModel.commonData.fieldConfigItem.getCurrentRatingRangeConfig(fieldEditModel: viewModel.fieldEditModel)
            if newRange.min > oldRange.min || newRange.max < oldRange.max {
                // 范围发生变化，弹窗确认
                let dialog = UDDialog()
                dialog.setTitle(text: BundleI18n.SKResource.Bitable_Common_Notice_Title)
                dialog.setContent(text: BundleI18n.SKResource.Bitable_Rating_ExceededDataWillBeDeteled_Description)
                dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel, dismissCompletion: {
                    callback(false)
                })
                dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonConfirm_Mobile, dismissCompletion: {
                    callback(true)
                })
                viewController.present(dialog, animated: true)
                return
            }
        }
        callback(true)
    }
    
    private func didClickChooseRatingSymbol(cell: BTCommonCell) {
        guard let viewController = viewController, let viewModel = viewModel else {
            return
        }
        viewController.hasFieldSubSettingClick = true
        guard let ratingSymbolConfig = viewModel.commonData.fieldConfigItem.getCurrentRatingSymbolConfig(fieldEditModel: viewModel.fieldEditModel) else {
            DocsLogger.error("ratingSymbolConfig invalid")
            return
        }
        let picker = BTRatingSymbolPickerViewController(items: ratingSymbolConfig.symbols, selectedItem: ratingSymbolConfig.selectedSymbol)
        picker.delegate = self
        viewController.safePresent { [weak viewController] in
            guard let viewController = viewController else { return }
            BTNavigator.presentDraggableVCEmbedInNav(picker, from: UIViewController.docs.topMost(of: viewController) ?? viewController, completion: {
            })
        }
        trackEditViewEvent(eventType: .bitableRatingFieldModifyClick, params: ["click": "mark_shape"])
    }
    
    ///修改评分字段最小位数
    private func didClickChooseRatingMin(cell: BTCommonCell) {
        guard let viewController = viewController, let viewModel = viewModel else {
            return
        }
        viewController.hasFieldSubSettingClick = true
        let ratingRangeConfig = viewModel.commonData.fieldConfigItem.getCurrentRatingRangeConfig(fieldEditModel: viewModel.fieldEditModel)

        var data: [BTFieldCommonData] = []
        var index: Int = 0
        let length = ratingRangeConfig.minRangeMax - ratingRangeConfig.minRangeMin + 1
        for i in 0..<length {
            let cMin = i + ratingRangeConfig.minRangeMin
            let cMinStr = String(cMin)
            data.append(.init(id: cMinStr, name: cMinStr))
            if ratingRangeConfig.min == cMin {
                index = i
            }
        }
        
        let tableList = BTFieldCommonDataListController(data: data,
                                                        title: BundleI18n.SKResource.Bitable_Rating_Minimum_Title,
                                                        action: BTFieldEditDataListViewAction.updateRatingMin.rawValue,
                                                        relatedView: cell,
                                                        lastSelectedIndexPath: IndexPath(row: index, section: 0))
        tableList.delegate = self
        viewController.safePresent { [weak viewController] in
            guard let viewController = viewController else { return }
            BTNavigator.presentDraggableVCEmbedInNav(tableList, from: UIViewController.docs.topMost(of: viewController) ?? viewController, completion: {

            })
        }
        
        trackEditViewEvent(eventType: .bitableRatingFieldModifyClick, params: ["click": "min_setting"])
    }
    
    ///修改评分字段最大位数
    private func didClickChooseRatingMax(cell: BTCommonCell) {
        guard let viewController = viewController, let viewModel = viewModel else {
            return
        }
        viewController.hasFieldSubSettingClick = true
        let ratingRangeConfig = viewModel.commonData.fieldConfigItem.getCurrentRatingRangeConfig(fieldEditModel: viewModel.fieldEditModel)

        var data: [BTFieldCommonData] = []
        var index: Int = 0
        let length = ratingRangeConfig.maxRangeMax - ratingRangeConfig.maxRangeMin + 1
        for i in 0..<length {
            let cMax = i + ratingRangeConfig.maxRangeMin
            let cMaxStr = String(cMax)
            data.append(.init(id: cMaxStr, name: cMaxStr))
            if ratingRangeConfig.max == cMax {
                index = i
            }
        }
        
        let tableList = BTFieldCommonDataListController(data: data,
                                                        title: BundleI18n.SKResource.Bitable_Rating_Maximum_Title,
                                                        action: BTFieldEditDataListViewAction.updateRatingMax.rawValue,
                                                        relatedView: cell,
                                                        lastSelectedIndexPath: IndexPath(row: index, section: 0))
        tableList.delegate = self
        viewController.safePresent { [weak viewController] in
            guard let viewController = viewController else { return }
            BTNavigator.presentDraggableVCEmbedInNav(tableList, from: UIViewController.docs.topMost(of: viewController) ?? viewController, completion: {

            })
        }
        trackEditViewEvent(eventType: .bitableRatingFieldModifyClick, params: ["click": "max_setting"])
    }
}

extension BTRatingFieldEditConfig: BTRatingSymbolPickerViewControllerDelegate {
    func didSelectedRatingSymbol(item: BTRatingSymbol, relatedView: UIView?) {
        guard let viewController = viewController, let viewModel = viewModel else {
            return
        }
        viewModel.fieldEditModel.fieldProperty.rating = BTRatingModel(symbol: item.symbol)
        viewController.updateUI(fieldEditModel: viewModel.fieldEditModel)
    }
}


extension BTRatingFieldEditConfig: BTFieldCommonDataListDelegate {
    func didSelectedItem(_ item: BTFieldCommonData,
                         relatedItemId: String,
                         relatedView: UIView?,
                         action: String,
                         viewController: UIViewController, sourceView: UIView? = nil) {
        guard let viewModel = viewModel else {
            return
        }
        guard let fieldEditAction = BTFieldEditDataListViewAction(rawValue: action) else {
            return
        }
        switch fieldEditAction {
        case .updateRatingMin:
            viewModel.fieldEditModel.fieldProperty.min = Double(item.id) ?? 0
            self.viewController?.updateUI(fieldEditModel: viewModel.fieldEditModel)
            viewController.dismiss(animated: true)
        case .updateRatingMax:
            viewModel.fieldEditModel.fieldProperty.max = Double(item.id) ?? 10
            self.viewController?.updateUI(fieldEditModel: viewModel.fieldEditModel)
            viewController.dismiss(animated: true)
        default:
            break
        }
    }
}
