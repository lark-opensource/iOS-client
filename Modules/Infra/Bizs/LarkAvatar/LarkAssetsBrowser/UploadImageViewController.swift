//
//  UploadImageViewController.swift
//  LarkAvatar
//
//  Created by 姚启灏 on 2020/3/5.
//

import Foundation
import UIKit
//import LarkSDKInterface
import LarkActionSheet
import LarkAlertController
import LarkUIKit
import RxSwift
import LarkFoundation
import LKCommonsLogging
import RoundedHUD
import EENavigator
import LarkImageEditor
import LarkAssetsBrowser
import LarkVideoDirector
import LarkContainer
import ByteWebImage
import UniverseDesignActionPanel
import UniverseDesignDialog
import UniverseDesignToast
import LarkBizAvatar
import LarkRustClient
import ServerPB
import RustPB

public final class UploadImageViewController: BaseUIViewController {

    static let log = Logger.log(UploadImageViewController.self, category: "Modules.common")

    public typealias FinishCallback = (UploadImageViewController, _ urls: [String], _ imageSources: [ImageSourceProvider]) -> Void

    public var sourceView: UIView?

    private var window: UIWindow? = UIApplication.shared.windows.first(where: { $0.isKeyWindow })

    private lazy var actionSheet = createActionSheet(sourceView: self.sourceView)

    fileprivate var max: Int
    fileprivate var multiple: Bool
    fileprivate var crop: Bool
    fileprivate var supportReset: Bool
    fileprivate var actionCallback: ((_ isPhoto: Bool?) -> Void)?
    fileprivate var finish: FinishCallback

    fileprivate let imageUploader: PreviewImageUploader
    fileprivate let saveHandler: (() -> Void)?

    fileprivate var didAppeared: Bool = false
    fileprivate var resetToken: String = ""
    fileprivate var defaultAvatar: UIImage?

    fileprivate let editConfig: CropperConfigure

    private let userResolver: UserResolver
    private let navigator: Navigatable
    private var client: RustService?

    fileprivate let disposeBag = DisposeBag()

    public init(multiple: Bool,
                max: Int,
                imageUploader: PreviewImageUploader,
                userResolver: UserResolver,
                crop: Bool = false,
                supportReset: Bool = false,
                editConfig: CropperConfigure = .default,
                actionCallback: ((_ isPhoto: Bool?) -> Void)? = nil,
                saveHandler: (() -> Void)? = nil,
                finish: @escaping FinishCallback) {
        self.max = max
        self.multiple = multiple
        self.imageUploader = imageUploader
        self.userResolver = userResolver
        self.crop = crop
        self.supportReset = supportReset
        self.editConfig = editConfig
        self.actionCallback = actionCallback
        self.finish = finish
        self.saveHandler = saveHandler
        self.client = try? userResolver.resolve(assert: RustService.self)
        self.navigator = userResolver.navigator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        LarkAvatarTracker.trackAvatarMainClick()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if didAppeared {
            return
        }
        didAppeared = true

        // 拍摄
        let complete: (UIImage, UIViewController) -> Void = { [weak self] (image, picker) in
            guard let self = self else { return }
            if self.crop {
                picker.dismiss(animated: true) {
                    let vc = self.cropImage(image, presented: true)
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
                }
            } else {
                let sourceFunc = { image }
                self.finishSelectImages([sourceFunc], dismissOnError: true)
                picker.dismiss(animated: true, completion: nil)
            }
        }
        let cancel: () -> Void = { [weak self] in
            self?.dismiss()
        }
        actionSheet.addDefaultItem(text: BundleI18n.LarkAvatar.Lark_Legacy_UploadImageTakePhoto) { [weak self] in
            LarkAvatarTracker.trackAvatarChangeClick(clickType: .shot)
            if let self {
                LarkCameraKit.takePhoto(from: self, userResolver: self.userResolver,
                                        didCancel: { _ in cancel() }, completion: complete)
            }
            self?.actionCallback?(false)
        }
        // 从相册选择
        actionSheet.addDefaultItem(text: BundleI18n.LarkAvatar.Lark_Legacy_ChooseFromPhotolibrary) { [weak self] in
            LarkAvatarTracker.trackAvatarChangeClick(clickType: .fromAlbum)
            self?.showPhotoLibrary()
            self?.actionCallback?(true)
        }
        if supportReset {
            actionSheet.addDefaultItem(text: BundleI18n.LarkAvatar.Lark_Profile_UseDefaultProfilePhoto) { [weak self] in
                LarkAvatarTracker.trackAvatarChangeClick(clickType: .defaultAvatar)
                self?.resetAvatar()
            }
        }
        if let saveHandler = saveHandler {
            actionSheet.addDefaultItem(text: BundleI18n.LarkAvatar.Lark_Profile_SaveImage) {
                LarkAvatarTracker.trackAvatarChangeClick(clickType: .photoSave)
                saveHandler()
            }
        }
        // 取消
        actionSheet.setCancelItem(text: BundleI18n.LarkAvatar.Lark_Legacy_Cancel) { [weak self] in
            self?.dismiss(false)
            self?.actionCallback?(nil)
        }

        self.navigator.present(actionSheet, from: self)
    }

    public func dismiss(_ animated: Bool = true) {
        self.presentedViewController?.dismiss(animated: animated)
        self.removeFromParent()
        self.view.removeFromSuperview()
    }

    private func resetAvatar() {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkAvatar.Lark_Profile_UseDefaultProfilePhotoConfirmTitle)
        dialog.addSecondaryButton(text: BundleI18n.LarkAvatar.Lark_Profile_Cancel, dismissCompletion: { [weak self] in
            guard let `self` = self else {
                return
            }
            self.putResetUserAvatarResultRequest(isReset: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak dialog] (_) in
                    dialog?.dismiss(animated: true)
                }).disposed(by: self.disposeBag)
        })
        dialog.addPrimaryButton(text: BundleI18n.LarkAvatar.Lark_Profile_UseDefaultProfilePhotoConfirmButton, dismissCompletion: { [weak self] in
            LarkAvatarTracker.trackAvatarConfirmClick()
            guard let `self` = self else {
                return
            }
            self.putResetUserAvatarResultRequest(isReset: true)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self, weak dialog] (_) in
                    guard let `self` = self else {
                        return
                    }
                    dialog?.dismiss(animated: true)
                    UDToast.showSuccess(with: BundleI18n.LarkAvatar.Lark_Profile_SavedToAlbum, on: self.view)
                    if let image = self.defaultAvatar {
                        self.finish(self, [], [ {return image}])
                    }
                }).disposed(by: self.disposeBag)
        })
        let content = UIView()
        let avatar = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        avatar.layer.masksToBounds = true
        avatar.layer.cornerRadius = 30
        content.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60)
        }
        dialog.setContent(view: content)

        self.resetUserAvatarRequest()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let `self` = self else {
                    return
                }

                self.resetToken = res.resetToken
                avatar.bt.setLarkImage(with: .avatar(key: res.defaultAvatarKey,
                                                     entityID: "0",
                                                     params: .defaultBig),
                                       completion: { [weak self] result in
                                         switch result {
                                         case .success(let imageResult):
                                             self?.defaultAvatar = imageResult.image
                                         case .failure(let error):
                                             break
                                         }
                                       })
                self.navigator.present(dialog, from: self)
            }, onError: { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                self.navigator.present(dialog, from: self)
            }).disposed(by: self.disposeBag)
    }

    private func resetUserAvatarRequest() -> Observable<Contact_V1_GetDefaultAvatarResponse> {
        guard let client = client else {
            return .just(Contact_V1_GetDefaultAvatarResponse())
        }

        var request = Contact_V1_GetDefaultAvatarRequest()
        return client.sendAsyncRequest(request)
    }

    private func putResetUserAvatarResultRequest(isReset: Bool) -> Observable<ServerPB_Chatters_PutResetUserAvatarResultResponse> {
        guard let client = client else {
            return .just(ServerPB_Chatters_PutResetUserAvatarResultResponse())
        }
        var request = ServerPB_Chatters_PutResetUserAvatarResultRequest()
        request.status = isReset ? .reset : .abort
        if isReset {
            request.resetToken = self.resetToken
        }
        return client.sendPassThroughAsyncRequest(request, serCommand: .putResetUserAvatarResult)
    }
}

fileprivate extension UploadImageViewController {
    func showPhotoLibrary() {
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: multiple ? max : 1))
        if multiple {
            picker.showMultiSelectAssetGridViewController()
        } else {
            picker.showSingleSelectAssetGridViewController()
        }
        picker.imagePickerFinishSelect = { [weak self] (picker, result) in
            guard let `self` = self else {
                return
            }
            if self.crop {
                if let asset = result.selectedAssets.first {
                    if let window = self.window {
                        RoundedHUD.showLoading(on: window)
                    }
                    DispatchQueue.global().async {
                        let shortSideLimit = LarkImageService.shared.imageUploadSetting.avatarConfig.limitImageSize
                        let shortSide = min(asset.pixelWidth, asset.pixelHeight)
                        let ratio = CGFloat(min(1, Double(shortSideLimit) / Double(shortSide)))
                        let size = CGSize(width: round(CGFloat(asset.pixelWidth) * ratio),
                                          height: round(CGFloat(asset.pixelHeight) * ratio))
                        let image = asset.imageWithSize(size: size)
                        DispatchQueue.main.async {
                            if let window = self.window {
                                RoundedHUD.removeHUD(on: window)
                            }
                            if let image = image {
                                picker.pushViewController(self.cropImage(image), animated: true)
                            } else {
                                UploadImageViewController.log.error("获取压缩的图片失败")
                            }
                        }
                    }
                } else {
                    UploadImageViewController.log.error("获取压缩的图片失败")
                }
            } else {
                let imageSources = result.selectedAssets
                    .map { (asset) -> ImageSourceProvider in
                        return {
                            return asset.originalImage()
                        }
                    }
                self.finishSelectImages(imageSources, isOrigin: result.isOriginal)
            }
        }
        picker.imagePikcerCancelSelect = { [weak self] (_, _) in
            self?.dismiss()
        }
        picker.imageEditAction = imageUploader.imageEditAction
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true, completion: nil)
    }

    func cropImage(_ image: UIImage, presented: Bool = false) -> UIViewController {
        let vc = CropperFactory.createCropper(with: image, and: editConfig)
        vc.cancelCallback = { [weak self] cropper in
            if presented {
                self?.dismiss()
            } else {
                cropper.navigationController?.popViewController(animated: true)
            }
        }
        vc.successCallback = { [weak self] image, _, _ in
            self?.finishSelectImages([ { image } ])
        }

        return vc
    }

    func finishSelectImages(_ imageSources: [ImageSourceProvider],
                            isOrigin: Bool = false,
                            dismissOnError: Bool = false) {
        // 显示hud
        var hud: RoundedHUD?
        if let window = self.window ?? self.presentingViewController?.view.window {
            hud = RoundedHUD.showLoading(with: BundleI18n.LarkAvatar.Lark_Legacy_Uploading,
                                         on: window,
                                         disableUserInteraction: true)
        }
        self.imageUploader.upload(imageSources, isOrigin: isOrigin).subscribe(onNext: { [weak self] (urls) in
            guard let `self` = self else { return }
            UploadImageViewController.log.info("upload image success urls:\(urls.count)")
            if let window = self.window {
                hud?.showSuccess(with: BundleI18n.LarkAvatar.Lark_Legacy_UploadImageSuccess, on: window)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                hud?.remove()
                self.finish(self, urls, imageSources)
                self.dismiss()
            })
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            
            if let sendImageError = error as? LarkSendImageError,
               let rcError = sendImageError.error.metaErrorStack.compactMap({ error in error as? RCError }).first,
               case .businessFailure(let e) = rcError,
               e.code == 4055 {
                UploadImageViewController.log.error("没有上传头像的权限", error: error)
                hud?.remove()
                let alertController = LarkAlertController()
                alertController.setTitle(text: e.displayMessage)
                alertController.addPrimaryButton(text: BundleI18n.LarkAvatar.Lark_Legacy_IKnow())
                var topController: UIViewController = self
                while let newTopController = topController.presentedViewController {
                    topController = newTopController
                }
                self.navigator.present(alertController, from: topController)
                return
            }
            UploadImageViewController.log.error("上传图片失败", error: error)
            if let window = self.window ?? self.presentingViewController?.view.window {
                hud?.showFailure(with: BundleI18n.LarkAvatar.Lark_Legacy_NetworkError, on: window)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                hud?.remove()
                if dismissOnError {
                    self.dismiss()
                }
            })
        }).disposed(by: disposeBag)
    }

    func createActionSheet(sourceView: UIView?) -> UDActionSheet {
        var actionSheet: UDActionSheet
        if let sourceView = sourceView {
            let popSource = UDActionSheetSource(sourceView: sourceView, sourceRect: sourceView.bounds)
            let config = UDActionSheetUIConfig(style: .autoPopover(popSource: popSource))
            actionSheet = UDActionSheet(config: config)
        } else {
            let config = UDActionSheetUIConfig(style: .normal)
            actionSheet = UDActionSheet(config: config)
            actionSheet.modalPresentationStyle = .overFullScreen
        }
        return actionSheet
    }
}
