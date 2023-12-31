//
//  PreviewImageQRCodeDetectionPlugin.swift
//  OPPlugin
//
//  Created by ByteDance on 2022/11/25.
//

import Foundation
import Swinject
import LarkContainer
import QRCode
import LarkAssetsBrowser
import UniverseDesignToast
import OPPluginBiz
import LKCommonsLogging
import OPFoundation
import LarkSetting

public protocol OPQRCodeAnalysisProxy {
    func handle(code: String, fromVC: UIViewController, errorHandler: @escaping (String?) -> Void)
}

final class PreviewImageQRCodeDetectionPlugin: LKAssetBrowserPlugin {
    static let logger = Logger.oplog(PreviewImageQRCodeDetectionPlugin.self, category: "QRCodeDetectionPlugin")
    
    @InjectedSafeLazy var qrCodeAnalysisProvider: OPQRCodeAnalysisProxy
    
    @FeatureGatingValue(key: "openplatform.api.enable.preview.new.qrcode_detection")
    private var enableNewQRCode: Bool

    var uniqueID:OPAppUniqueID
    
    var code: String?

    init(uniqueID: OPAppUniqueID) {
        self.uniqueID = uniqueID
        super.init()
    }

    override var type: LKAssetPluginPosition {
        .actionSheet
    }

    override var title: String? {
        BDPI18n.extract_qr_code
    }

    override func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        var _image: UIImage?
        if let page = context.currentPage as? LKAssetBaseImagePage {
            if let image = page.imageView.image {
                _image = image
            }
        }else if let page = context.currentPage as? LKAssetByteImageViewPage {
            if let image = page.imageView.image {
                _image = image
            }
        }
        guard let image = _image else { return false }
        if let detectedCode = detectQRCode(image) {
            Self.logger.info("shouldDisplayQRCodeDetectionPlugin detectedCode:\(detectedCode)")
            code = detectedCode
            return true
        }else {
            Self.logger.info("shouldDisplayQRCodeDetectionPlugin image has no QRCode ")
        }
        return false
    }

    override func handleAsset(on context: LKAssetBrowserContext) {
        guard let code = code else { return }
        processQRCode(code)
    }
    
    private func detectQRCode(_ image: UIImage) -> String? {
        return QRCodeTool.scan(from: image)
    }

    private func processQRCode(_ code: String) {
        guard let browser = currentContext?.assetBrowser, let window = browser.view.window else { return }
        Self.logger.info("start processQRCode:\(code),enableNewQRCode:\(enableNewQRCode)")
        if enableNewQRCode {
            browser.dismiss(animated: false) {
                guard let topMost = OPNavigatorHelper.topMostAppController(window: nil) else {
                    Self.logger.error("processQRCode get topMost VC fail")
                    return
                }
                self.qrCodeAnalysisProvider.handle(code: code, fromVC: topMost) { errorInfo in
                    Self.logger.error("qrCodeAnalysisProvider error:\(String(describing: errorInfo))")
                }
            }
        }else {
            EMAPluginImagePreviewHandler.handelQRCode(code, from: browser, uniqueID: uniqueID)
        }
    }
}
