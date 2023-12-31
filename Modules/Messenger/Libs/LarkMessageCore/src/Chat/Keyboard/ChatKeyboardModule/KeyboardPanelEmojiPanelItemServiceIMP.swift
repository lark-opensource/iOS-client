//
//  KeyboardPanelEmojiPanelItemServiceIMP.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/3/23.
//

import UIKit
import RustPB
import RxSwift
import RxCocoa
import LarkBaseKeyboard
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer
import EENavigator
import LarkUIKit
import UniverseDesignToast
import LarkAssetsBrowser
import Photos
import ByteWebImage
import LarkAlertController
import LarkImageEditor
import LarkCore
import LKCommonsTracker
import LKCommonsLogging
import LarkEmotion
import AppReciableSDK

public class KeyboardPanelEmojiPanelItemServiceIMP: KeyboardPanelEmojiPanelItemService, UserResolverWrapper {
    public let userResolver: UserResolver

    static let logger = Logger.log(KeyboardPanelEmojiPanelItemServiceIMP.self, category: "Module.Inputs")

    private var trackId = ""
    private var trackSence: Scene = Scene.Unknown

    @ScopedInjectedLazy private var stickerService: StickerService?
    @ScopedInjectedLazy private var reactionAPI: ReactionAPI?

    let disposeBag = DisposeBag()

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public func allStickerSetItems() -> [RustPB.Im_V1_StickerSet] {
        return stickerService?.stickerSets ?? []
    }

    public func stickerSetReloadDriver() -> Driver<Void> {
        return stickerService?.stickerSetsObserver.asDriver().map { _ in Void() } ?? .empty()
    }

    public func allStickerItems() -> [RustPB.Im_V1_Sticker] {
        return stickerService?.stickers ?? []
    }

    public func stickerReloadDriver() -> Driver<Void> {
        return stickerService?.stickersObserver.asDriver().map { _ in Void() } ?? .empty()
    }

    public func clickStickerSetting(from: UIViewController) {
        self.navigator.present(
            body: EmotionSettingBody(showType: .present),
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
    }

    public func clickNewStickersButton(from: UIViewController) {
        self.showImagePicker(
            showOriginButton: false,
            from: from,
            selectedBlock: { [weak self, weak from] (picker, assets: [PHAsset], _) in
                guard let `self` = self else { return }
                picker.dismiss(animated: true) { [weak from] in
                    self.pickedStickerImages(assets: assets, from: from)
                }
            })
    }

    func showImagePicker(
        showOriginButton: Bool,
        from: UIViewController,
        selectedBlock: ((ImagePickerViewController, _ assets: [PHAsset], _ isOriginalImage: Bool) -> Void)?
    ) {

        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 9),
                                               isOriginButtonHidden: !showOriginButton,
                                               sendButtonTitle: BundleI18n.LarkMessageCore.Lark_Legacy_LarkConfirm)
        picker.showMultiSelectAssetGridViewController()
        picker.imagePikcerCancelSelect = { (picker, _) in
            picker.dismiss(animated: true, completion: nil)
        }
        picker.imagePickerFinishSelect = { (picker, result) in
            selectedBlock?(picker, result.selectedAssets, result.isOriginal)
        }
        picker.imageEditAction = { Tracker.post(TeaEvent($0.event, params: $0.params ?? [:])) }
        picker.modalPresentationStyle = .fullScreen
        self.navigator.present(picker, from: from)
    }

    func pickedStickerImages(assets: [PHAsset], from: UIViewController?) {
        guard !assets.isEmpty, let vc = from else {
            return
        }
        let hud = UDToast.showLoading(on: vc.view, disableUserInteraction: true)
        let logId = self.trackId
        let scene = self.trackSence
        DispatchQueue.global().async {
            let sendImageRequest = SendImageRequest(
                input: .assets(assets),
                sendImageConfig: SendImageConfig(
                    isSkipError: false,
                    checkConfig: SendImageCheckConfig(
                        imageSize: CGSize(width: 2000, height: 2000),
                        fileSize: 5 * 1024 * 1024, isOrigin: false,
                        scene: scene, fromType: .sticker)),
                uploader: StickerSendImageUploader(fromVC: vc, stickerService: self.stickerService, nav: self.navigator))
            SendImageManager.shared
                .sendImage(request: sendImageRequest)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    Self.logger.info("pickedStickerImages success \(logId)")
                    hud.remove()
                }, onError: { [weak self] error in
                    hud.remove()
                    // custom会报出三种错误
                    // 一个是上传错误，这个在stickerService.uploadStickers接口内部已经处理过了
                    // 一个是检查失败（主要是检查sticker个数是否超限），这个已经在uploader里处理过了
                    // 一个是getCompressResult（拿不到压缩后的结果），但设置了isSkipError是false，所以如果有压缩错误已经在compress阶段抛出错误了
                    // 所以这里跳过custom阶段的所有错误
                    if let imageError = error as? LarkSendImageError,
                        imageError.type == .custom {
                        return
                    }
                    Self.logger.error("pickedStickerImages \(logId) error: \(error)")
                    if let imageError = error as? LarkSendImageError,
                        let compressError = imageError.error as? CompressError,
                        let err = AttachmentImageError.getCompressError(error: compressError) {
                        let alertController = LarkAlertController()
                        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Legacy_Hint)
                        alertController.setContent(text: err)
                        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_LarkConfirm)
                        self?.navigator.present(alertController, from: vc)
                    } else {
                        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip, on: vc.view)
                    }
                }, onCompleted: {
                    hud.remove()
                    Self.logger.info("pickedStickerImages completed \(logId)")
                }).disposed(by: self.disposeBag)
        }
    }

    public func pushEmotionShopListVC(from: UIViewController) {
        let body = EmotionShopListBody()
        self.navigator.present(body: body,
                               wrap: LkNavigationController.self,
                               from: from,
                               prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })

    }

    public func updateRecentlyUsedReaction(emojiKey: String) {
        if let reactionKey = EmotionResouce.shared.reactionKeyBy(emotionKey: emojiKey) {
            self.reactionAPI?.updateRecentlyUsedReaction(reactionType: reactionKey).subscribe().disposed(by: disposeBag)
        }
    }

    public func setTrackInfo(id: String, sence: Scene) {
        self.trackId = id
        self.trackSence = sence
    }
}
