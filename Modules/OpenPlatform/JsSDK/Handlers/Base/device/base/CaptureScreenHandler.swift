//
//  CaptureScreenHandler.swift
//  Action
//
//  Created by chenyingguang on 2019/3/1.
//

import Foundation
import WebBrowser

class CaptureScreenObserver: NSObject {

    var notifyBlock: ( () -> Void )?

    public func regist() {
        // 监听截屏
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reciveNotification),
                                               name: UIApplication.userDidTakeScreenshotNotification,
                                               object: nil)
    }

    @objc
    func reciveNotification() {
        notifyBlock?()
    }

    public func unregist() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.userDidTakeScreenshotNotification,
                                                  object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class CaptureScreenOnHandler: JsAPIHandler {
    private let captureScreenObserver: CaptureScreenObserver
    var functionName: String = ""
    var callback: WorkaroundAPICallBack?

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let functionName = args["callback"] as? String else {
                GeoLocationHandler.logger.error("参数有误")
                return
        }
        self.functionName = functionName
        self.callback = callback
        captureScreenObserver.regist()
    }

    init(captureScreenOb: CaptureScreenObserver, api: WebBrowser) {
        self.captureScreenObserver = captureScreenOb
        self.captureScreenObserver.notifyBlock = { [weak self] in
            guard let self = self else {
                return
            }
            self.callback?.asyncNotify(event: self.functionName, data: [])
        }
    }
}

class CaptureScreenOffHandler: JsAPIHandler {
    private let captureScreenObserver: CaptureScreenObserver

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        captureScreenObserver.unregist()
    }

    init(captureScreenOb: CaptureScreenObserver) {
        self.captureScreenObserver = captureScreenOb
    }
}
