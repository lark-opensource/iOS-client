//
//  SheetAttributionToolItem.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/24.
//

import Foundation
import SKCommon
import SKUIKit
import SKResource

class SheetAttributionToolItem: PanelTypeToolBarItem {
    var sheetAttView: SheetAttributionView?
    var titleView: ColorPickerNavigationView?

    override func panelView() -> UIView? {
        if sheetAttView == nil {
            let frame = CGRect(x: 0, y: 0, width: SKDisplay.activeWindowBounds.width, height: 200)
            sheetAttView = SheetAttributionView(status: childStatus, frame: frame)
        }
        sheetAttView?.delegate = self
        sheetAttView?.updateStatus(status: childStatus)
        return sheetAttView
    }

    override func transferPanelView(to item: DocsBaseToolBarItem) {
        if let toItem = item as? SheetAttributionToolItem {
            toItem.sheetAttView = self.sheetAttView
            toItem.sheetAttView?.delegate = toItem
            toItem.sheetAttView?.updateStatus(status: toItem.childStatus)
            toItem.titleView = self.titleView
            toItem.titleView?.delegate = toItem
        }
    }

    override func panelWillDisappear() {
        super.panelWillDisappear()
        sheetAttView?.showColorPicker(show: false)
    }
}

extension SheetAttributionToolItem: SheetAttributionViewDelegate {
    func sheetAttributionViewDidShowImagePicker(view: SheetAttributionView) {
        delegate?.requestJumpAnotherTitleView(in: self)
    }
}

extension SheetAttributionToolItem: ColorPickerNavigationViewDelegate {
    func colorPickerNavigationViewRequestExit(view: ColorPickerNavigationView) {
        sheetAttView?.showColorPicker(show: false)
        delegate?.requestExitTitleView(in: self)
        delegate?.requestTapicFeedback(item: self)
    }
}
