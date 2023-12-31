//
//  ScanHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import EENavigator
import QRCode
import WebBrowser
import LKCommonsLogging

class ScanHandler: JsAPIHandler {
    static let logger = Logger.log(ScanHandler.self, category: "Module.JSSDK")
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        ScanHandler.logger.info("ScanHandler call begin")

        /// 开发者可选配置，不配置默认全选
        var scanCodeType: ScanCodeType = []
        /// Type数组
        if let typeArray = args["type"] as? [String] {
            if typeArray.contains("qrCode") {
                scanCodeType.insert(.qrCode)
            }
            if typeArray.contains("barCode") {
                scanCodeType.insert(.barCode)
            }
        }
        /// 没传递或者写错了就默认
        if scanCodeType.isEmpty {
            scanCodeType = [.barCode, .qrCode]
        }
        ScanHandler.logger.error("ScanHandler start scan with parameters: \(scanCodeType)")
        let vc = H5ScanCodeController(type: scanCodeType)
        if let barCodeInput = args["barCodeInput"] as? Bool,
            barCodeInput {
            vc.shouldShowInput = true
            ScanHandler.logger.error("ScanHandler set shouldShowInput true")
        }
        /// 这个地方缺少返回回调，扫码vc需要补充
        vc.didScanQRCodeBlock = { [weak vc, weak self, weak api] (result, _) in
            vc?.navigationController?.popViewController(animated: true)
            ScanHandler.logger.error("ScanHandler callback success")
            callback.callbackSuccess(param: ["text": result])
        }
        Navigator.shared.push(vc, from: api) // Global
        ScanHandler.logger.info("ScanHandler call end")
    }
}
