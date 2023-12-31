//
//  AssetBrowserActionHandler.swift
//  Lark
//
//  Created by 刘晚林 on 2017/8/11.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkActionSheet
import LarkUIKit
import LarkModel
import LarkMessengerInterface
import LarkFoundation
import RxSwift
import Photos
import RxCocoa
import Reachability
import UniverseDesignToast
import QRCode
import EENavigator
import LarkSDKInterface
import LarkKAFeatureSwitch
import LarkEnv
import LKCommonsLogging
import LKCommonsTracker
import LarkAssetsBrowser
import LarkImageEditor
import LarkCache
import LarkContainer
import LarkKeyCommandKit
import LarkReleaseConfig
import ByteWebImage
import UniverseDesignActionPanel
import LarkAccountInterface
import LarkOCR
import LarkFeatureGating
import LarkEMM
import LarkLocalizations
import LarkSecurityComplianceInterface
import LarkSensitivityControl
import LarkSendMessage // MediaDiskUtil

private typealias Path = LarkSDKInterface.PathWrapper

private final class SaveVideoDisplayViewWrappar {
    weak var videoDisplayView: LKVideoDisplayViewProtocol?
}

/// 图片/视频批量下载相关，LKAssetBrowserActionHandler.handleSaveAssets中使用
public enum SaveAssetsError: Error {
    /// 其他通用错误
    case mediaInfoError
    /// 安全检测错误
    case imageSecurityError(ValidateResult, SecurityControlEvent)
}

final public class AssetBrowserActionHandler: LKAssetBrowserActionHandler, UserResolverWrapper {

    public let userResolver: UserResolver
    private static let logger = Logger.log(AssetBrowserActionHandler.self, category: "LarkCore.AssetBrowserActionHandler")
    private let disposeBag = DisposeBag()
    private let resourceAPI: ResourceAPI
    private let videoSaveService: VideoSaveService
    private var showSaveToCloud: Bool
    /// 控制是否可以保存到相册
    private let canSaveImage: Bool
    private var canEditImage: Bool
    private var canTranslate: Bool
    private var canImageOCR: Bool
    private let reachability = Reachability()
    private var isInWifi: Bool {
        return (reachability?.connection ?? .none) == .wifi
    }
    private var qrCodeScanResult: String?
    private weak var browser: LKAssetBrowserViewController?
    private var scanQR: ((String) -> Void)?
    private let loadMoreOldAsset: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)?
    private let loadMoreNewAsset: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)?
    private let shareImage: ((String, UIImage) -> Void)?
    private let viewInChat: ((LKDisplayAsset) -> Void)?
    private let onSaveImage: ((LKDisplayAsset) -> Void)?
    private let saveImageFinishCallBack: ((LKDisplayAsset?, _ succeed: Bool) -> Void)? //当保存图片回调需要区分成功/失败的状态时，用这个block
    private let onEditImage: ((LKDisplayAsset) -> Void)?
    private let onNextImage: ((LKDisplayAsset) -> Void)?
    private let onSaveVideo: ((MediaInfoItem) -> Void)?
    private let viewInChatTitle: String
    private let fromWhere: PreviewImagesFromWhere
    private let addToSticker: ((LKDisplayAsset) -> Void)?
    /// 用户操作行为
    /// 目前用于安全管控
    private enum OperateType {
        case save
        case edit
        case forward
        case ocr
        case addToStick
    }

    @ScopedInjectedLazy private var dependency: LarkCoreVCDependency?
    @ScopedInjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy private var messageAPI: MessageAPI?
    @ScopedInjectedLazy private var fileAPI: SecurityFileAPI?
    @ScopedInjectedLazy private var passportUser: PassportUserService?
    var mediaDiskUtil: MediaDiskUtil { .init(userResolver: userResolver) }

    private weak var currentVideoPlayProxy: LKVideoDisplayViewProtocol?
    private weak var currentVideoAsset: LKDisplayAsset?
    // 存储需要下载的videoDisplayView(LKVideoDisplayViewProtocol)，key：mediaInfoItem.messageId
    // 添加此参数的目的：保存视频后滑动到另一个资源，此时LKVideoDisplayViewProtocol改变，所以需要保存以便下载进度返回后，可以隐藏HUD等操作
    private var videoDisplayViewDic = [String: SaveVideoDisplayViewWrappar]()
    lazy var isOversea: Bool = {
        !(passportUser?.isFeishuBrand ?? true)
    }()

    private let shouldDetectFile: Bool

    init(userResolver: UserResolver,
         resourceAPI: ResourceAPI,
         videoSaveService: VideoSaveService,
         shouldDetectFile: Bool,
         showSaveToCloud: Bool,
         canSaveImage: Bool,
         canEditImage: Bool,
         canTranslate: Bool,
         canImageOCR: Bool = false,
         scanQR: ((String) -> Void)? = nil,
         loadMoreOldAsset: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)? = nil,
         loadMoreNewAsset: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)? = nil,
         shareImage: ((String, UIImage) -> Void)? = nil,
         viewInChat: ((LKDisplayAsset) -> Void)? = nil,
         viewInChatTitle: String,
         fromWhere: PreviewImagesFromWhere,
         onSaveImage: ((LKDisplayAsset) -> Void)? = nil,
         saveImageFinishCallBack: ((LKDisplayAsset?, _ succeed: Bool) -> Void)? = nil,
         onEditImage: ((LKDisplayAsset) -> Void)? = nil,
         onNextImage: ((LKDisplayAsset) -> Void)? = nil,
         onSaveVideo: ((MediaInfoItem) -> Void)? = nil,
         addToSticker: ((LKDisplayAsset) -> Void)? = nil) {
        self.userResolver = userResolver
        self.resourceAPI = resourceAPI
        self.videoSaveService = videoSaveService
        self.shouldDetectFile = shouldDetectFile && userResolver.fg.staticFeatureGatingValue(with: "messenger.file.detect")
        self.showSaveToCloud = showSaveToCloud
        self.canSaveImage = canSaveImage
        self.canEditImage = canEditImage
        self.onNextImage = onNextImage
        self.canTranslate = canTranslate
        self.scanQR = scanQR
        self.loadMoreOldAsset = loadMoreOldAsset
        self.loadMoreNewAsset = loadMoreNewAsset
        self.shareImage = shareImage
        self.viewInChat = viewInChat
        self.viewInChatTitle = viewInChatTitle
        self.fromWhere = fromWhere
        if fromWhere == .chatHistory {
            CoreTracker.picBrowserInChatHistory()
        }
        self.onSaveImage = onSaveImage
        self.saveImageFinishCallBack = saveImageFinishCallBack
        self.onEditImage = onEditImage
        self.onSaveVideo = onSaveVideo
        self.addToSticker = addToSticker
        self.canImageOCR = canImageOCR
        super.init()

        self.addSaveProgressObserver()
    }

    private func presentActionSheet(image: UIImage,
                                    asset: LKDisplayAsset,
                                    browser: LKAssetBrowserViewController,
                                    sourceView: UIView?) {
        guard let currentPageView = browser.currentPageView else { return }
        self.browser = browser
        let topmostFrom = WindowTopMostFrom(vc: browser)

        let source: UIView
        let sourceRect: CGRect
        if let sourceView = sourceView {
            source = sourceView
            sourceRect = CGRect(origin: .zero, size: sourceView.bounds.size)
        } else {
            source = currentPageView
            sourceRect = CGRect(origin: currentPageView.longGesture.location(in: currentPageView), size: .zero)
        }

        let popSource = UDActionSheetSource(sourceView: source,
                                            sourceRect: sourceRect)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: popSource))
        var shouldPresentSheet: Bool = false

        var isAnimatedImage = asset.isGIf()
        if let byteImage = image as? ByteImage {
            isAnimatedImage = byteImage.isAnimatedImage
        }

        var showOCRIcon = false
        if canImageOCR,
           !asset.isVideo,
           !isAnimatedImage,
           userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.ocr.image_to_text")),
           let ocrResult = asset.extraInfo[ImageShowOcrButtonKey] as? Bool,
           ocrResult {
            showOCRIcon = true
            // OCR 识别
            actionSheet.addDefaultItem(text: BundleI18n.LarkCore.Lark_IM_ImageToText_ExtractText_Button) { [weak self] in
                guard let self = self else { return }
                PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .identify_image)
                var imageKey = asset.originalImageKey ?? ""
                if imageKey.isEmpty {
                    imageKey = asset.key
                }
                var extra: [String: Any] = [:]
                if let messageId = asset.extraInfo[ImageAssetMessageIdKey] as? String {
                    extra[RustOCRService.MessageIDKey] = messageId
                }
                if let scene = asset.extraInfo[ImageAssetDownloadSceneKey] {
                    extra[RustOCRService.DownloadSceneKey] = scene
                }

                self.isOperationAllowed(messageID: asset.extraInfo[ImageAssetMessageIdKey] as? String,
                                        fatherMFId: asset.extraInfo[ImageAssetFatherMFIdKey] as? String,
                                        replyInthreadRootId: asset.extraInfo[ImageAssetReplyThreadRootIdKey] as? String,
                                        operateType: .ocr)
                .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] isAllowed in
                        guard let self = self else { return }
                        if !isAllowed { return }
                        let config = ImageOCRConfig(
                            image: image,
                            imageKey: imageKey,
                            service: RustOCRService(userResolver: self.userResolver),
                            delegate: self,
                            extra: extra
                        )
                        let recognitionController = OCRRecognitionController(config: config)
                        let navi = LkNavigationController(rootViewController: recognitionController)
                        navi.modalPresentationStyle = .currentContext
                        self.userResolver.navigator.present(navi, from: topmostFrom, animated: false)
                    }).disposed(by: self.disposeBag)
            }
        }
        Tracker.post(TeaEvent("public_identify_image_icon_view", params: [
            "occasion": "picbrowser_more",
            "has_identify_icon": showOCRIcon ? true : false
        ]))

        var showTranslateIcon = false
        // 图片翻译
        if canTranslate && delegate?.canTranslate(assetKey: asset.originalImageKey ?? "") ?? false {
            showTranslateIcon = true
            shouldPresentSheet = true
            AssetBrowserActionHandler.logger.info("handleLongPress in asset >> \(asset.key), translateProperty >> \(asset.translateProperty)")
            switch asset.translateProperty {
            case .origin:
                actionSheet.addDefaultItem(text: BundleI18n.LarkCore.Lark_Chat_TranslateImageText) { [weak self] in
                    PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .translate)
                    self?.delegate?.handleTranslate(asset: asset)
                }
            case .translated:
                actionSheet.addDefaultItem(text: BundleI18n.LarkCore.Lark_Chat_ViewOriginalImage) { [weak self] in
                    PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .translate)
                    self?.delegate?.handleTranslate(asset: asset)
                }
            @unknown default: break
            }
        }
        Tracker.post(TeaEvent("public_image_translate_icon_view", params: [
            "occasion": "picbrowser_more",
            "has_translate_icon": showTranslateIcon ? true : false
        ]))

        if canSaveImage {
            shouldPresentSheet = true
            var itemTitle = ""
            switch asset.translateProperty {
            case .origin:
                itemTitle = BundleI18n.LarkCore.Lark_Legacy_ImageSave
            case .translated:
                itemTitle = BundleI18n.LarkCore.Lark_Chat_SaveTranslatedImage
            @unknown default: break
            }
            actionSheet.addDefaultItem(text: itemTitle) { [weak self] in
                PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .save)
                self?.saveImageToAlbum(imageAsset: asset, image: image, saveImageCompletion: nil)
            }
        }

        // 跳转至会话
        if let viewInChat = viewInChat {
            shouldPresentSheet = true
            actionSheet.addDefaultItem(text: viewInChatTitle) { [weak self] in
                PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .jump_to_chat)
                if self?.fromWhere ?? .other == .chatHistory {
                    CoreTracker.picBowserGoChatInChatHistory()
                }
                self?.delegate?.dismissViewController(completion: {
                    viewInChat(asset)
                })
            }
        }

        if let addToSticker = addToSticker, asset.translateProperty == .origin, !asset.isVideo {
            shouldPresentSheet = true
            actionSheet.addDefaultItem(text: BundleI18n.LarkCore.Lark_Legacy_AddStickerForChat) { [weak self] in
                PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .sticker_save)
                if let self = self {
                    self.isOperationAllowed(messageID: asset.extraInfo[ImageAssetMessageIdKey] as? String,
                                            fatherMFId: asset.extraInfo[ImageAssetFatherMFIdKey] as? String,
                                            replyInthreadRootId: asset.extraInfo[ImageAssetReplyThreadRootIdKey] as? String,
                                            operateType: .addToStick)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { isAllowed in
                        if !isAllowed { return }
                        addToSticker(asset)
                    }).disposed(by: self.disposeBag)
                } else {
                    addToSticker(asset)
                }
            }
        }

        // 编辑，gif不支持编辑
        if self.canEditImage, (image as? ByteImage)?.animatedImageData == nil {
            shouldPresentSheet = true
            actionSheet.addDefaultItem(text: BundleI18n.LarkCore.Lark_Legacy_Edit) { [weak self] in
                PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .edit)
                guard let self = self else {
                    return
                }
                let messageId = asset.extraInfo[ImageAssetMessageIdKey] as? String
                // 检查安全管控状态后再允许进入编辑界面，如果有saveImage的dlp信息，则进编辑时不检测，延后到保存
                (asset.securityExtraInfo(for: .saveImage) != nil ? .just(true) : self.checkImageOperateSecurity(.edit, messageID: messageId))
                    .filter { $0 == true }
                    .flatMap { [weak self] ( _ ) -> Observable<Bool> in
                        self?.isOperationAllowed(messageID: asset.extraInfo[ImageAssetMessageIdKey] as? String,
                                                 fatherMFId: asset.extraInfo[ImageAssetFatherMFIdKey] as? String,
                                                 replyInthreadRootId: asset.extraInfo[ImageAssetReplyThreadRootIdKey] as? String,
                                                 operateType: .edit) ?? .just(true)
                    }
                    .filter { $0 == true }
                    .flatMap { [weak self] ( _ ) -> Observable<Bool> in
                        self?.canDownLoadByFileDetecting(asset: asset, from: topmostFrom) ?? .just(true)
                    }
                    .filter { $0 == true }
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.showEditImageViewController(image: image, asset: asset, from: topmostFrom)
                    }).disposed(by: self.disposeBag)
            }
        }

        // 分享图片
        if let share = self.shareImage {
            shouldPresentSheet = true
            var forwardText = BundleI18n.LarkCore.Lark_Legacy_Forward
            if canTranslate && asset.translateProperty != .origin {
                forwardText = BundleI18n.LarkCore.Lark_IM_ForwardOriginalImage_Button
            }
            actionSheet.addDefaultItem(text: forwardText) { [weak self] in
                PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .forward)
                // 此处可以直接使用image转发：大图预览时都是下载的原图，在原图未下载完成时用户无法进行交互。
                if let self = self {
                    self.isOperationAllowed(messageID: asset.extraInfo[ImageAssetMessageIdKey] as? String,
                                            fatherMFId: asset.extraInfo[ImageAssetFatherMFIdKey] as? String,
                                            replyInthreadRootId: asset.extraInfo[ImageAssetReplyThreadRootIdKey] as? String,
                                            operateType: .forward)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { isAllowed in
                        if !isAllowed { return }
                            share(asset.key, image)
                        }).disposed(by: self.disposeBag)
                } else {
                    share(asset.key, image)
                }
            }
        }

        // 扫码二维码
        if let scanQR = scanQR {
            if userResolver.fg.dynamicFeatureGatingValue(with: "im.scan_code.multi_code_identification") {
                var imageInfos = MultiQRCodeScanner.ImageInfos(image: .uiImage(image))
                if let currentPageView = currentPageView as? LKAssetMultiQRCodeScannablePage {
                    if let originalImageData = currentPageView.originalImageData {
                        imageInfos = .init(image: .data(originalImageData))
                    }
                    imageInfos.zoomFactor = currentPageView.currentImageScale
                    imageInfos.visibleRect = currentPageView.visibleRect
                    imageInfos.customDisplayImage = currentPageView.visibleImage
                }
                imageInfos.identifier = asset.originalImageKey ?? asset.key
                if case .success(let infos) = MultiQRCodeScanner.scanCodes(image: imageInfos,
                                                                           setting: userResolver.settings),
                   !infos.isEmpty {
                    shouldPresentSheet = true
                    // 目前 只能识别 二维码和条形码
                    let barCodesCount = infos.filter({ $0.type == .barCode }).count
                    let qrCodesCount = infos.count - barCodesCount
                    let text = if barCodesCount > 0 {
                        if qrCodesCount > 0 {
                            BundleI18n.LarkCore.Lark_IM_ScanBarcodeOrQR_Button
                        } else {
                            BundleI18n.LarkCore.Lark_IM_ScanBarcode_Button
                        }
                    } else {
                        BundleI18n.LarkCore.Lark_Legacy_QRCode
                    }
                    actionSheet.addDefaultItem(text: text) { [weak self] in
                        guard let self else { return }
                        PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .identify_QR)
                        MultiQRCodeScanner.pickCode(image: imageInfos,
                                                    from: browser,
                                                    codeInfos: infos,
                                                    setting: self.userResolver.settings) { code in
                            guard let code else { return }
                            scanQR(code.content)
                        }
                    }
                }
            } else {
                qrCodeScanResult = browser.view.lu.screenshot().flatMap { QRCodeTool.scan(from: $0) }
                if let code = qrCodeScanResult {
                    shouldPresentSheet = true
                    actionSheet.addDefaultItem(text: BundleI18n.LarkCore.Lark_Legacy_QRCode) { [weak self] in
                        PublicTracker.AssetsBrowser.Click.browserMoreClick(action: .identify_QR)
                        self?.delegate?.dismissViewController { scanQR(code) }
                    }
                }
            }
        }
        guard shouldPresentSheet else { return }

        actionSheet.setCancelItem(text: BundleI18n.LarkCore.Lark_Legacy_Cancel)
        userResolver.navigator.present(actionSheet, from: browser)
    }

    public override func handleClickLoadOrigin() {
        PublicTracker.AssetsBrowser.Click.browserClick(action: .originImage)
    }

    public override func handleClickTranslate() {
        PublicTracker.AssetsBrowser.Click.browserClick(action: .translate)
    }

    public override func handleClickAlbum() {
        PublicTracker.AssetsBrowser.Click.browserClick(action: .chatAlbum)
        PublicTracker.AssetsBrowser.chatAlbumView()
    }

    public override func handleLongPressFor(image: UIImage, asset: LKDisplayAsset, browser: LKAssetBrowserViewController, sourceView: UIView?) {
        PublicTracker.AssetsBrowser.Click.browserClick(action: .press)
        self.presentActionSheet(image: image,
                                asset: asset,
                                browser: browser,
                                sourceView: sourceView)
    }

    public override func handleClickMoreButton(image: UIImage,
                                        asset: LKDisplayAsset,
                                        browser: LKAssetBrowserViewController,
                                        sourceView: UIView?) {
        PublicTracker.AssetsBrowser.Click.browserClick(action: .more)
        PublicTracker.AssetsBrowser.moreView()
        self.presentActionSheet(image: image,
                                asset: asset,
                                browser: browser,
                                sourceView: sourceView)
    }

    public override func handleSaveAsset(_ asset: LKDisplayAsset, relatedImage: UIImage?, saveImageCompletion: ((Bool) -> Void)?) {
        if !self.canSaveImage {
            return
        }
        PublicTracker.AssetsBrowser.Click.browserClick(action: .download)
        if asset.isVideo {
            self.saveVideo(asset: asset, mediaInfoItem: self.mediaInfoItem(from: asset))
        } else {
            self.saveImageToAlbum(imageAsset: asset, image: relatedImage, saveImageCompletion: saveImageCompletion)
        }
    }

    public override func handleClickPhotoEditting(image: UIImage, asset: LKDisplayAsset, from browser: LKAssetBrowserViewController) {
        if !self.canEditImage {
            return
        }
        PublicTracker.AssetsBrowser.Click.browserClick(action: .edit)
        let messageId = asset.extraInfo[ImageAssetMessageIdKey] as? String
        // 检查DLP的状态后再允许进入编辑界面，如果有saveImage的dlp信息，则进编辑时不检测，延后到保存
        (asset.securityExtraInfo(for: .saveImage) != nil ? .just(true) : self.checkImageOperateSecurity(.edit, messageID: messageId))
            .filter { $0 == true }
            .flatMap { [weak self] ( _ ) -> Observable<Bool> in
                self?.isOperationAllowed(messageID: asset.extraInfo[ImageAssetMessageIdKey] as? String,
                                         fatherMFId: asset.extraInfo[ImageAssetFatherMFIdKey] as? String,
                                         replyInthreadRootId: asset.extraInfo[ImageAssetReplyThreadRootIdKey] as? String,
                                         operateType: .edit) ?? .just(true)
            }
            .filter { $0 == true }
            .flatMap { [weak self] ( _ ) -> Observable<Bool> in
                self?.canDownLoadByFileDetecting(asset: asset, from: browser) ?? .just(true)
            }
            .filter { $0 == true }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.showEditImageViewController(image: image, asset: asset, from: browser)
            }).disposed(by: self.disposeBag)
    }

    public override func handleClickPhotoOCR(image: UIImage, asset: LKDisplayAsset, from browser: LKAssetBrowserViewController) {
        var isAnimatedImage = asset.isGIf()
        if let byteImage = image as? ByteImage {
            isAnimatedImage = byteImage.isAnimatedImage
        }
        if canImageOCR,
           !asset.isVideo,
           !isAnimatedImage,
           userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.ocr.image_to_text")) {
            // OCR 识别
            var imageKey = asset.originalImageKey ?? ""
            if imageKey.isEmpty {
                imageKey = asset.key
            }
            var extra: [String: Any] = [:]
            if let messageId = asset.extraInfo[ImageAssetMessageIdKey] as? String {
                extra[RustOCRService.MessageIDKey] = messageId
            }
            if let scene = asset.extraInfo[ImageAssetDownloadSceneKey] {
                extra[RustOCRService.DownloadSceneKey] = scene
            }

            isOperationAllowed(messageID: asset.extraInfo[ImageAssetMessageIdKey] as? String,
                               fatherMFId: asset.extraInfo[ImageAssetFatherMFIdKey] as? String,
                               replyInthreadRootId: asset.extraInfo[ImageAssetReplyThreadRootIdKey] as? String,
                               operateType: .ocr)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self]isAllowed in
                guard let self = self else { return }
                if !isAllowed { return }
                let config = ImageOCRConfig(
                    image: image,
                    imageKey: imageKey,
                    service: RustOCRService(userResolver: self.userResolver),
                    delegate: self,
                    extra: extra
                )
                let recognitionController = OCRRecognitionController(config: config)
                let navi = LkNavigationController(rootViewController: recognitionController)
                navi.modalPresentationStyle = .currentContext
                self.userResolver.navigator.present(navi, from: browser, animated: false)
            }).disposed(by: self.disposeBag)

            PublicTracker.AssetsBrowser.Click.browserClick(action: .identify_image)
        }
    }

    private func showEditImageViewController(image: UIImage, asset: LKDisplayAsset?, from: NavigatorFrom) {
        if let asset = asset {
            self.onEditImage?(asset)
        }
        let imageEditVC = ImageEditorFactory.createEditor(with: image)
        imageEditVC.delegate = self
        imageEditVC.editEventObservable.subscribe(onNext: {
            CoreTracker.trackImageEditEvent($0.event, params: $0.params)
        }).disposed(by: disposeBag)
        let navigationVC = LkNavigationController(rootViewController: imageEditVC)
        navigationVC.modalPresentationStyle = .fullScreen
        userResolver.navigator.present(navigationVC, from: from, animated: false)
    }

    // IM文件安全检测 - 图片资源
    private func canDownLoadByFileDetecting(asset: LKDisplayAsset, from: NavigatorFrom? = nil) -> Observable<Bool> {
        // FG
        guard self.shouldDetectFile else { return .just(true) }
        // 安全侧是否禁用风险文件下载
        return fileAPI?
            .canDownloadFile(
                detectRiskFileMeta: DetectRiskFileMeta(key: asset.originalImageKey ?? "", messageRiskObjectKeys: asset.riskObjectKeys)
            )
            .observeOn(MainScheduler.instance)
            .map { [weak self] canDownloadRiskFile in
                guard let self = self else { return canDownloadRiskFile }
                if !canDownloadRiskFile {
                    guard let originalImageKey = asset.originalImageKey else { return false }

                    /// 历史原因,服务端无法识别key前缀,需要替换
                    let imageQualityPrefixs = ["origin:", "middle:", "thumbnail:"]
                    var fixedKey = originalImageKey
                    for prefix in imageQualityPrefixs {
                        fixedKey = fixedKey.replacingOccurrences(of: prefix, with: "", options: .regularExpression)
                    }

                    let body = RiskFileAppealBody(fileKey: fixedKey, locale: LanguageManager.currentLanguage.rawValue)
                    if let from = from {
                        self.userResolver.navigator.present(body: body, from: from)
                    } else if let window = self.viewController?.view.window {
                        self.userResolver.navigator.present(body: body, from: window)
                    }
                }
                return canDownloadRiskFile
            }.catchErrorJustReturn(true) ?? .just(true)
    }

    // IM文件安全检测 - 视频资源
    private func canDownLoadByFileDetecting(mediaContent: MediaInfoItem) -> Observable<Bool> {
        // FG
        guard self.shouldDetectFile else { return .just(true) }
        // 安全侧是否禁用风险文件下载
        return fileAPI?
            .canDownloadFile(
                detectRiskFileMeta: DetectRiskFileMeta(
                    key: mediaContent.key, messageRiskObjectKeys: mediaContent.messageRiskObjectKeys
                )
            )
            .observeOn(MainScheduler.instance)
            .map { [weak self]canDownloadRiskFile in
                guard let self = self else { return canDownloadRiskFile }
                if !canDownloadRiskFile {
                    let body = RiskFileAppealBody(fileKey: mediaContent.key, locale: LanguageManager.currentLanguage.rawValue)
                    if let window = self.viewController?.view.window {
                        self.userResolver.navigator.present(body: body, from: window)
                    }
                }
                return canDownloadRiskFile
            }.catchErrorJustReturn(true) ?? .just(true)
    }

    /// 用户操作前进行的DLP安全侧管控
    private func checkImageOperateSecurity(_ operateType: OperateType, messageID: String?) -> Observable<Bool> {
        guard let messageID = messageID else {
            Self.logger.error("Get MessageID failed. checkOperateSecurity pass by default.")
            return .just(true)
        }
        return self.messageAPI?
            .fetchLocalMessage(id: messageID)
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] message -> Observable<Bool> in
                /// DLP管控检测
                switch message.dlpState {
                    // dlp检测失败后禁止保存或编辑,弹出toast,提示用户发送的消息涉及到企业敏感信息
                case .dlpBlock:
                    if let window = self?.viewController?.view.window {
                        let tipString: String
                        switch operateType {
                        case .save:
                            tipString = BundleI18n.LarkCore.Lark_IM_DLP_ImageSensitiveNoDownload_Toast
                        case .edit:
                            tipString = BundleI18n.LarkCore.Lark_IM_DLP_ImageSensitiveNoEdit_Toast
                        @unknown default:
                            assertionFailure("DLP has only save & edit operate type")
                            tipString = ""
                        }
                        UDToast.showFailure(
                            with: tipString,
                            on: window
                        )} else {
                            Self.logger.error("DLP State haven't Pass. Failed to unwrap 'self?.window' to push toast.")
                        }
                    let error = NSError(
                        domain: "dlpstate is dlpBlcok. Deny to save to album",
                        code: 0,
                        userInfo: ["dlpState": message.dlpState]
                    ) as Error
                    Self.logger.error("DLP State haven't Pass. Deny to save to album. Error: \(error)")
                    return .just(false)
                    // dlp检测中禁止保存或编辑,弹出toast,提示用户稍后重试
                case .dlpInProgress:
                    if let window = self?.viewController?.view.window {
                        let tipString: String
                        switch operateType {
                        case .save:
                            tipString = BundleI18n.LarkCore.Lark_IM_DLP_UnableToDownload_Toast
                        case .edit:
                            tipString = BundleI18n.LarkCore.Lark_IM_DLP_UnableToEditRetry_Toast
                        @unknown default:
                            assertionFailure("DLP has only save & edit operate type")
                            tipString = ""
                        }
                        UDToast.showFailure(with: tipString, on: window)
                    } else {
                        Self.logger.error("DLP State is DLPInProgress. Failed to unwrap 'self?.window' to push toast.")
                    }
                    let error = NSError(
                        domain: "dlpstate is dlpInProgress. Deny to save to album",
                        code: 0,
                        userInfo: ["dlpState": message.dlpState]
                    ) as Error
                    Self.logger.error("DLP State haven't Pass. Deny to save to album. Error: \(error)")
                    return .just(false)
                @unknown default:
                    break
                }
                /// 检测是否被设置为保密消息
                return .just(true)
            }.catchErrorJustReturn(true) ?? .just(true)
    }

    /// 根据消息ID判断操作是否被服务端禁用
    private func isOperationAllowed(messageID: String?,
                                     fatherMFId: String?,
                                     replyInthreadRootId: String?,
                                     operateType: OperateType) -> Observable<Bool> {
        guard let messageID = messageID else {
            return .just(true)
        }
        var messageIds: [String] = [messageID]
        if let fatherId = fatherMFId {
            messageIds.append(fatherId)
        } else if let replyInthreadRootId = replyInthreadRootId {
            messageIds.append(replyInthreadRootId)
        }

        var errorMessage: String?
        return self.messageAPI?
            .fetchMessages(ids: messageIds)
            .flatMap { messages -> Observable<Bool> in
                switch operateType {
                case .forward:
                    for message in messages {
                        if let disabled = message.disabledAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] {
                            switch disabled.code {
                            case 311_150:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_MessageRestrictedCantForward_Hover
                            default:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
                            }
                            break
                        }
                    }
                case .addToStick:
                    for message in messages {
                        if let disabled = message.disabledAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] {
                            switch disabled.code {
                            case 311_150:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_MessageRestrictedCantAddSticker_Toast
                            default:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
                            }
                            break
                        }
                    }
                    break
                case .edit:
                    for message in messages {
                        if let disabled = message.disabledAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] {
                            switch disabled.code {
                            case 311_150:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_MessageRestrictedCantEdit_Hover
                            default:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
                            }
                            break
                        }
                    }
                    break
                case .ocr:
                    for message in messages {
                        if let disabled = message.disabledAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] {
                            switch disabled.code {
                            case 311_150:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_MessageRestrictedCantExtractText_Toast
                            default:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
                            }
                            break
                        }
                    }
                    break
                case .save:
                    for message in messages {
                        if let disabled = message.disabledAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] {
                            switch disabled.code {
                            case 311_150:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_MessageRestrictedCantSave_Hover
                            default:
                                errorMessage = BundleI18n.LarkCore.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
                            }
                            break
                        }
                    }
                    break
                }
                if let errorMessage = errorMessage {
                    DispatchQueue.main.async { [weak self] in
                        guard let vc = self?.viewController, let window = WindowTopMostFrom(vc: vc).fromViewController?.view else { return }
                        UDToast.showFailure(with: errorMessage, on: window)
                    }
                }
                return .just(errorMessage == nil ? true : false)
            }.catchErrorJustReturn(false) ?? .just(false)
    }

    private func checkMediaOperateSecurity(_ operateType: OperateType, messageID: String?) -> Observable<Bool> {
        guard let messageID = messageID else {
            Self.logger.error("Get MessageID failed. DLP default pass.")
            return .just(true)
        }
        return self.messageAPI?
            .fetchLocalMessage(id: messageID)
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] message -> Observable<Bool> in
                switch message.dlpState {
                // dlp检测失败后禁止保存或编辑,弹出toast,提示用户发送的消息涉及到企业敏感信息
                case .dlpBlock:
                    if let window = self?.viewController?.view.window {
                        let tipString: String
                        switch operateType {
                        case .save:
                            tipString = BundleI18n.LarkCore.Lark_IM_DLP_ImageSensitiveNoDownload_Toast
                        case .edit:
                            tipString = BundleI18n.LarkCore.Lark_IM_DLP_ImageSensitiveNoEdit_Toast
                        @unknown default:
                            assertionFailure("DLP has only save & edit operate type")
                            tipString = ""
                        }
                        UDToast.showFailure(
                            with: tipString,
                            on: window
                        )} else {
                        Self.logger.error("DLP State haven't Pass. Failed to unwrap 'self?.window' to push toast.")
                    }
                    let error = NSError(
                        domain: "dlpstate is dlpBlcok. Deny to save to album",
                        code: 0,
                        userInfo: ["dlpState": message.dlpState]
                    ) as Error
                    Self.logger.error("DLP State haven't Pass. Deny to save to album. Error: \(error)")
                    return .just(false)
                // dlp检测中禁止保存或编辑,弹出toast,提示用户稍后重试
                case .dlpInProgress:
                    if let window = self?.viewController?.view.window {
                        let tipString: String
                        switch operateType {
                        case .save:
                            tipString = BundleI18n.LarkCore.Lark_IM_DLP_UnableToDownload_Toast
                        case .edit:
                            tipString = BundleI18n.LarkCore.Lark_IM_DLP_UnableToEditRetry_Toast
                        @unknown default:
                            assertionFailure("DLP has only save & edit operate type")
                            tipString = ""
                        }
                        UDToast.showFailure(
                            with: tipString,
                            on: window
                        )} else {
                        Self.logger.error("DLP State haven't Pass. Failed to unwrap 'self?.window' to push toast.")
                    }
                    let error = NSError(
                        domain: "dlpstate is dlpInProgress. Deny to save to album",
                        code: 0,
                        userInfo: ["dlpState": message.dlpState]
                    ) as Error
                    Self.logger.error("DLP State haven't Pass. Deny to save to album. Error: \(error)")
                    return .just(false)
                // 其他情况DLP不做处理
                @unknown default:
                    return .just(true)
                }
            }.catchErrorJustReturn(true) ?? .just(true)
    }

    private func saveImageToAlbum(imageAsset: LKDisplayAsset, image: UIImage?, saveImageCompletion: ((Bool) -> Void)?) {
        // 检查视频、图片存储是否有空间
        guard mediaDiskUtil.checkDownloadAssetsEnable(assets: [(imageAsset, image)], on: self.viewController?.view), let chatSecurityControlService else {
            saveImageCompletion?(false)
            return
        }
        CoreTracker.trackSavePic()
        chatSecurityControlService.downloadAsyncCheckAuthority(event: .saveImage, securityExtraInfo: imageAsset.securityExtraInfo(for: .saveImage)) { [weak self] authority in
            guard let self = self, let chatSecurityControlService = self.chatSecurityControlService else { return }
            guard authority.authorityAllowed else {
                if let interceptViewController = self.viewController {
                    chatSecurityControlService.authorityErrorHandler(event: .saveImage,
                                                                     authResult: authority,
                                                                     from: interceptViewController)
                }
                saveImageCompletion?(false)
                return
            }

            CoreTracker.trackDownloadImage()
            self.onSaveImage?(imageAsset)
            DispatchQueue.global().async {
                if self.qrCodeScanResult != nil {
                    CoreTracker.trackDownloadQrcode()
                }
            }

            if let scheme = URL(string: imageAsset.originalUrl)?.scheme,
                scheme.lowercased().starts(with: "http"),
                let image = image {
                guard !LarkCache.isCryptoEnable() else {
                    if let window = self.viewController?.view.window {
                        UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Core_SecuritySettingKAToast, on: window)
                    }
                    saveImageCompletion?(false)
                    return
                }

                try? Utils.savePhoto(token: AssetBrowserToken.savePhoto.token, image: image) { [weak self] (succeeded, granted) in
                    DispatchQueue.main.async { [weak self] in
                        guard granted else {
                            self?.delegate?.photoDenied()
                            self?.saveImageFinishCallBack?(imageAsset, false)
                            saveImageCompletion?(false)
                            return
                        }
                        self?.showSaveImageTip(succeeded)
                        self?.saveImageFinishCallBack?(imageAsset, succeeded)
                        saveImageCompletion?(succeeded)
                    }
                }
                return
            }

            try? Utils.checkPhotoWritePermission(token: AssetBrowserToken.checkPhotoWritePermission.token) { (granted) in
                guard granted else {
                    self.delegate?.photoDenied()
                    self.saveImageFinishCallBack?(imageAsset, false)
                    saveImageCompletion?(false)
                    return
                }

                if let extraInfo = imageAsset.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType {
                    switch extraInfo {
                    case .avatar(let avatarViewParams, let entityId):
                        self.fetchAndSaveAvatar(imageAsset: imageAsset, params: avatarViewParams, entityId: entityId, saveImageCompletion: saveImageCompletion)
                    default:
                        self.fetchAndSaveImage(imageAsset: imageAsset, saveImageCompletion: saveImageCompletion)
                    }
                } else {
                    self.fetchAndSaveImage(imageAsset: imageAsset, saveImageCompletion: saveImageCompletion)
                }
            }
        }
    }

    /// 保存头像需要走C接口
    private func fetchAndSaveAvatar(imageAsset: LKDisplayAsset, params: AvatarViewParams?, entityId: String? = nil, saveImageCompletion: ((Bool) -> Void)?) {
        let params = params ?? AvatarViewParams.defaultBig
        let format = params.format.displayName
        self.resourceAPI.fetchResourcePath(entityID: entityId ?? "", key: imageAsset.key, size: Int32(params.size()),
                                           dpr: Float(UIScreen.main.scale), format: format)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (path) in
                self?.saveImageToAlbum(imagePath: path, imageAsset: imageAsset, saveImageCompletion: saveImageCompletion)
            }, onError: { [weak self] (error) in
                self?.saveImageFinishCallBack?(imageAsset, false)
                saveImageCompletion?(false)
                if let window = self?.viewController?.view.window {
                    UDToast.showFailure(
                        with: BundleI18n.LarkCore.Lark_Legacy_PhotoZoomingSaveImageFail,
                        on: window,
                        error: error
                    )
                }
                Self.logger.error("save avatar to album failed due to fetchResourcePath error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    /// 保存普通图片，如chat里的图片
    private func fetchAndSaveImage(imageAsset: LKDisplayAsset, saveImageCompletion: ((Bool) -> Void)?) {
        var imageKey = imageAsset.key
        if let originKey = imageAsset.originalImageKey, !originKey.isEmpty {
            imageKey = originKey
        }
        let messageId = imageAsset.extraInfo[ImageAssetMessageIdKey] as? String
        // 检查DLP的状态后再下载图片，如果有saveImage的dlp信息，说明已经在前面检测过了，这里不再检测
        (imageAsset.securityExtraInfo(for: .saveImage) != nil ? .just(true) : self.checkImageOperateSecurity(.save, messageID: messageId))
            // 如果为fasle，则提前执行completion回调；如果为true，后续流程会负责执行completion
            .do(onNext: { result in if !result { saveImageCompletion?(false) } })
            .filter { $0 == true }
            .flatMap { [weak self] ( _ ) -> Observable<Bool> in
                self?.isOperationAllowed(messageID: imageAsset.extraInfo[ImageAssetMessageIdKey] as? String,
                                         fatherMFId: imageAsset.extraInfo[ImageAssetFatherMFIdKey] as? String,
                                         replyInthreadRootId: imageAsset.extraInfo[ImageAssetReplyThreadRootIdKey] as? String,
                                         operateType: .save) ?? .just(true)
            }
            // 如果为fasle，则提前执行completion回调；如果为true，后续流程会负责执行completion
            .do(onNext: { result in if !result { saveImageCompletion?(false) } })
            .filter { $0 == true }
            .flatMap { [weak self] ( _ ) -> Observable<Bool> in
                self?.canDownLoadByFileDetecting(asset: imageAsset) ?? .just(true)
            }
            // 如果为fasle，则提前执行completion回调；如果为true，后续流程会负责执行completion
            .do(onNext: { result in if !result { saveImageCompletion?(false) } })
            .filter { $0 == true }
            .flatMap { [weak self] _ -> Observable<ResourceItem> in
                guard let self = self else { return .empty() }
                return self.resourceAPI.fetchResource(key: imageKey,
                                                      path: nil,
                                                      authToken: nil,
                                                      downloadScene: .chat,
                                                      isReaction: false,
                                                      isEmojis: false,
                                                      avatarMap: nil)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (item) in
                self?.saveImageToAlbum(imagePath: item.path, imageAsset: imageAsset, saveImageCompletion: saveImageCompletion)
            }, onError: { [weak self] error in
                self?.saveImageFinishCallBack?(imageAsset, false)
                saveImageCompletion?(false)
                if let window = self?.viewController?.view.window {
                    UDToast.showFailure(
                        with: BundleI18n.LarkCore.Lark_Legacy_PhotoZoomingSaveImageFail,
                        on: window
                    )
                }
                Self.logger.error("save image to album failed due to fetchResource error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    private func saveImageToAlbum(imagePath: String, imageAsset: LKDisplayAsset?, saveImageCompletion: ((Bool) -> Void)?) {
        let url = URL(fileURLWithPath: imagePath)
        var tempUrl: URL?
        let urlData = try? Data.read_(from: url)
        if url.pathExtension.isEmpty, let data = urlData {
            switch data.lf.fileFormat() {
            case .image(let format):
                tempUrl = URL(fileURLWithPath: "\(imagePath).\(format)")
            default:
                break
            }
        }
        guard !LarkCache.isCryptoEnable() else {
            if let window = self.viewController?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Core_SecuritySettingKAToast, on: window)
            }
            saveImageFinishCallBack?(imageAsset, false)
            saveImageCompletion?(false)
            return
        }
        let isOriginal = (imageAsset?.originalImageSize ?? 0) != 0
        safePerformChanges {
            if let tempUrl = tempUrl {
                try? Path(url.path).copyFile(to: Path(tempUrl.path))
                self.customCreationRequestForAsset(atFileURL: tempUrl, isOriginal: isOriginal, data: urlData)
            } else {
                self.customCreationRequestForAsset(atFileURL: url, isOriginal: isOriginal, data: urlData)
            }
        } completionHandler: { [weak self] (succeeded, error) in
            DispatchQueue.main.async { [weak self] in
                self?.showSaveImageTip(succeeded)
                self?.saveImageFinishCallBack?(imageAsset, succeeded)
                saveImageCompletion?(succeeded)
            }
            if let tempUrl = tempUrl {
                try? Path(tempUrl.path).deleteFile()
            }
            if let error = error {
                Self.logger.error("save image to album failed: \(error)")
            }
        }
    }

    private func safePerformChanges(_ changeBlock: @escaping () -> Void,
                                    completionHandler: ((Bool, Error?) -> Void)?) {
        /// http://t.wtturl.cn/e5Rp5FU/
        /// iOS14.0后系统有相册权限，在系统进行[PLPrivacy _checkAuthStatusForPhotosAccessScope]检测权限的时候，
        /// 在主线程调用PHPhotoLibrary.shared()会导致卡死
        if #available(iOS 14.0, *), Thread.isMainThread {
            DispatchQueue.global().async {
                let phPhoto = PHPhotoLibrary.shared()
                DispatchQueue.main.async {
                    phPhoto.performChanges(changeBlock, completionHandler: completionHandler)
                }
            }
            return
        }
        PHPhotoLibrary.shared().performChanges(changeBlock, completionHandler: completionHandler)
    }

    private func customCreationRequestForAsset(atFileURL url: URL, isOriginal: Bool, data: Data?) {
        let exportConfig = LarkImageService.shared.imageExportConfig
        let config = isOriginal ? exportConfig.origin : exportConfig.noneOrigin
        if let data, config.convertSourceTypes.contains(data.bt.imageFileFormat.displayName),
           let image = try? ByteImage(data, decodeForDisplay: false, downsampleSize: data.bt.imageSize) {
            // 如果格式在配置的转格式列表里，则转换成 UIImage 再存相册（系统默认会转换为 JPEG）
            _ = try? AlbumEntry.creationRequestForAsset(forToken: AssetBrowserToken.creationRequestForAsset.token, fromImage: image)
        } else if #unavailable(iOS 14), config.convertWhenSystemUnavailable, let data, data.bt.imageFileFormat == .webp,
                  let image = try? ByteImage(data, decodeForDisplay: false, downsampleSize: data.bt.imageSize) {
            // 对于系统不支持的格式，也进行转码
            // 目前飞书支持的格式中系统不支持的格式，只有 iOS 13 及以下系统的 WebP 格式
            _ = try? AlbumEntry.creationRequestForAsset(forToken: Token(""), fromImage: image)
        } else if let data = data, data.isHeic {
            var urlFixExtension = url
            urlFixExtension.appendPathExtension("heic")
            try? Path(url.path).copyFile(to: Path(urlFixExtension.path))
            _ = try? AlbumEntry.creationRequestForAssetFromImage(forToken: AssetBrowserToken.creationRequestForAssetFromImage.token, atFileURL: urlFixExtension)
        } else {
            _ = try? AlbumEntry.creationRequestForAssetFromImage(forToken: AssetBrowserToken.creationRequestForAssetFromImage.token,
                                                                 atFileURL: url)
        }
    }

    private func showSaveImageTip(_ succeeded: Bool) {
        guard let presentVC = self.viewController else { return }
        if succeeded {
            UDToast.showSuccess(with: BundleI18n.LarkCore.Lark_Legacy_QrCodeSaveToAlbum,
                                on: presentVC.view, delay: 1)
        } else {
            UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_PhotoZoomingSaveImageFail,
                                on: presentVC.view, delay: 1)
        }
    }

    public override func handleCurrentShowedAsset(asset: LKDisplayAsset) {
        CoreTracker.trackPreviewImage()
    }

    public override func handleCurrentVideoShowedAsset(asset: LKDisplayAsset, videoDisplayView: LKVideoDisplayViewProtocol?) {
        self.currentVideoAsset = asset
        self.currentVideoPlayProxy = videoDisplayView
        if let mediaInfoItem = self.mediaInfoItem(from: asset) {
            let (isVideoDownloading, progress) = videoSaveService.isVideoDownloadingAndProgress(for: mediaInfoItem.messageId)
            if isVideoDownloading {
                self.currentVideoPlayProxy?.pause()
                self.currentVideoPlayProxy?.showProgressView()
                self.currentVideoPlayProxy?.configProgressView(progress)
            }
        }
    }

    public override func getSaveImageKeyCommand(asset: LKDisplayAsset, relatedImage: UIImage?) -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "s",
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkCore.Lark_Legacy_SaveVideoMenu
            ).binding(
                handler: { [weak self] in
                    self?.saveImageToAlbum(imageAsset: asset, image: relatedImage, saveImageCompletion: nil)
                }
            ).wraper
        ]
    }

    public override func getSaveVideoKeyCommand(videoDisplayView: LKVideoDisplayViewProtocol, asset: LKDisplayAsset) -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "s",
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkCore.Lark_Legacy_SaveVideoMenu
            ).binding(
                tryHandle: { [weak self] (_) -> Bool in
                    guard let self = self else { return false }
                    if self.canHandleSaveVideoToAlbum,
                       let mediaInfoItem = self.mediaInfoItem(from: asset) {
                        let (isVideoDownloading, _) = self.videoSaveService.isVideoDownloadingAndProgress(for: mediaInfoItem.messageId)
                        // 如果视频正在下载，就不响应保存快捷键
                        if !isVideoDownloading {
                            return true
                        }
                    }
                    return false
                },
                handler: { [weak self] in
                    let mediaInfoItem: MediaInfoItem? = self?.mediaInfoItem(from: asset)
                    self?.currentVideoPlayProxy = videoDisplayView
                    self?.currentVideoAsset = asset
                    self?.saveVideo(asset: asset, mediaInfoItem: mediaInfoItem)
                }
            ).wraper
        ]
    }

    func saveVideo(asset: LKDisplayAsset, mediaInfoItem: MediaInfoItem?) {
        CoreTracker.trackSavePic()
        guard !LarkCache.isCryptoEnable() else {
            if let window = self.viewController?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Core_SecuritySettingKAToast, on: window)
            }
            return
        }
        self.currentVideoPlayProxy?.pause()
        self.saveVideoToAlbum(asset: asset, item: mediaInfoItem)
    }

    // 以下是视频消息
    private func presentActionSheetForVideo(asset: LKDisplayAsset,
                                            videoDisplayView: LKVideoDisplayViewProtocol,
                                            browser: LKAssetBrowserViewController,
                                            sourceView: UIView?) {
        guard let currentPageView = browser.currentPageView else {
            return
        }
        let source: UIView
        let sourceRect: CGRect
        if let sourceView = sourceView {
            source = sourceView
            sourceRect = CGRect(origin: .zero, size: sourceView.bounds.size)
        } else {
            source = currentPageView
            sourceRect = CGRect(origin: currentPageView.longGesture.location(in: currentPageView), size: .zero)
        }

        let popSource = UDActionSheetSource(sourceView: source,
                                            sourceRect: sourceRect)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: popSource))

        self.currentVideoAsset = asset
        self.currentVideoPlayProxy = videoDisplayView
        self.browser = browser

        let mediaInfoItem: MediaInfoItem? = self.mediaInfoItem(from: asset)
        var hadItems = false
        if self.canHandleSaveVideoToAlbum {
            hadItems = true
            actionSheet.addDefaultItem(text: BundleI18n.LarkCore.Lark_Legacy_SaveVideoMenu) { [weak self] in
                self?.saveVideo(asset: asset, mediaInfoItem: mediaInfoItem)
            }
        }

        // 未发送成功的视频，没有对应url，因此不展示保存到云端
        if showSaveToCloud, !(mediaInfoItem?.url ?? "").isEmpty {
            hadItems = true
            actionSheet.addDefaultItem(text: BundleI18n.LarkCore.Lark_Legacy_SaveFileToDrive) { [weak self] in
                // 长按视频的“保存到云盘”由IM管控。本地文件预览的“保存到云盘”由CCM管控
                let authority = self?.chatSecurityControlService?.checkAuthority(event: .saveToDrive)
                guard authority?.authorityAllowed == true else {
                    self?.chatSecurityControlService?.authorityErrorHandler(event: .saveToDrive, authResult: authority, from: browser, errorMessage: nil, forceToAlert: false)
                    return
                }
                self?.currentVideoPlayProxy?.pause()
                self?.saveVideoToSpaceStore(item: mediaInfoItem)
            }
        }

        if let viewInChat = viewInChat {
            hadItems = true
            actionSheet.addDefaultItem(text: viewInChatTitle) { [weak self] in
                if self?.fromWhere ?? .other == .chatHistory {
                    CoreTracker.picBowserGoChatInChatHistory()
                }
                self?.delegate?.dismissViewController(completion: {
                    viewInChat(asset)
                })
            }
        }
        /// 这里没有功能Items 就不需要单独加一个cancel按钮
        if hadItems {
            actionSheet.setCancelItem(text: BundleI18n.LarkCore.Lark_Legacy_Cancel)
            userResolver.navigator.present(actionSheet, from: browser)
        }
    }

    public override func handleLongPressForVideo(asset: LKDisplayAsset,
                                               videoDisplayView: LKVideoDisplayViewProtocol,
                                               browser: LKAssetBrowserViewController,
                                               sourceView: UIView?) {
        PublicTracker.AssetsBrowser.Click.browserClick(action: .press)
        self.presentActionSheetForVideo(asset: asset,
                                        videoDisplayView: videoDisplayView,
                                        browser: browser,
                                        sourceView: sourceView)
    }

    public override func handleClickMoreButtonForVideo(asset: LKDisplayAsset,
                                                videoDisplayView: LKVideoDisplayViewProtocol,
                                            browser: LKAssetBrowserViewController,
                                            sourceView: UIView?) {
        PublicTracker.AssetsBrowser.Click.browserClick(action: .more)
        PublicTracker.AssetsBrowser.moreView()
        self.presentActionSheetForVideo(asset: asset,
                                        videoDisplayView: videoDisplayView,
                                        browser: browser,
                                        sourceView: sourceView)
    }

    func mediaInfoItem(from displayAsset: LKDisplayAsset) -> MediaInfoItem? {
        let type = (displayAsset.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType) ?? .other
        switch type {
        case .video(let mediaInfoItem):
            return mediaInfoItem
        default:
            return nil
        }
    }

    public override func handleLoadMoreOld(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {
        self.loadMoreOldAsset?(completion)
    }

    public override func handleLoadMoreNew(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {
        self.loadMoreNewAsset?(completion)
    }

    public override func handlePreviousShowedAsset(previousAsset: LKDisplayAsset, currentAsset: LKDisplayAsset) {
        CoreTracker.picBowserPrevious(fromWhere: fromWhere)
    }

    public override func handleNextShowedAsset(nextAsset: LKDisplayAsset, currentAsset: LKDisplayAsset) {
        onNextImage?(nextAsset)
        CoreTracker.picBowserNext(fromWhere: fromWhere)
    }

    // 保存视频
    private func saveVideoToAlbum(asset: LKDisplayAsset, item: MediaInfoItem?) {
        // 检查视频存储是否有足够磁盘
        guard mediaDiskUtil.checkDownloadVideoEnable(on: self.viewController?.view) else {
            return
        }
        guard let mediaContent = item else {
            if let window = self.viewController?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_SaveFail, on: window)
            }
            return
        }

        func inMainThread(perform: @escaping () -> Void) {
            if Thread.isMainThread {
                perform()
            } else {
                DispatchQueue.main.async {
                    perform()
                }
            }
        }

        // 视频没有上传成功
        if mediaContent.url.isEmpty {
            // 点击保存到相册，再存一份
            chatSecurityControlService?.downloadAsyncCheckAuthority(event: .saveVideo, securityExtraInfo: asset.securityExtraInfo(for: .saveVideo), completion: { [weak self] authority in
                guard let self else { return }
                if !authority.authorityAllowed {
                    self.chatSecurityControlService?.authorityErrorHandler(event: .saveVideo, authResult: authority, from: self.browser, errorMessage: nil)
                    return
                }
                try? Utils.checkPhotoWritePermission(token: AssetBrowserToken.checkPhotoWritePermission.token) { [weak self] granted in
                    guard let window = self?.viewController?.view.window else { return }
                    guard granted else {
                        // 没有相册权限，返回保存失败
                        UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_SaveFail, on: window)
                        return
                    }

                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: mediaContent.localPath))
                    } completionHandler: { isSaved, _ in
                        // 主线程展示UI
                        inMainThread(perform: {
                            if isSaved {
                                UDToast.showSuccess(with: BundleI18n.LarkCore.Lark_Legacy_SaveSuccess, on: window)
                            } else {
                                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_SaveFail, on: window)
                            }
                        })
                    }
                }
            })
        } else {
            // 检查DLP的状态后再允许用户保存视频到本地
            checkMediaOperateSecurity(.save, messageID: mediaContent.messageId)
                .filter { $0 == true }
                .flatMap { [weak self] ( _ ) -> Observable<Bool> in
                    self?.isOperationAllowed(messageID: mediaContent.messageId,
                                             fatherMFId: mediaContent.fatherMFId,
                                             replyInthreadRootId: mediaContent.replyThreadRootId,
                                             operateType: .save) ?? .just(true)
                }
                .filter { $0 == true }
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    // 添加进字典，当有进度回调时，会有toast展示
                    let wrappar = SaveVideoDisplayViewWrappar()
                    wrappar.videoDisplayView = self.currentVideoPlayProxy
                    self.videoDisplayViewDic[mediaContent.messageId] = wrappar
                    self.onSaveVideo?(mediaContent)
                    self.videoSaveService.saveVideoToAlbum(
                        with: mediaContent.messageId, asset: asset,
                        info: .init(key: mediaContent.key,
                                    authToken: mediaContent.authToken,
                                    absolutePath: "",
                                    type: .message,
                                    channelId: mediaContent.channelId,
                                    sourceType: mediaContent.sourceType,
                                    sourceID: mediaContent.sourceId),
                        riskDetectBlock: { [weak self] in self?.canDownLoadByFileDetecting(mediaContent: mediaContent) ?? .just(true) },
                        from: self.browser,
                        downloadFileScene: item?.downloadFileScene)
                }).disposed(by: self.disposeBag)
        }
    }

    private func addSaveProgressObserver() {
        videoSaveService.videoSavePush.drive(onNext: { [weak self] (push) in
            guard let window = self?.viewController?.view.window,
                  let wrappar = self?.videoDisplayViewDic[push.0]
            else { return }

            // wrapper的videoDisplayView是weak，此处调用时需要检查一下，如果被释放，那么removeValueForKey
            guard let displayView = wrappar.videoDisplayView else {
                self?.videoDisplayViewDic.removeValue(forKey: push.0)
                return
            }

            // 截止状态，需要removeValueForKey
            switch push.1 {
            case .downloadSuccess,
                 .downloadFailed,
                 .downloadSaveError,
                 .saveToNutFailed,
                 .saveToNutFailedWithMoreThanLimit,
                 .saveToNutSuccess,
                 .cryptoError:
                self?.videoDisplayViewDic.removeValue(forKey: push.0)
            default:
                break
            }

            switch push.1 {
            case .downloadStart:
                displayView.showProgressView()
            case .downloading(let progress):
                displayView.configProgressView(progress)
            case .downloadFailed:
                displayView.hideProgressView()
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_SaveFail, on: window)
            case .downloadSuccess:
                displayView.hideProgressView()
                UDToast.showSuccess(with: BundleI18n.LarkCore.Lark_Legacy_SaveSuccess, on: window)
            case .downloadSaveError:
                displayView.hideProgressView()
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_PhotoZoomingSaveVideoNoSupport, on: window)
            case .saveToNutInProgress:
                break
            case .saveToNutFailed:
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_SaveFail, on: window)
            case .saveToNutFailedWithMoreThanLimit:
                if let vc = self?.viewController, let isOversea = self?.isOversea {
                    if isOversea {
                        UDToast.showFailure(
                            with: BundleI18n.LarkCore.Lark_Legacy_SaveFail,
                            on: window
                        )
                    } else {
                        self?.dependency?.showQuataAlertFromVC(vc)
                    }
                }
            case .saveToNutSuccess:
                UDToast.showSuccess(with: BundleI18n.LarkCore.Lark_Legacy_SavedFileToDrive, on: window)
            case .cryptoError:
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Core_SecuritySettingKAToast, on: window)
            }
        }).disposed(by: disposeBag)
    }

    private func saveVideoToSpaceStore(item: MediaInfoItem?) {
        guard let item = item else {
            if let window = self.viewController?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_SaveFail, on: window)
            }
            return
        }

        isOperationAllowed(messageID: item.messageId,
                           fatherMFId: item.fatherMFId,
                           replyInthreadRootId: item.replyThreadRootId,
                           operateType: .save)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] isAllowed in
            guard let self = self else { return }
            if !isAllowed { return }
            let wrappar = SaveVideoDisplayViewWrappar()
            wrappar.videoDisplayView = self.currentVideoPlayProxy
            self.videoDisplayViewDic[item.messageId] = wrappar

            self.videoSaveService.saveFileToSpaceStore(messageId: item.messageId, chatId: item.channelId, key: item.key, sourceType: item.sourceType, sourceID: item.sourceId)
        }).disposed(by: self.disposeBag)
    }

    public override var canHandleSaveVideoToAlbum: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteVideoDownload)) && self.canSaveImage
    }

    // 多选图片/视频下载的错误处理，业务自定义
    public override func saveAssetsCustomErrorHandler(results: [Swift.Result<Void, Error>], from: NavigatorFrom?) -> Bool {
        // 文件权限
        var fileSecurity: (ValidateResult, SecurityControlEvent)?
        // DLP
        var dlpSecurity: (ValidateResult, SecurityControlEvent)?
        for item in results {
            guard case .failure(let error) = item,
                  case SaveAssetsError.imageSecurityError(let auth, let event) = error else { continue }
            switch auth.extra.resultSource {
            case .dlpDetecting, .dlpSensitive:
                dlpSecurity = (auth, event)
            case .fileStrategy, .securityAudit, .unknown:
                fileSecurity = (auth, event)
            case .ttBlock:
                continue
            }
            if dlpSecurity != nil, fileSecurity != nil {
                break
            }
        }
        let succeededCount = results.filter { if case .success = $0 { return true } else { return false } }.count
        let errorMessage = BundleI18n.LarkCore.Lark_Legacy_NumberDownloadSuccessNumberFail(succeededCount, results.count - succeededCount)
        // 文件策略的优先级高于DLP
        var authResult: (ValidateResult, SecurityControlEvent)? = fileSecurity ?? dlpSecurity
        if let authResult = authResult {
            // 文件策略一般弹框，DLP一般弹toast
            // 有限展示文件权限的拦截
            self.chatSecurityControlService?.authorityErrorHandler(
                event: authResult.1,
                authResult: authResult.0,
                from: from,
                errorMessage: errorMessage,
                forceToAlert: true)
            return true
        } else {
            return false
        }
    }

    public override func handleSaveAssets(_ assets: [(LKDisplayAsset, UIImage?)], granted: Bool, saveImageCompletion: ((Bool) -> Void)?)
    -> Observable<[Swift.Result<Void, Error>]> {
        if !self.canSaveImage {
            Self.logger.info("handleSaveAssets canSaveImage is false")
            return .just([Swift.Result.failure(SaveAssetsError.mediaInfoError)])
        }
        PublicTracker.AssetsBrowser.Click.chatAlbumClick(action: .download)

        guard granted else {
            self.delegate?.photoDenied()
            return .just([])
        }

        let hasVideo = assets.contains { $0.0.isVideo == true }
        let hasImage = assets.contains { $0.0.isVideo != true }

        if (hasImage || hasVideo), !checkCache() {
            return .just([])
        }

        // 检查视频/图片存储是否有足够磁盘
        let result = mediaDiskUtil.checkDownloadAssetsEnableInOB(assets: assets)
        guard result.0 else {
            return .just([]).do(onDispose: { [weak self] in
                DispatchQueue.main.async {
                    result.1?(self?.viewController?.navigationController?.view)
                }
            })
        }

        /// 多选下载前, 判断是否消息被设为保密
        let messageIds: [String] = assets.compactMap { asset -> String? in
            if asset.0.isVideo, let mediaInfoItem = self.mediaInfoItem(from: asset.0) {
                return mediaInfoItem.messageId
            } else {
                return asset.0.extraInfo[ImageAssetMessageIdKey] as? String
            }
        }
        return (self.messageAPI?.fetchMessages(ids: messageIds) ?? .just([]))
            .flatMap { [weak self] messages -> Observable<[Swift.Result<Void, Error>]> in
                for message in messages {
                    if let disableBehavior = message.disabledAction.actions[Int32(MessageDisabledAction.Action.download.rawValue)] {
                        return .just([]).do(onDispose: { [weak self] in
                            self?.serverMutiSelectDownloadError(errorCode: disableBehavior.code, selectCount: messages.count)
                        })
                    }
                }
                guard let self = self else { return .just([])}
                /// 多选下载前, 判断是否包含风险文件后再下载

                return self.fileAPI?.canDownloadFiles(
                    detectRiskFileMetas: assets
                        .map({ (asset, _) in
                            var key = asset.originalImageKey ?? ""
                            if asset.isVideo {
                                key = self.mediaInfoItem(from: asset)?.key ?? ""
                            }
                            return DetectRiskFileMeta(key: key, messageRiskObjectKeys: asset.riskObjectKeys)
                        })
                )
                .flatMap({ [weak self] canDownloadMap -> Observable<[Swift.Result<Void, Error>]> in
                    guard let self = self else { return .just([]) }
                    var obs: [Observable<Swift.Result<Void, Error>>] = []
                    var canDownloadAssets: [LKDisplayAsset] = []
                    var firstRiskAssetKey: String?
                    for (k, v) in canDownloadMap {
                        if !v, firstRiskAssetKey == nil, !k.isEmpty {
                            firstRiskAssetKey = k
                        }
                        if v, let asset = assets.first(where: { (asset, _) in
                            if asset.isVideo, let media = self.mediaInfoItem(from: asset) {
                                return media.key == k
                            }
                            return asset.originalImageKey == k
                        }) {
                            canDownloadAssets.append(asset.0)
                        }
                    }
                    /// 找到第一个报错
                    if let firstRiskAssetKey = firstRiskAssetKey,
                        let vc = self.viewController,
                        let asset = assets.first(where: { (asset, _) in
                            if asset.isVideo, let media = self.mediaInfoItem(from: asset) {
                                return media.key == firstRiskAssetKey
                            }
                            return asset.originalImageKey == firstRiskAssetKey
                        })?.0 {
                        self.appealMutiSelectRiskFile(asset: asset, vc: vc)
                    }
                    /// 其他下载
                    if canDownloadAssets.isEmpty {
                        return .just([])
                    }
                    canDownloadAssets.forEach {
                        $0.isVideo ? obs.append(self.patchSaveVideo(asset: $0, mediaContent: self.mediaInfoItem(from: $0)))
                        : obs.append(self.patchSaveImage(asset: $0, saveImageCompletion: saveImageCompletion))
                    }
                    return Observable.zip(obs)
                }) ?? .just([])
            }.observeOn(MainScheduler.instance)
    }

    private func serverMutiSelectDownloadError(errorCode: Int32, selectCount: Int) {
        let errorMessage: String
        switch errorCode {
        case 311_150:
            if selectCount == 1 {
                errorMessage = BundleI18n.LarkCore.Lark_IM_MessageRestrictedCantSave_Hover
            } else {
                errorMessage = BundleI18n.LarkCore.Lark_IM_MultiSelectRestrictedMsgRetry_Toast
            }
        default:
            errorMessage = BundleI18n.LarkCore.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
        }

        DispatchQueue.main.async {
            if let vc = self.viewController,
               let window = WindowTopMostFrom(vc: vc).fromViewController?.view {
                UDToast.showFailure(with: errorMessage, on: window)
            }
        }
    }

    private func appealMutiSelectRiskFile(asset: LKDisplayAsset, vc: UIViewController) {
        let body: RiskFileAppealBody
        if asset.isVideo {
            guard let mediaInfoItem = self.mediaInfoItem(from: asset) else { return }
            body = RiskFileAppealBody(fileKey: mediaInfoItem.key, locale: LanguageManager.currentLanguage.rawValue)
        } else {
            guard let originalImageKey = asset.originalImageKey else { return }
            /// 历史原因,服务端无法识别key前缀,需要替换
            let imageQualityPrefixs = ["origin:", "middle:", "thumbnail:"]
            var fixedKey = originalImageKey
            for prefix in imageQualityPrefixs {
                fixedKey = fixedKey.replacingOccurrences(of: prefix, with: "", options: .regularExpression)
            }
            body = RiskFileAppealBody(fileKey: fixedKey, locale: LanguageManager.currentLanguage.rawValue)
        }

        DispatchQueue.main.async {
            self.userResolver.navigator.present(body: body, from: WindowTopMostFrom(vc: vc))
        }
    }

    private func checkCache() -> Bool {
        guard !LarkCache.isCryptoEnable() else {
            if let window = self.viewController?.view.window ?? self.viewController?.navigationController?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Core_SecuritySettingKAToast, on: window)
            }
            return false
        }

        return true
    }

    private func patchSaveVideo(asset: LKDisplayAsset, mediaContent: MediaInfoItem?) -> Observable<Swift.Result<Void, Error>> {
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let `self` = self, let mediaContent = mediaContent else {
                if let window = self?.viewController?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_SaveFail, on: window)
                }
                observer.onNext(Swift.Result.failure(SaveAssetsError.mediaInfoError))
                observer.onCompleted()
                return Disposables.create()
            }
            // 视频下载前判断是否有权限管控，不允许下载
            self.chatSecurityControlService?.downloadAsyncCheckAuthority(
                event: .saveVideo, securityExtraInfo: asset.securityExtraInfo(for: .saveVideo), ignoreSecurityOperate: true) { [weak self] authority in
                guard let `self` = self else {
                    observer.onNext(Swift.Result.failure(SaveAssetsError.mediaInfoError))
                    observer.onCompleted()
                    return
                }
                guard authority.authorityAllowed else {
                    observer.onNext(Swift.Result.failure(SaveAssetsError.imageSecurityError(authority, SecurityControlEvent.saveVideo)))
                    observer.onCompleted()
                    return
                }
                let wrappar = SaveVideoDisplayViewWrappar()
                wrappar.videoDisplayView = self.currentVideoPlayProxy
                self.videoDisplayViewDic[mediaContent.messageId] = wrappar
                self.onSaveVideo?(mediaContent)

                self.videoSaveService.saveVideoToAlbumOb(
                    with: mediaContent.messageId,
                    key: mediaContent.key,
                    authToken: mediaContent.authToken,
                    absolutePath: "",
                    type: .message,
                    channelId: mediaContent.channelId,
                    sourceType: mediaContent.sourceType,
                    sourceID: mediaContent.sourceId,
                    from: self.browser,
                    downloadFileScene: mediaContent.downloadFileScene).subscribe(onNext: {_ in
                        observer.onNext(Swift.Result.success(()))
                        observer.onCompleted()
                    }, onError: { error in
                        observer.onNext(Swift.Result.failure(error))
                        observer.onCompleted()
                    }).disposed(by: self.disposeBag)
            }
            return Disposables.create()
        }
    }

    private func patchSaveImage(asset: LKDisplayAsset, saveImageCompletion: ((Bool) -> Void)?) -> Observable<Swift.Result<Void, Error>> {
        self.onSaveImage?(asset)

        return Observable.create { [weak self] (observer) -> Disposable in
            guard let `self` = self else {
                saveImageCompletion?(false)
                observer.onNext(Swift.Result.failure(SaveAssetsError.mediaInfoError))
                observer.onCompleted()
                return Disposables.create()
            }
            // 图片下载前判断是否有权限管控，不允许下载
            self.chatSecurityControlService?.downloadAsyncCheckAuthority(
                event: .saveImage, securityExtraInfo: asset.securityExtraInfo(for: .saveImage), ignoreSecurityOperate: true) { [weak self] authority in
                guard let `self` = self else {
                    saveImageCompletion?(false)
                    observer.onNext(Swift.Result.failure(SaveAssetsError.mediaInfoError))
                    observer.onCompleted()
                    return
                }
                // 检测不通过不进入后续下载流程
                guard authority.authorityAllowed else {
                    saveImageCompletion?(false)
                    observer.onNext(Swift.Result.failure(SaveAssetsError.imageSecurityError(authority, SecurityControlEvent.saveImage)))
                    observer.onCompleted()
                    return
                }
                // DLP检测通过，开始下载图片
                self.resourceAPI.fetchResource(key: asset.key,
                                               path: nil,
                                               authToken: nil,
                                               downloadScene: .chat,
                                               isReaction: false,
                                               isEmojis: false,
                                               avatarMap: nil)
                .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] item in
                    self?.saveImageToAlbum(imagePath: item.path, imageAsset: asset, saveImageCompletion: saveImageCompletion)
                    observer.onNext(Swift.Result.success(()))
                    observer.onCompleted()
                }, onError: { [weak self] error in
                    self?.saveImageFinishCallBack?(asset, false)
                    Self.logger.error("patch download image failed", error: error)
                    observer.onNext(Swift.Result.failure(SaveAssetsError.mediaInfoError))
                    observer.onCompleted()
                }).disposed(by: self.disposeBag)
            }
            return Disposables.create()
        }
    }
}

extension AssetBrowserActionHandler: ImageEditViewControllerDelegate {
    public func closeButtonDidClicked(vc: EditViewController) {
        vc.exit()
    }

    public func finishButtonDidClicked(vc: EditViewController, editImage: UIImage) { // 相册编辑-完成
        let adapter = ActionSheetAdapter()
        let actionSheet = adapter.create(level: .normalWithCustomActionSheet)
        var shouldPresentSheet: Bool = false

        let topmostFrom = WindowTopMostFrom(vc: vc)

        // 分享图片
        if self.shareImage != nil {
            shouldPresentSheet = true
            adapter.addItem(title: BundleI18n.LarkCore.Lark_Legacy_Forward) { [weak self] in
                guard let self else { return }
                // 取消分享需要重新进入编辑界面，PM要求此逻辑和微信保持一致
                // 注：不需要重新打开编辑页面，present 出分享页面后，编辑页面没有关闭
                let cancelCallBack: (() -> Void) = {}
                // 分享成功后内部调dismiss，vc所在navigationVC会一起dismiss掉；符合预期，PM要求分享成功后需要同时消失分享&编辑界面
                let resource = Navigator.shared
                    .response(for: ShareImageBody(image: editImage,
                                                  type: .forward,
                                                  needFilterExternal: false,
                                                  cancelCallBack: cancelCallBack) { [weak self] in
                        guard let self = self,
                              let presentVC = self.viewController else { return }

                        UDToast.showTips(with: BundleI18n.LarkCore.Lark_Legacy_Success,
                                         on: presentVC.view)
                    }).resource
                // ShareImageHandler内部会包装一层navigationVC，我们只取rootVC，不然无法做到同时消失分享&编辑界面
                guard let shareVC = (resource as? UINavigationController)?.viewControllers[0] else { return }
                self.userResolver.navigator.push(shareVC, from: vc, animated: true, completion: nil)
            }
        }
        // 保存到相册
        if self.canSaveImage {
            shouldPresentSheet = true
            adapter.addItem(title: BundleI18n.LarkCore.Lark_Legacy_ImageSave) { [weak self] in
                guard let self else { return }
                if let currentAsset = self.browser?.currentPageView?.displayAsset {
                    // 向外通知 saveImage 事件，在调用业务的埋点方法
                    self.onSaveImage?(currentAsset)
                }

                // 保存资源时，调用安全的异步接口，网络请求。用户是否有保存的权限
                self.chatSecurityControlService?.downloadAsyncCheckAuthority(
                    event: .saveImage,
                    securityExtraInfo: self.browser?.currentPageView?.displayAsset?.securityExtraInfo(for: .saveImage)) { [weak self] authority in
                    guard let self = self else { return }
                    guard authority.authorityAllowed else {
                        self.chatSecurityControlService?.authorityErrorHandler(event: .saveImage,
                                                                              authResult: authority,
                                                                              from: vc)
                        self.saveImageFinishCallBack?(self.browser?.currentPageView?.displayAsset, false)
                        Self.logger.error("[AssetBrowser.ActionHandler][\(#function)] save image failed: authority not allowed.")
                        return
                    }

                    guard !LarkCache.isCryptoEnable() else {
                        if let window = vc.view.window {
                            UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Core_SecuritySettingKAToast, on: window)
                        }
                        Self.logger.error("[AssetBrowser.ActionHandler][\(#function)] save image failed: crypto not enabled")
                        return
                    }
                    try? Utils.savePhoto(token: AssetBrowserToken.savePhoto.token, image: editImage) { (succeeded, granted) in
                        DispatchQueue.main.async { [weak self] in
                            // 被限制
                            guard granted else {
                                self?.delegate?.photoDenied()
                                self?.saveImageFinishCallBack?(self?.browser?.currentPageView?.displayAsset, false)
                                Self.logger.error("[AssetBrowser.ActionHandler][\(#function)] save image failed: permission not granted")
                                return
                            }
                            self?.showSaveImageTip(succeeded)
                            self?.saveImageFinishCallBack?(self?.browser?.currentPageView?.displayAsset, succeeded)
                            // 保存成功，退出界面
                            vc.exit()
                        }
                    }
                }
            }
        }
        guard shouldPresentSheet else { return }
        adapter.addCancelItem(title: BundleI18n.LarkCore.Lark_Legacy_Cancel)
        userResolver.navigator.present(actionSheet, from: vc)
    }
}

extension Data {
    public var isHeic: Bool {
        guard count >= 12, [UInt8](subdata(in: startIndex..<index(startIndex, offsetBy: 1))).first == 0 else {
            return false
        }
        let start = index(startIndex, offsetBy: 4)
        let end = index(startIndex, offsetBy: 12)
        let testData = subdata(in: start..<end)
        guard let testString = String(data: testData, encoding: .ascii) else {
            return false
        }

        if testString == "ftypheic" || testString == "ftypheix"
            || testString == "ftyphevc" || testString == "ftyphevx"
            || testString == "ftypmif1" || testString == "ftypmsf1" {
            return true
        }
        return false
    }
}

extension AssetBrowserActionHandler: ImageOCRDelegate {
    public func ocrResultCopy(result: String, from: UIViewController, dismissCallback: @escaping (Bool) -> Void) {
        Self.logger.info("ocr copy result length \(result.count)")
        do {
            let config = PasteboardConfig(token: Token("LARK-PSDA-messenger_image_browser_ocr_result_copy"))
            try SCPasteboard.generalUnsafe(config).string = result
            if let window = from.rootWindow() {
                UDToast.showSuccess(with: BundleI18n.LarkCore.Lark_IM_ImageToText_Copied_Toast, on: window)
            }
        } catch {
            // 业务兜底逻辑
            if let window = from.rootWindow() {
                UDToast.showFailure(with: BundleI18n.LarkCore.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
            }
        }
        dismissCallback(false)
    }
    public func ocrResultForward(result: String, from: UIViewController, dismissCallback: @escaping (Bool) -> Void) {
        Self.logger.info("ocr forward result length \(result.count)")
        let forwardTextBody = ForwardTextBody(text: result, sentHandler: { _, _ in
            dismissCallback(false)
        })
        userResolver.navigator.present(
            body: forwardTextBody,
            from: from,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    public func ocrResultTapNumber(number: String, from: UIViewController, dismissCallback: @escaping (Bool) -> Void) {
        Self.logger.info("ocr tap result click phone number")
        userResolver.navigator.open(body: OpenTelBody(number: number), from: from)
    }

    public func ocrResultTapLink(link: String, from: UIViewController, dismissCallback: @escaping (Bool) -> Void) {
        Self.logger.info("ocr tap result click url")
        if let url = URL(string: link) {
            userResolver.navigator.push(url, from: from)
        } else {
            Self.logger.error("ocr tap url is invalied")
        }
    }

    public func ocrRecognizeResult(imageKey: String, str: NSAttributedString) {
        self.chatSecurityAuditService?.auditEvent(.ocrResult(length: str.string.count, imageKey: imageKey), isSecretChat: false)
    }
}
