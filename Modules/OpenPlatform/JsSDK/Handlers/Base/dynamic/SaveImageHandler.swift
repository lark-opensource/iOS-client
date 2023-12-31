//
//  SaveImageHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import LKCommonsLogging
import WebBrowser
import OPFoundation

class SaveImageHandler: NSObject, JsAPIHandler {

    private static let logger = Logger.log(SaveImageHandler.self, category: "SaveImageHandler")
    private var args: [String: Any] = [:]
    private weak var api: WebBrowser?

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        self.args = args
        self.api = api
        if let imageBase64String = args["image"] as? String,
            let dataDecoded = Data(base64Encoded: imageBase64String, options: .ignoreUnknownCharacters),
            let decodedimage = UIImage(data: dataDecoded) {
            SaveImageHandler.logger.info("image length \(dataDecoded.count)")
            do {
                try OPSensitivityEntry.UIImageWriteToSavedPhotosAlbum(forToken: .SaveImageHandler_handle_UIImageWriteToSavedPhotosAlbum, image: decodedimage, completionTarget: self, completionSelector: #selector(savePhotoToAlbum(image:didFinishSavingWithError:contextInfo:)), contextInfo: nil)
            } catch {
                SaveImageHandler.logger.error("OPSensitivityEntry UIImageWriteToSavedPhotosAlbum error: \(error)")
                callbackWith(api: api, funcName: "save failed", arguments: [NewJsSDKErrorAPI.unknown(extraMsg: "psda").description()])
            }
        } else {
            if let onFailed = args["onFailed"] as? String {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
            SaveImageHandler.logger.error("SaveImageHandler faild, imageBase64String is empty")
        }
    }

    @objc
    private func savePhotoToAlbum(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error == nil {
            if let onSuccess = self.args["onSuccess"] as? String,
                let api = self.api {
                callbackWith(api: api, funcName: onSuccess, arguments: [])
            }
            SaveImageHandler.logger.debug("SaveImageHandler success, image = \(image)")
        } else {
            if let onFailed = self.args["onFailed"] as? String,
            let api = self.api {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
            SaveImageHandler.logger.error("SaveImageHandler faild, error = \(String(describing: error))")
        }
    }

}
