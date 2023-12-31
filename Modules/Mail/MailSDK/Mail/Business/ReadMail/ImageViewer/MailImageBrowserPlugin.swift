//
//  MailImageBrowserPlugin.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/13.
//

import Foundation
import LarkAssetsBrowser
import UniverseDesignIcon
import QRCode
import ByteWebImage

// MARK: Edit Image Plugin

final class MailImageBrowserEditImagePlugin: LKAssetBrowserPlugin {

    override var type: LKAssetPluginPosition {
        .all
    }

    override var icon: UIImage? {
        UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    }

    override var title: String? {
        BundleI18n.MailSDK.Mail_ViewImage_EditImage_Button
    }

    override func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        guard let page = context.currentPage as? LKAssetByteImagePage,
              let image = page.imageView.image as? ByteImage else {
            return false
        }
        if image.animatedImageData != nil {
            // gif 不支持编辑
            return false
        }
        return true
    }

    override func handleAsset(on context: LKAssetBrowserContext) {
        guard let browser = context.assetBrowser as? MailImageBrowser,
              let page = context.currentPage as? LKAssetByteImagePage,
              let image = page.imageView.image else {
            return
        }
        browser.showEditImageViewController(
            image: image,
            asset: context.currentAsset,
            from: browser
        )
        if context.actionInfo.ifFromBottomButton {
            browser.eventTracker.clickOuterAction("edit_image", at: browser.currentPageIndex)
        } else {
            browser.eventTracker.clickMenuAction("edit_image", hasQRCode: browser.hasQRCode())
        }
    }
}

// MARK: Save Image Plugin

final class MailImageBrowserSaveImagePlugin: LKAssetBrowserPlugin {

    override var type: LKAssetPluginPosition {
        .all
    }

    override var icon: UIImage? {
        UDIcon.getIconByKey(.downloadOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    }

    override var title: String? {
        BundleI18n.MailSDK.Mail_ViewImage_SaveImage_Button
    }

    override func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        return true
    }

    override func handleAsset(on context: LKAssetBrowserContext) {
        guard let browser = context.assetBrowser as? MailImageBrowser,
              let page = context.currentPage as? LKAssetByteImagePage,
              let image = page.imageView.image else {
            return
        }
        browser.saveImageToAlbum(
            imageAsset: context.currentAsset,
            image: image,
            tokenForAsset: MailSensitivityApiToken.saveImageForAsset,
            tokenForCreationRequest: MailSensitivityApiToken.saveImageCreationRequestForAsset,
            from: context.assetBrowser,
            saveImageCompletion: nil
        )
        if context.actionInfo.ifFromBottomButton {
            browser.eventTracker.clickOuterAction("save_image", at: browser.currentPageIndex)
        } else {
            browser.eventTracker.clickMenuAction("save_image", hasQRCode: browser.hasQRCode())
        }
    }
}

// MARK: Share To Chat Plugin

final class MailImageBrowserShareToChatPlugin: LKAssetBrowserPlugin {

    override var type: LKAssetPluginPosition {
        .actionSheet
    }

    override var title: String? {
        BundleI18n.MailSDK.Mail_ViewImage_ShareToChat_Button
    }

    override func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        return true
    }

    override func handleAsset(on context: LKAssetBrowserContext) {
        guard let browser = context.assetBrowser as? MailImageBrowser,
              let page = context.currentPage as? LKAssetByteImagePage,
              let image = page.imageView.image else {
            return
        }
        browser.shareToChat(
            image: image,
            asset: context.currentAsset,
            from: browser,
            shouldDismissFromVC: false
        )
        browser.eventTracker.clickMenuAction("share_image", hasQRCode: browser.hasQRCode())
    }
}

// MARK: Open In Another App Plugin

final class MailImageBrowserOpenInAnotherAppPlugin: LKAssetBrowserPlugin {

    override var type: LKAssetPluginPosition {
        .actionSheet
    }

    override var title: String? {
        BundleI18n.MailSDK.Mail_ViewImage_OpenInAnotherApp_Button
    }

    override func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        return true
    }

    override func handleAsset(on context: LKAssetBrowserContext) {
        guard let browser = context.assetBrowser as? MailImageBrowser,
              let page = context.currentPage as? LKAssetByteImagePage,
              let image = page.imageView.image else {
            return
        }
        browser.openWithOtherApp(
            image: image,
            asset: context.currentAsset,
            from: browser
        )
        browser.eventTracker.clickMenuAction("other_app_open", hasQRCode: browser.hasQRCode())
    }
}

// MARK: Detect QRCode Plugin

final class MailImageBrowserDetectQRCodePlugin: LKAssetBrowserPlugin {

    override var type: LKAssetPluginPosition {
        .actionSheet
    }

    override var title: String? {
        BundleI18n.MailSDK.Mail_ViewImage_ScanQRCode_Button
    }

    override func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        guard let browser = context.assetBrowser as? MailImageBrowser else {
            return false
        }
        if let qrResult = browser.qrResults[context.currentAsset.identifier] {
            return qrResult.hasQRCode
        } else {
            // 原来的实现就是截图扫描，可能考虑到原图分辨率过高的情况，暂时保留此逻辑
            let result = browser.view.lu.screenshot().flatMap { QRCodeTool.scan(from: $0) }
            let hasQRCode = result != nil
            browser.qrResults[context.currentAsset.identifier] = (hasQRCode, result)
            return hasQRCode
        }
    }

    override func handleAsset(on context: LKAssetBrowserContext) {
        guard let browser = context.assetBrowser as? MailImageBrowser,
              let qrResult = browser.qrResults[context.currentAsset.identifier],
              qrResult.hasQRCode, let code = qrResult.code else {
            return
        }
        browser.scanQRCode(code)
        browser.eventTracker.clickMenuAction("qr_code", hasQRCode: browser.hasQRCode())
    }
}
