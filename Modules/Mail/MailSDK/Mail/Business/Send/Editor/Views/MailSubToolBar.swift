//
//  MailSubToolBar.swift
//  MailSDK
//
//  Created by majx on 2019/6/16.
//

import Foundation
import UniverseDesignTheme

class MailSubToolBar: EditorSubToolBarPanel {
    class func statusTransfer(status: [EditorToolBarItemInfo]) -> [EditorToolBarButtonIdentifier: EditorToolBarItemInfo] {
        var infos: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo] = [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]()
        for data in status {
            if let identifier = EditorToolBarButtonIdentifier(rawValue: data.identifier) {
                infos.updateValue(data, forKey: identifier)
            }
        }
        return infos
    }

    // 文字格式
    class func mailAttributionPanel(_ frame: CGRect, _ status: [EditorToolBarItemInfo]?, toolDelegate: MailSubToolBarDelegate?) -> EditorSubToolBarPanel? {
        guard let items = status else { return nil }
        let viewStatus = MailSubToolBar.statusTransfer(status: items)
        let view = MailAttributionView(frame: frame, items: items, status: viewStatus)
        view.toolDelegate = toolDelegate
        return view
    }

    // 图片选择器
    class func assetPanel(_ width: CGFloat, sendAction: MailSendAction?, presentVC: UIViewController?) -> MailImagePickerToolView {
        let defaultRect = CGRect.init(x: 0, y: 0, width: width, height: 260 + Display.bottomSafeAreaHeight)
        let imagePickerView = MailImagePickerToolView(frame: defaultRect, sendAction: sendAction, presentVC: presentVC)
        return imagePickerView
    }
}
