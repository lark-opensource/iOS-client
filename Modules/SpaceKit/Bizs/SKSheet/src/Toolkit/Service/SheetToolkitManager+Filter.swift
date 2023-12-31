//
//  File.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/26.
//

import SKCommon

extension SheetToolkitManager: SheetFilterFacadeViewControllerDelegate {

    func filterDidRequstUpdate(identifier: String, value: String?, controller: SheetFilterFacadeViewController) {
        delegate?.toolkitRequestNavigation(identifier: identifier, value: value, viewType: .operation, manager: self, itemIsEnable: true)
    }

    func updateFilterInfo(_ filterInfo: [SheetFilterType: SheetFilterInfo]) {
        self.filterDetailInfo = filterInfo
        refreshPanel(identifier: BadgedItemIdentifier.filterValue.rawValue)
        refreshPanel(identifier: BadgedItemIdentifier.filterColor.rawValue)
        refreshPanel(identifier: BadgedItemIdentifier.filterCondition.rawValue)
    }
}

extension SheetToolkitManager: SheetFilterDetailDelegate {

    var browserViewBottomDistance: CGFloat {
        return dataSource?.primaryBrowserViewDistanceToWindowBottom ?? 0
    }

    func requestJsCallBack(identifier: String, value: String, controller: SheetFilterDetailViewController) {
        delegate?.filterRequestJsUpdateValue(identifier, value: value, filterInfo: controller.filterInfo, manager: self)
    }

    func requestJsCallBack(identifier: String, range value: [Any], controller: SheetFilterDetailViewController, bySearch: Bool?) {
        delegate?.filterRequestJsUpdateRange(identifier, range: value, filterInfo: controller.filterInfo, manager: self, bySearch: bySearch)
    }

    func willBeginTextInput(controller: SheetFilterDetailViewController) {
        switchToFloatModel(model: .nearlyFull)
    }

    func willEndTextInput(controller: SheetFilterDetailViewController) {
        switchToFloatModel(model: .middle)
    }
}

extension SheetToolkitManager: SheetFilterByValueDelegate {
    func temporarilyDisableDraggability() {
        inhibitsDraggability = true
    }
    
    func restoreDraggability() {
        inhibitsDraggability = nil
    }
    
    func didPressPanelSearchButton(_ controller: SheetFilterByValueViewController) {
        delegate?.filterByValueDidPressPanelSearchButton(fromToolkit: isShowingToolkit(), manager: self)
    }
    func didPressKeyboardSearchButton(_ controller: SheetFilterByValueViewController) {
        delegate?.filterByValueDidPressKeyboardSearchButton(fromToolkit: isShowingToolkit(), manager: self)
    }
}
