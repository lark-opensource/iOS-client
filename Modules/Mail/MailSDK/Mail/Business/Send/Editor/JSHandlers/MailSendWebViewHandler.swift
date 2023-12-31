//
//  MailSendWebViewHandler.swift
//  MailSDK
//
//  Created by tanghaojin on 2022/1/14.
//

import Foundation
import RxSwift

extension EditorJSService {
    // 高度变化
    static let mailEditorResizeY = EditorJSService(rawValue: "biz.core.resizeY")
    // 内容发生变化
    static let renderDone = EditorJSService(rawValue: "biz.render.done")
    static let notifyReady = EditorJSService("biz.notify.ready")
}

protocol MailSendWebViewHandlerDelegate: AnyObject {
    func updateWebViewHeight(_ height: CGFloat)
    func renderDone(_ status: Bool, _ param: [String: Any]) 
    func setToolBar(_ param: [String: Any])
    func preLoadSignature(_ param: [String: Any])
    func notifyReady()
}

class MailSendWebViewHandler: EditorJSServiceHandler {
    weak var delegate: MailSendWebViewHandlerDelegate?
    private var disposeBag = DisposeBag()

    var handleServices: [EditorJSService] = [.mailEditorResizeY,
                                             .renderDone,
                                             .mailSetToolBar,
                                             .signature,
                                             .notifyReady]
    // js callToNative
    func handle(params: [String: Any], serviceName: String) {
        if EditorJSService(rawValue: serviceName) == .mailEditorResizeY {
            guard let height = params["height"] as? CGFloat else { return }
            delegate?.updateWebViewHeight(height)
        } else if EditorJSService(rawValue: serviceName) == .renderDone {
            delegate?.renderDone(true, params)
        } else if serviceName == EditorJSService.mailSetToolBar.rawValue {
            delegate?.setToolBar(params)
        } else if EditorJSService(rawValue: serviceName) == .signature {
            delegate?.preLoadSignature(params)
        } else if EditorJSService(rawValue: serviceName) == .notifyReady {
            if FeatureManager.open(.preRender) {
                delegate?.notifyReady()
            }
        }

    }
}
