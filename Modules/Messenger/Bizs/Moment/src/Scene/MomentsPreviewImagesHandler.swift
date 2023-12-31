//
//  MomentsPreviewImagesHandler.swift
//  Moment
//
//  Created by bytedance on 3/11/22.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import Swinject
import LarkMessengerInterface
import RxSwift
import LarkModel
import EENavigator
import ByteWebImage
import UniverseDesignToast
import LarkAccountInterface
import LarkAssetsBrowser
import RustPB
import LarkSDKInterface
import LarkExtensions
import AppReciableSDK
import LarkFeatureGating
import LarkRustClient
import LarkRichTextCore
import LarkCore
import LarkQRCode
import LarkNavigator

open class MomentsPreviewImagesHandler: UserTypedRouterHandler {

    public static func compatibleMode() -> Bool { Moment.userScopeCompatibleMode }

    private lazy var qrCodeAnalysis: QRCodeAnalysisService? = {
        return try? userResolver.resolve(assert: QRCodeAnalysisService.self)
    }()

    @ScopedInjectedLazy private var securityAuditService: MomentsSecurityAuditService?

    public func handle(_ body: MomentsPreviewImagesBody, req: EENavigator.Request, res: Response) throws {
        guard let vc = req.from.fromViewController else {
            assertionFailure()
            return
        }

        let from = WindowTopMostFrom(vc: vc)
        let assets = body.assets.map { $0.transform() }
        weak var browserVC: UIViewController?
        let actionHandler = try AssetBrowserActionHandlerFactory
            .handler(with: userResolver,
                     shouldDetectFile: body.shouldDetectFile,
                     canSaveImage: body.canSaveImage,
                     canEditImage: body.canEditImage,
                     canImageOCR: true,
                     scanQR: { [weak self] code in
                        guard let self else { return }
                        if self.userResolver.fg.dynamicFeatureGatingValue(with: "im.scan_code.multi_code_identification"),
                           let browserVC { // 新版扫码不退出大图查看器,直接跳转
                            self.scanQR(code, from: browserVC)
                        } else {
                            if let fromVC = from.fromViewController {
                                self.scanQR(code, from: fromVC)
                            }
                        }
                     },
                     saveImageFinishCallBack: { [weak self] imageAsset, succeed in
                guard let self = self,
                      let imageAsset = imageAsset,
                      let postId = body.postId else { return }
                self.securityAuditService?.auditEvent(.momentsSaveImage(originKey: imageAsset.key,
                                                                       postId: postId),
                                                     status: succeed ? .success : .fail)
            })

        func auditPreview(index: Int) {
            if let postId = body.postId,
               index >= 0 && index < body.assets.count {
                let asset = body.assets[index]
                //当前图片查看器所暴露的借口中，预览图片/视频 事件无法区分status是success还是fail
                if asset.isVideo {
                    if let videoUrl = asset.extraInfo["videoUrl"] as? String {
                        self.securityAuditService?.auditEvent(.momentsPreviewVideo(driveUrl: videoUrl,
                                                                                  postId: postId),
                                                             status: nil)
                    }
                } else {
                    self.securityAuditService?.auditEvent(.momentsPreviewImage(originKey: asset.originKey ?? "",
                                                                              postId: postId),
                                                         status: nil)
                }
            }
        }

        let controller = MomentsAssetBrowserViewController(
            assets: assets,
            pageIndex: body.pageIndex,
            actionHandler: actionHandler,
            buttonType: body.buttonType)
        controller.checkImageOCR = true
        controller.checkImageTranlation = true
        browserVC = controller

        let session: String? = try? userResolver.resolve(assert: PassportUserService.self).user.sessionKey
        controller.videoPlayProxyFactory = { [userResolver] in
            try userResolver.resolve(assert: LKVideoDisplayViewProxy.self, arguments: session, false)
        }
        var trackInfo: PreviewImageTrackInfo = PreviewImageTrackInfo(scene: .Moments)
        configureAssetInfo(controller, trackInfo: trackInfo)
        controller.isSavePhotoButtonHidden = body.hideSavePhotoBut
        controller.showImageOnly = false

        let navigation = AssetsNavigationController(rootViewController: controller)
        navigation.transitioningDelegate = controller
        navigation.modalPresentationStyle = .custom
        navigation.modalPresentationCapturesStatusBarAppearance = true

        PublicTracker.AssetsBrowser.show()
        //一进来先上报预览当前页的图片/视频
        auditPreview(index: body.pageIndex)
        controller.currentPageIndexWillChangeCallBack = { index in
            //翻页时上报预览图片
            auditPreview(index: index)
        }
        res.end(resource: navigation)
    }

    private func configureAssetInfo(_ controller: MomentsAssetBrowserViewController, trackInfo: PreviewImageTrackInfo) {
        controller.prepareAssetInfo = { (displayAsset) in
            let sourceType = (displayAsset.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType) ?? .other
            var passThrough: ImagePassThrough?
            if !displayAsset.fsUnit.isEmpty {
                passThrough = ImagePassThrough()
                passThrough?.key = displayAsset.key
                passThrough?.fsUnit = displayAsset.fsUnit
            }
            switch sourceType {
            case .image(let imageSet):
                if let dataProvider = ImageDisplayStrategy.largeImage(imageItem: ImageItemSet.transform(imageSet: imageSet),
                                                                      scene: .lookLargeImage, forceOrigin: displayAsset.forceLoadOrigin) {
                    return (dataProvider, passThrough, TrackInfo(
                        scene: trackInfo.scene, isOrigin: dataProvider.getImageKeyResource().cacheKey == imageSet.origin.key,
                        fromType: .image, metric: ["message_id": trackInfo.messageID]))
                }
                let key = imageSet.origin.key
                if displayAsset.forceLoadOrigin ||
                    LarkImageService.shared.isCached(resource: .default(key: key), options: .all) {
                    return (LarkImageResource.default(key: key), passThrough, TrackInfo(scene: trackInfo.scene,
                                                                                        isOrigin: true, fromType: .image,
                                                                                        metric: ["message_id": trackInfo.messageID]))
                }
                return (LarkImageResource.default(key: imageSet.middle.key),
                        passThrough,
                        TrackInfo(scene: trackInfo.scene, isOrigin: false, fromType: .image,
                                  metric: ["message_id": trackInfo.messageID]))
            /// Image情况存在下面几种情况：
            /// 1. 本地有原图优先使用
            /// 2. 本地没原图，forceLoadOrigin(老的线上图、新图中通过原图加载) 为true，则加载origin
            /// 3. 本地没原图，用middle，服务端决定middle是否跟origin一样
            case .other:
                let resource = LarkImageResource.default(key: displayAsset.originalUrl)
                return (resource, passThrough, TrackInfo(scene: trackInfo.scene, isOrigin: true, fromType: .unknown,
                                                         metric: ["message_id": trackInfo.messageID]))
            case .video(let mediaItem):
                let key = ImageItemSet.transform(imageSet: mediaItem.videoCoverImage).generateVideoMessageKey(forceOrigin: true)
                let resource = LarkImageResource.default(key: key)
                return (resource, passThrough, TrackInfo(scene: trackInfo.scene, isOrigin: true, fromType: .media,
                                                         metric: ["message_id": trackInfo.messageID]))
            default:
                assertionFailure("Moments only support sourceType .image or .video")
                let resource = LarkImageResource.default(key: displayAsset.originalUrl)
                return (resource, passThrough, TrackInfo(scene: trackInfo.scene, isOrigin: true, fromType: .unknown,
                                                         metric: ["message_id": trackInfo.messageID]))
            }
        }
    }

    func scanQR(_ code: String, from: UIViewController) {
        let status: QRCodeAnalysisCallBack = { [weak from] status, callback in
            switch status {
            case .preFinish:
                break
            case .fail(errorInfo: let errorInfo):
                guard let window = from?.view.window else { return }
                if let errorInfo = errorInfo {
                    UDToast.showFailure(with: errorInfo, on: window)
                } else {
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Legacy_QrCodeQrCodeError, on: window)
                }
            }
            callback?()
        }
        qrCodeAnalysis?.handle(code: code, status: status, from: .pressImage, fromVC: from)
    }

}
