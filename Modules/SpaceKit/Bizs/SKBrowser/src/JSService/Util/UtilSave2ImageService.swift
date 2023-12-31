//
//  UtilSave2ImageService.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/1/28.
//

import Foundation
import SKCommon
import SKFoundation
import LarkSensitivityControl
import UniverseDesignToast
import SKResource
import SKInfra

public final class UtilSave2ImageService: BaseJSService {
    var callback: String?

    private var helper: UtilSave2ImageServiceHelper?
}

extension UtilSave2ImageService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.save2Image]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard let base64 = params["data"] as? String,
            let callback = params["callback"] as? String else {
            DocsLogger.info("缺少参数")
            return
        }

        helper = UtilSave2ImageServiceHelper(callback, jsEngine: model?.jsEngine)

        if let image = UIImage.docs.image(base64: base64) {
            do {
                try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: Token(PSDATokens.MindNote.mindnote_preview_image_do_download), image, helper, #selector(helper?.image(_:didFinishSavingWithError:contextInfo:)), nil)
            } catch {
                DocsLogger.error("AlbumEntry UIImageWriteToSavedPhotosAlbum err")
                model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["code": "0"], completion: nil)
            }
        } else {
            // 保存失败
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["code": "0"], completion: nil)
        }
    }
}

private class UtilSave2ImageServiceHelper: NSObject {
    var callback: String
    var jsEngine: BrowserJSEngine?

    init(_ callback: String, jsEngine: BrowserJSEngine?) {
        self.callback = callback
        self.jsEngine = jsEngine
        super.init()
    }

    @objc
     func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) { // 保存结果
        if let e = error {
            DocsLogger.info("保存图片发生错误", extraInfo: ["error": e])
            jsEngine?.callFunction(DocsJSCallBack(callback), params: ["code": "0"], completion: nil)
        } else {
            DocsLogger.info("保存图片成功")
            jsEngine?.callFunction(DocsJSCallBack(callback), params: ["code": "1"], completion: nil)
        }
    }
}
