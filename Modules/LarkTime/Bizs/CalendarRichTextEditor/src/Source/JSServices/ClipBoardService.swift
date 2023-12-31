//
//  ClipBoardService.swift
//  CalendarRichTextEditor
//
//  Created by Rico on 2021/6/8.
//

import Foundation
import LarkEMM
import SwiftyJSON
import CalendarFoundation
import LarkSensitivityControl

final class ClipBoardSetService: JSServiceHandler {
    var handleServices: [JSService] {
        return [.rtClipboardSetContent]
    }

    func handle(params: [String: Any], serviceName: String) {
        if let text = params["text"] as? String {
            let config = PasteboardConfig(token: LarkSensitivityControl.Token(SCPasteboardUtils.getSceneKey(.docsWebViewBridgeClipBoardSet)))
            do {
                try SCPasteboard.generalUnsafe(config).string = text
            } catch {
                SCPasteboardUtils.logCopyFailed()
            }
        }
    }
}

final class ClipBoardGetService: JSServiceHandler {
    var handleServices: [JSService] {
        return [.rtClipboardGetContent]
    }

    func handle(params: [String: Any], serviceName: String) {

    }
}

final class ClipBoardOnPasteDocsService: JSServiceHandler {
    weak var uiDisplayConfig: RichTextViewDisplayConfig?

    init(_ uiDisplayConfig: RichTextViewDisplayConfig) {
        self.uiDisplayConfig = uiDisplayConfig
    }

    var handleServices: [JSService] {
        return [.rtOnPasteDocs]
    }

    func handle(params: [String: Any], serviceName: String) {
        let keystr = "docInfos"
        let propertyKey = "inviteCanView"
        let infos = JSON(params)[keystr].compactMap { $0.1[propertyKey].bool }
        Logger.info("onPasteDocs ", extraInfo: ["docsAuthInfos": infos.description])
        guard !infos.isEmpty else { return }
        uiDisplayConfig?.pushOnpasteAutoAuth(infos)
    }
}
