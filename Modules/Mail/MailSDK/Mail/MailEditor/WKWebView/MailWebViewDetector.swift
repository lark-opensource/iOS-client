//
//  MailWebViewDetector.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/3/18.
//

import Foundation

protocol MailWebViewDetectable {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
}

class MailWebViewDetector {
    enum DetectMethodType {
        case domTree
    }

    enum DetectResult {
        case avaliable
        case domNodeLess
    }

    static let shared = MailWebViewDetector()
}

typealias MailWebViewDetectComplete = (Bool, MailWebViewDetector.DetectResult) -> Void

// MARK: interface
extension MailWebViewDetector {
    func detect(webview: MailWebViewDetectable, complete: @escaping MailWebViewDetectComplete) {

        switch detectType {
        case .domTree:
            detectWithDomTree(webview: webview, complete: complete)
        }
    }
}

// MARK: internal
extension MailWebViewDetector {
    private func detectWithDomTree(webview: MailWebViewDetectable, complete: @escaping MailWebViewDetectComplete) {
        webview.evaluateJavaScript(MailCommonJS.whiteScreenDetectJS) { (res, error) in
            if let resp = res as? String, resp == "true" {
                complete(true, .domNodeLess)
            } else {
                complete(true, .avaliable)
            }
        }
    }
}

// MARK: Helper
extension MailWebViewDetector {
    var detectType: DetectMethodType {
        return .domTree
    }
}
