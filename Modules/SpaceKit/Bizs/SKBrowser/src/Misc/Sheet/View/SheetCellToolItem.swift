//
//  SheetCellToolItem.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/24.
//

import Foundation
import SKCommon
import SKUIKit
import SKResource

class SheetCellToolItem: PanelTypeToolBarItem {
    var sheetCellView: SheetCellManagerView?
    var titleView: ColorPickerNavigationView?

    override func panelView() -> UIView? {
        if sheetCellView == nil {
            let frame = CGRect(x: 0, y: 0, width: SKDisplay.activeWindowBounds.size.width, height: 200)
            sheetCellView = SheetCellManagerView(status: childStatus, frame: frame)
        }
        sheetCellView?.delegate = self
        sheetCellView?.updateStatus(status: childStatus)
        return sheetCellView
    }

    override func transferPanelView(to item: DocsBaseToolBarItem) {
        if let toItem = item as? SheetCellToolItem {
            toItem.sheetCellView = self.sheetCellView
            toItem.sheetCellView?.delegate = toItem
            toItem.sheetCellView?.updateStatus(status: toItem.childStatus)
            toItem.titleView = self.titleView
            toItem.titleView?.delegate = toItem
        }
    }

    override func panelWillDisappear() {
        super.panelWillDisappear()
        sheetCellView?.showColorPicker(show: false)
    }
}

extension SheetCellToolItem: SheetCellManagerViewDelegate {
    func sheetCellManagerViewDidShowImagePicker(view: SheetCellManagerView) {
        delegate?.requestJumpAnotherTitleView(in: self)
    }
}

extension SheetCellToolItem: ColorPickerNavigationViewDelegate {

    func colorPickerNavigationViewRequestExit(view: ColorPickerNavigationView) {
        sheetCellView?.showColorPicker(show: false)
        delegate?.requestExitTitleView(in: self)
        delegate?.requestTapicFeedback(item: self)
    }
}
