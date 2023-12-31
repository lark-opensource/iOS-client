//
//  WikiAssetBrowser.swift
//  LarkAssetsBrowser
//
//  Created by Hayden Wang on 2022/2/10.
//

import Foundation
import UIKit
import QRCode
import Swinject
import LarkQRCode
import EENavigator
import LarkContainer
import LarkAssetsBrowser
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkSensitivityControl

public final class WikiAssetBrowser: LKAssetBrowser, UserResolverWrapper {

    public static var appLinkPath: String = "/client/photo_picker/open"
//    public static var appLinkPath: String = "/client/applock/setting"

    public var isQRDetectionEnabled: Bool = false
    public var isSavingImageEnabled: Bool = false

    public let userResolver: UserResolver

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.onLongPressed = { [weak self] _ in
            guard let self = self else { return }
            self.showLongPressActionSheetIfNeeded()
        }
    }

    private func showLongPressActionSheetIfNeeded() {
        guard isQRDetectionEnabled || isSavingImageEnabled else { return }
        guard let currentPage = galleryView.currentPage as? LKAssetBaseImagePage,
              let currentImage = currentPage.imageView.image else { return }

        var shouldShowActionPanel: Bool = false
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false))

        if isSavingImageEnabled {
            shouldShowActionPanel = true
            actionSheet.addDefaultItem(text: BundleI18n.LarkSearchCore.Lark_Legacy_ImageSave) { [weak self] in
                self?.saveImage(currentImage)
            }
        }
        if isQRDetectionEnabled, let code = detectQRCode(currentImage) {
            shouldShowActionPanel = true
            actionSheet.addDefaultItem(text: BundleI18n.LarkSearchCore.Lark_Legacy_QRCode) { [weak self] in
                self?.scanQRCode(code)
            }
        }
        guard shouldShowActionPanel else { return }
        actionSheet.setCancelItem(text: BundleI18n.LarkSearchCore.Lark_Legacy_Cancel)
        userResolver.navigator.present(actionSheet, from: self)
    }

    // MARK: Save Image

    private func saveImage(_ image: UIImage) {
        do {
            let token = Token("LARK-PSDA-enter_wiki_photo_page_save_photo")
            try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: token, image, self, #selector(saveCompleted), nil)
        } catch {
            let showView: UIView = self.view.window ?? self.view
            UDToast.showFailure(with: BundleI18n.LarkSearchCore.Lark_Legacy_PhotoZoomingSaveImageFail, on: showView)
        }
    }

    @objc
    private func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        // save finished
        let showView: UIView = self.view.window ?? self.view
        if error != nil {
            UDToast.showFailure(with: BundleI18n.LarkSearchCore.Lark_Legacy_PhotoZoomingSaveImageFail, on: showView)
        } else {
            UDToast.showSuccess(with: BundleI18n.LarkSearchCore.Lark_Legacy_QrCodeSaveToAlbum, on: showView)
        }
    }

    // MARK: Scan QRCode

    private lazy var qrCodeAnalysis: QRCodeAnalysisService? = {
        return try? userResolver.resolve(assert: QRCodeAnalysisService.self)
    }()

    private func detectQRCode(_ image: UIImage) -> String? {
        return QRCodeTool.scan(from: image)
    }

    private func scanQRCode(_ code: String) {
        let status: QRCodeAnalysisCallBack = { [weak self] status, callback in
            switch status {
            case .preFinish:
                break
            case .fail(errorInfo: let errorInfo):
                guard let window = self?.view.window else { return }
                if let errorInfo = errorInfo {
                    UDToast.showFailure(with: errorInfo, on: window)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkSearchCore.Lark_Legacy_QrCodeQrCodeError, on: window)
                }
            }
            callback?()
        }
        qrCodeAnalysis?.handle(code: code, status: status, from: .pressImage, fromVC: self)
    }
}
