//
//  ImageEditHandler.swift
//  LarkMessageCore
//
//  Created by Supeng on 2021/4/15.
//
import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import UniverseDesignToast
import LarkImageEditor
import LarkUIKit
import EENavigator
import LarkActionSheet
import LarkMessengerInterface
import LarkCache
import LarkContainer
import LarkFoundation
import ByteWebImage
import LarkCore
import RxSwift
import UniverseDesignDialog
import LarkSensitivityControl

/// 图片消息编辑
public final class ImageEditHandler {
    enum ImageEditToken: String {
        case savePhoto

        var token: Token {
            switch self {
            case .savePhoto:
                return Token("LARK-PSDA-ImageEdit_savePhoto")

            }
        }
    }

    public init(chatSecurityControlService: ChatSecurityControlService?, nav: Navigatable, fromVC: UIViewController) {
        self.chatSecurityControlService = chatSecurityControlService
        self.fromVC = fromVC
        self.nav = nav
    }

    /// 权限管控服务
    private var chatSecurityControlService: ChatSecurityControlService?
    private var chat: Chat?
    /// 编辑后保存需要进行DLP检测
    private var securityExtraInfo: SecurityExtraInfo?
    private let imageView = UIImageView()
    private let disposeBag = DisposeBag()
    private weak var fromVC: UIViewController?
    private weak var navigationVC: UIViewController?
    private let nav: Navigatable

    public func handle(message: Message, chat: Chat, params: [String: Any]) {
        guard let imageContent = message.content as? ImageContent,
                let fromVC = self.fromVC, let chatSecurityControlService = self.chatSecurityControlService else {
            return
        }
        let permissionPreview = chatSecurityControlService.checkPermissionPreview(anonymousId: chat.anonymousId, message: message)
        if !permissionPreview.0 {
            chatSecurityControlService.authorityErrorHandler(event: .localImagePreview, authResult: permissionPreview.1, from: fromVC, errorMessage: nil, forceToAlert: true)
            return
        }
        if chat.enableRestricted(.forward) && chat.enableRestricted(.download) {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_UnableToEditImage_Toast, on: fromVC.view)
            return
        }
        self.chat = chat
        let hud = UDToast.showLoading(on: fromVC.view)
        let imageSet = ImageItemSet.transform(imageSet: imageContent.image)
        let imageKey = imageSet.generateImageMessageKey(forceOrigin: true)
        self.securityExtraInfo = SecurityExtraInfo(fileKey: imageSet.origin?.key ?? "", message: message, chat: chat)
        let placeholder = imageSet.inlinePreview
        imageView.bt.setLarkImage(with: .default(key: imageKey),
                                  placeholder: placeholder,
                                  completion: { [weak self] result in
                                    hud.remove()
                                    guard let self = self, let fromVC = self.fromVC else {
                                        return
                                    }
                                    switch result {
                                    case .success(let imageResult):
                                        if let image = imageResult.image {
                                            self.showImageEdit(with: image, fromVC: fromVC)
                                        }
                                    case .failure:
                                        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_NetworkOrServiceError, on: fromVC.view)
                                    }
                                  })
    }

    private func showImageEdit(with image: UIImage, fromVC: UIViewController?) {
        guard let fromVC = fromVC else { return }

        let imageEditVC = ImageEditorFactory.createEditor(with: image)
        imageEditVC.delegate = self
        imageEditVC.editEventObservable.subscribe(onNext: {
            CoreTracker.trackImageEditEvent($0.event, params: $0.params)
        }).disposed(by: disposeBag)
        let navigationVC = LkNavigationController(rootViewController: imageEditVC)
        self.navigationVC = navigationVC
        navigationVC.modalPresentationStyle = .fullScreen
        self.nav.present(navigationVC, from: fromVC, animated: true)
    }
}

extension ImageEditHandler: ImageEditViewControllerDelegate {
    public func closeButtonDidClicked(vc: EditViewController) {
        vc.exit()
    }

    public func finishButtonDidClicked(vc: EditViewController, editImage: UIImage) {
        guard let chat = chat, let fromVC = self.fromVC else {
            return
        }
        let adapter = ActionSheetAdapter()
        let actionSheet = adapter.create(level: .normalWithCustomActionSheet)
        if !chat.enableRestricted(.forward) {
            adapter.addItem(title: BundleI18n.LarkMessageCore.Lark_Legacy_Forward) { [weak self] in
                guard let self = self else { return }
                // 取消分享需要重新进入编辑界面，PM要求此逻辑和微信保持一致
                let cancelCallBack: (() -> Void) = { [weak self] in
                    self?.showImageEdit(with: editImage, fromVC: self?.fromVC)
                }
                // 分享成功后内部调dismiss，vc所在navigationVC会一起dismiss掉；符合预期，PM要求分享成功后需要同时消失分享&编辑界面
                let resource = self.nav.response(for: ShareImageBody(image: editImage,
                                                                             type: .forward,
                                                                             cancelCallBack: cancelCallBack)).resource
                // ShareImageHandler内部会包装一层navigationVC，我们只取rootVC，不然无法做到同时消失分享&编辑界面
                guard let shareVC = (resource as? UINavigationController)?.viewControllers[0] else { return }
                self.nav.push(shareVC, from: vc, animated: true, completion: nil)
            }
        }
        if !chat.enableRestricted(.download) {
            adapter.addItem(title: BundleI18n.LarkMessageCore.Lark_Legacy_ImageSave) { [weak self] in
                guard let self = self, let fromVC = self.fromVC else { return }
                self.chatSecurityControlService?.downloadAsyncCheckAuthority(event: .saveImage, securityExtraInfo: self.securityExtraInfo) { [weak self] authority in
                    guard let self = self else { return }
                    guard authority.authorityAllowed else {
                        self.chatSecurityControlService?.authorityErrorHandler(event: .saveImage,
                                                                               authResult: authority,
                                                                               from: vc)
                        return
                    }

                    guard !LarkCache.isCryptoEnable() else {
                        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Core_SecuritySettingKAToast, on: fromVC.view)
                        return
                    }

                    try? Utils.savePhoto(token: ImageEditToken.savePhoto.token, image: editImage) { (granted, succeeded) in
                        DispatchQueue.main.async {
                            // 被限制
                            guard granted else {
                                let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkMessageCore.Lark_Core_PhotoAccessForSavePhoto,
                                                                         detail: BundleI18n.LarkMessageCore.Lark_Core_PhotoAccessForSavePhoto_Desc())
                                fromVC.present(dialog, animated: true, completion: nil)
                                return
                            }
                            if succeeded {
                                UDToast.showSuccess(
                                    with: BundleI18n.LarkMessageCore.Lark_Legacy_QrCodeSaveToAlbum,
                                    on: fromVC.view
                                )
                            } else {
                                UDToast.showFailure(
                                    with: BundleI18n.LarkMessageCore.Lark_Legacy_PhotoZoomingSaveImageFail,
                                    on: fromVC.view
                                )
                            }
                            // 保存成功，退出界面
                            vc.exit()
                        }
                    }
                }
            }
        }
        adapter.addCancelItem(title: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)
        self.nav.present(actionSheet, from: vc)
    }
}
