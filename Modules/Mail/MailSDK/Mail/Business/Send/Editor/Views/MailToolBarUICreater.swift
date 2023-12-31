//
//  Mail.swift
//  MailSDK
//
//  Created by majx on 2019/6/10.
//

import Foundation
// MARK: - UICreater
class MailToolBarUICreater: EditorToolBarUICreater {
    private weak var uiDelegate: MailSendController?
    private weak var mainDelegate: MailMainToolBarDelegate?
    private weak var subDelegate: MailSubToolBarDelegate?
    init(uiDelegate: MailSendController?, mainToolDelegate: MailMainToolBarDelegate?, subToolDelegate: MailSubToolBarDelegate?) {
        self.uiDelegate = uiDelegate
        mainDelegate = mainToolDelegate
        subDelegate = subToolDelegate
    }

    // 更新工具条
    func updateMainToolBarPanel(_ status: [EditorToolBarItemInfo], service: EditorJSService) -> EditorMainToolBarPanel {
        // 根据 status 构建一个新的工具条
        let newTool = MailMainToolBar(status, service: service)
        newTool.toolDelegate = mainDelegate
        newTool.sendVC = uiDelegate
        var frame = newTool.frame
        frame.origin.y = UIScreen.main.bounds.height
        newTool.frame = frame
        return newTool
    }

    // 更新子面板
    func updateSubToolBarPanel(_ status: [EditorToolBarItemInfo]?, identifier: String) -> EditorSubToolBarPanel? {
        guard let barIdentifier = EditorToolBarButtonIdentifier(rawValue: identifier) else { return nil }
        let width = self.uiDelegate?.getScreenSize().width ?? 0
        switch barIdentifier {
        case .insertImage:
            return MailSubToolBar.assetPanel(width, sendAction: uiDelegate?.action, presentVC: uiDelegate)
        case .attr:
            return MailSubToolBar.mailAttributionPanel(CGRect(origin: .zero, size: CGSize(width: width, height: 336)), status, toolDelegate: nil)

        default:
            return nil
        }
    }
}
