//
//  JSServiceManager.swift
//  DocsSDK
//
//  Created by weidong fu on 2018/12/11.
//

import Foundation

class EditorJSServicesManager {
    private var handlers: [EditorJSServiceHandler] = []
    //    private var registeredService: Set<EditorJSService> = []
    private let handerQueue = DispatchQueue(label: "com.bytedance.mail.handler.\(UUID().uuidString)")
    var isBusy: Bool = false

    //
    func handle(message: String, _ params: [String: Any]) {
        handerQueue.async { [weak self] in
            guard let self = self else { return }
            let cmd = EditorJSService(rawValue: message)
            self.handlers.forEach { (handler) in
                if handler.handleServices.contains(cmd) {
                    DispatchQueue.main.async {
                        var logParams = params
                        if cmd == EditorJSService.imgDomChange, let src = params["src"] as? String, src.starts(with: "data:image") {
                            //base64的image传递以防log数据太大，不写src到log
                            logParams["src"] = "data:image"
                        }
                        MailLogger.info("jsservice handle message=\(message)")
                        handler.handle(params: params, serviceName: message)
                    }
                }
            }
        }
    }

    // 在这里注册 js handler
    @discardableResult
    func register(handler: EditorJSServiceHandler) -> EditorJSServiceHandler {
        handlers.append(handler)
        return handler
        // checkIsRegistered(handler)
    }
}
