//
//  DocsSubToolBar.swift
//  SpaceKit
//
//  Created by Webster on 2019/5/27.
//

import Foundation
import SKCommon
import SKUIKit
import EENavigator
import SpaceInterface

public final class DocsSubToolBar: SKSubToolBarPanel {

    class func statusTransfer(status: [ToolBarItemInfo]) -> [BarButtonIdentifier: ToolBarItemInfo] {
        var infos: [BarButtonIdentifier: ToolBarItemInfo] = [BarButtonIdentifier: ToolBarItemInfo]()
        for data in status {
            if let identifier = BarButtonIdentifier(rawValue: data.identifier) {
                infos.updateValue(data, forKey: identifier)
            }
        }
        return infos
    }

    class func docsAttributionPanel(_ status: [ToolBarItemInfo]?) -> SKSubToolBarPanel? {
        guard let realStatus = status else { return nil }
        let viewStatus = DocsSubToolBar.statusTransfer(status: realStatus)
        let frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        let view = DocsAttributionView(status: viewStatus, frame: frame)
        view.showColorPicker(toShow: true)
        return view
    }

    class func sheetAttributionPanel(_ status: [ToolBarItemInfo]?) -> SKSubToolBarPanel? {
        guard let realStatus = status else { return nil }
        let viewStatus = DocsSubToolBar.statusTransfer(status: realStatus)
        let frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        let view = SheetAttributionView(status: viewStatus, frame: frame)
        return view
    }

    class func sheetCellManagerPanel(_ status: [ToolBarItemInfo]?) -> SKSubToolBarPanel? {
        guard let realStatus = status else { return nil }
        let viewStatus = DocsSubToolBar.statusTransfer(status: realStatus)
        let frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        let view = SheetCellManagerView(status: viewStatus, frame: frame)
        return view
    }

    class func mindNodeAttributionPanel(_ status: [ToolBarItemInfo]?) -> SKSubToolBarPanel? {
        guard let realStatus = status else { return nil }
        let viewStatus = DocsSubToolBar.statusTransfer(status: realStatus)
        let frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        let view = MindNoteAttributionView(status: viewStatus, frame: frame)
        return view
    }

    class func assetPanel(_ status: [ToolBarItemInfo]?, docsInfo: DocsInfo?, curWindow: UIWindow?) -> SKSubToolBarPanel? {
        let width = EditorManager.shared.currentEditor?.frame.width ?? 0
        let defaultRect = CGRect(x: 0, y: 0, width: width, height: 200)
        let imagePickerView = DocsImagePickerToolView(frame: defaultRect, fileType: docsInfo?.type, curWindow: curWindow)
        return imagePickerView
    }

}
