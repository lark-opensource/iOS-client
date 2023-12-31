//
//  CodeBlockService.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/9/21.
//

import Foundation
import SKCommon
import SKFoundation
import SKUIKit

public final class CodeBlockService: BaseJSService {
    var callback: String = ""
}

extension CodeBlockService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.codeBlockLanguages]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard let languages = params["list"] as? [String],
            let selectLanguage = params["value"] as? String,
            let callback = params["callback"]  as? String else {
            DocsLogger.error("CodeBlockLanguages parmas deficiency")
            return
        }
        self.callback = callback
        let context = CBLangSelectVCContext(languages: languages, selectLanguage: selectLanguage)
        let selectVC = CBLangSelectViewController(context: context, delegate: self)
        ui?.displayConfig.setCodeBlockSceneStatus(true)
        if SKDisplay.pad,
            ui?.editorView.isMyWindowRegularSize() ?? false {
            selectVC.modalPresentationStyle = .formSheet
            navigator?.presentViewController(selectVC, animated: true, completion: nil)
        } else {
            selectVC.modalPresentationStyle = .overFullScreen
            navigator?.presentViewController(selectVC, animated: true, completion: nil)
        }
    }
}

extension CodeBlockService: CBLangSelectViewControllerDelegate {
    func didSelectedNewLanguague(_ language: String) {
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["value": language], completion: nil)
    }

    func willDismissLangSelectVC() {
        ui?.displayConfig.setCodeBlockSceneStatus(false)
    }
}
