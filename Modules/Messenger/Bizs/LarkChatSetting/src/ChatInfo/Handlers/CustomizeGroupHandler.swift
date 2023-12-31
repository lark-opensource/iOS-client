//
//  CustomizeAvatarHandler.swift
//  LarkChatSetting
//
//  Created by 李勇 on 2020/4/20.
//

import UIKit
import Foundation
import EENavigator
import Swinject
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import RustPB
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkCore
import ByteWebImage
import LarkFeatureGating
import LKCommonsLogging
import LarkContainer
import ThreadSafeDataStructure
import LarkNavigator
import LarkSetting
import LarkModel

/// 定制群头像
final class CustomizeGroupAvatarHandler: UserTypedRouterHandler {
    private let disposeBag = DisposeBag()
    private var newAvatarFG: Bool {
        return userResolver.fg.dynamicFeatureGatingValue(with: "messenger.chat.groupavatar.v2.client")
    }

    private var genericAvatarFG: Bool {
        return userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.groupavatar.v3")
    }

    static func compatibleMode() -> Bool {
        ChatSetting.userScopeCompatibleMode
    }

    func handle(_ body: CustomizeGroupAvatarBody, req: EENavigator.Request, res: Response) throws {
        let chatId = body.chat.id
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        if genericAvatarFG {
            let viewModel = AvatarBaseViewModel(name: body.chat.name,
                                                defaultCenterIcon: Resources.newStyle_color_icon,
                                                drawStyle: .soild,
                                                resolver: self.userResolver,
                                                avatarMetaObservable: chatAPI.fetchChatAvatarMeta(chatId: chatId)
                .map { avatarMeta -> RustPB.Basic_V1_AvatarMeta? in return avatarMeta })

            let vc = GenericAvatarSettingController(chatId: chatId,
                                                    defaultAvatar: .avatarKey(entityId: chatId, key: body.chat.avatarKey),
                                                    viewModel: viewModel,
                                                    jointAvatarEnable: true)

            vc.savedCallback = { [weak self] iconImage, avatarMeta, targetVC, trackInfo in
                self?.uploadAvatar(iconImage: iconImage,
                                  avatarMeta: avatarMeta,
                                  targetVC: targetVC,
                                  chatId: chatId,
                                  chatAPI: chatAPI)
                NewChatSettingTracker.genericAvatarSaveClick(chat: body.chat, trackInfo: trackInfo)
            }
            res.end(resource: vc)
            return
        }
        if newAvatarFG {
            let viewModel = VariousAvatarEditViewModel(resolver: self.userResolver,
                                                       defaultCenterIcon: Resources.newStyle_color_icon,
                                                       drawStyle: .soild,
                                                       name: body.chat.name,
                                                       avatarType: .avatarKey(entityId: chatId, key: body.chat.avatarKey),
                                                       avatarMetaObservable: chatAPI.fetchChatAvatarMeta(chatId: chatId)
                .map { avatarMeta -> RustPB.Basic_V1_AvatarMeta? in return avatarMeta })
            let vc = VariousAvatarEditController(viewModel: viewModel)
            vc.savedCallback = { [weak self] iconImage, avatarMeta, targetVC, _, trackInfo in
                self?.uploadAvatar(iconImage: iconImage,
                                  avatarMeta: avatarMeta,
                                  targetVC: targetVC,
                                  chatId: chatId,
                                  chatAPI: chatAPI)
                NewChatSettingTracker.variousAvatarSaveClick(chat: body.chat,
                                                             isWord: trackInfo.isWord,
                                                             isImage: trackInfo.isImage,
                                                             isFill: trackInfo.isFill,
                                                             isTick: trackInfo.isTick,
                                                             isEnter: trackInfo.isEnter)
            }
            res.end(resource: vc)
            return
        }

        let vm = CustomizeAvatarViewModel(
            resolver: self.userResolver,
            initAvatarType: .avatarKey(entityId: chatId, key: body.chat.avatarKey),
            name: body.chat.name,
            defaultCenterIcon: Resources.defalut_color_icon,
            drawStyle: body.avatarDrawStyle,
            avatarMetaObservable: chatAPI.fetchChatAvatarMeta(chatId: chatId)
                .map { avatarMeta -> RustPB.Basic_V1_AvatarMeta? in return avatarMeta })

        let vc = CustomizeAvatarController(viewModel: vm)
        vc.extraInfo = ["chat": body.chat]
        let isOwner = self.userResolver.userID == body.chat.ownerId

        vc.savedCallback = { [weak self] iconImage, avatarMeta, targetVC, textView in
            guard let self = self, let centerTextView = textView as? GroupTextView else {
                return
            }
            ChatSettingTracker.trackGroupProfileSave(chat: body.chat)
            NewChatSettingTracker.imChatSettingEditAvatarSaveClick(chatId: chatId,
                                                                    isAdmin: isOwner,
                                                                    isUploadPhoto: avatarMeta.type == .upload,
                                                                    isChooseTitle: centerTextView.selectButtonTag != -1,
                                                                    titleIndex: centerTextView.selectButtonTag,
                                                                    isInputTitle: !centerTextView.inputText.isEmpty,
                                                                    isChooseColor: avatarMeta.hasColor,
                                                                    colorHex: avatarMeta.color)
            self.uploadAvatar(iconImage: iconImage,
                              avatarMeta: avatarMeta,
                              targetVC: targetVC,
                              chatId: chatId,
                              chatAPI: chatAPI)

        }

        res.end(resource: vc)
    }

    func uploadAvatar(iconImage: UIImage,
                      avatarMeta: RustPB.Basic_V1_AvatarMeta,
                      targetVC: UIViewController,
                      chatId: String,
                      chatAPI: ChatAPI) {
        let hud = UDToast.showLoading(on: targetVC.view)
        let sendImageByAvatar = SendImageByAvatar(chatAPI: chatAPI, chatId: chatId, avatarMeta: avatarMeta, disposeBag: self.disposeBag)
        if avatarMeta.type == .collage {
            chatAPI
                .updateChat(chatId: chatId, avatarMeta: avatarMeta)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak targetVC, weak hud, weak self] _ in
                    guard let targetVC = targetVC, let navi = self?.userResolver.navigator else { return }
                    hud?.remove()
                    if targetVC.presentingViewController != nil {
                        targetVC.presentingViewController?.dismiss(animated: true, completion: nil)
                    } else {
                        navi.pop(from: targetVC)
                    }
                }, onError: { [weak targetVC, weak hud] _ in
                    if let targetVC = targetVC {
                        hud?.showTips(with: BundleI18n.LarkChatSetting.Lark_Legacy_SaveFail, on: targetVC.view)
                    }
                }).disposed(by: self.disposeBag)
            return
        }

        let avatarUploadConfig = LarkImageService.shared.imageUploadSetting.avatarConfig
        let compressRate = Float(avatarUploadConfig.quality) / 100
        let destPixel = avatarUploadConfig.limitImageSize
        let sendImageRequest = SendImageRequest(
            input: .image(iconImage),
            sendImageConfig: SendImageConfig(
                checkConfig: SendImageCheckConfig(needConvertToWebp: true,
                                                  scene: .GroupAvatar, fromType: .avatar),
                compressConfig: SendImageCompressConfig(compressRate: compressRate, destPixel: destPixel)),
            uploader: sendImageByAvatar)
        SendImageManager.shared.sendImage(request: sendImageRequest)
            .subscribe(onNext: { [weak targetVC, weak hud, weak self] _ in
                guard let targetVC = targetVC, let navi = self?.userResolver.navigator else { return }
                hud?.remove()
                if targetVC.presentingViewController != nil {
                    targetVC.presentingViewController?.dismiss(animated: true, completion: nil)
                } else {
                    navi.pop(from: targetVC)
                }
            }, onError: { [weak targetVC, weak hud] _ in
                if let targetVC = targetVC {
                    hud?.showTips(with: BundleI18n.LarkChatSetting.Lark_Legacy_SaveFail, on: targetVC.view)
                }
            }).disposed(by: self.disposeBag)
    }
}

/// 通用定制头像
final class TeamCustomizeAvatarHandler: UserTypedRouterHandler {
    private let disposeBag = DisposeBag()
    private var newAvatarFG: Bool {
        return userResolver.fg.dynamicFeatureGatingValue(with: "messenger.chat.groupavatar.v2.client")
    }
    private var genericAvatarFG: Bool {
        return userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.groupavatar.v3")
    }

    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: TeamCustomizeAvatarBody, req: EENavigator.Request, res: Response) throws {
        var tragetImage: UIImage?
        if let imageData = body.imageData {
            tragetImage = UIImage(data: imageData)
        }

        let avatarType: VariousAvatarType
        if let image = tragetImage {
            avatarType = .image(image)
        } else {
            avatarType = .avatarKey(entityId: body.entityId, key: body.avatarKey)
        }

        if genericAvatarFG {
            let viewModel = AvatarBaseViewModel(name: body.name,
                                                defaultCenterIcon: body.defaultCenterIcon,
                                                drawStyle: .transparent,
                                                resolver: self.userResolver,
                                                avatarMetaObservable: .just(body.avatarMeta))

            let vc = GenericAvatarSettingController(chatId: body.entityId,
                                                    defaultAvatar: avatarType,
                                                    viewModel: viewModel,
                                                    jointAvatarEnable: false)

            vc.savedCallback = { iconImage, avatarMeta, targetVC, _ in
                body.savedCallback?(iconImage, avatarMeta, targetVC, targetVC.view)
            }
            res.end(resource: vc)
            return
        }

        if newAvatarFG {
            let viewModel = VariousAvatarEditViewModel(resolver: self.userResolver,
                                                       defaultCenterIcon: body.defaultCenterIcon,
                                                       drawStyle: .transparent,
                                                       name: body.name,
                                                       avatarType: avatarType,
                                                       avatarMetaObservable: .just(body.avatarMeta))
            let vc = VariousAvatarEditController(viewModel: viewModel)
            vc.savedCallback = { iconImage, avatarMeta, targetVC, view, _ in
                body.savedCallback?(iconImage, avatarMeta, targetVC, view)
            }
            res.end(resource: vc)
            return
        }

        let initAvatarType: AvatarSetType
        if let image = tragetImage {
            initAvatarType = .image(image: image)
        } else {
            initAvatarType = .avatarKey(entityId: body.entityId, key: body.avatarKey)
        }
        let vm = CustomizeAvatarViewModel(resolver: self.userResolver,
                                          initAvatarType: initAvatarType,
                                          name: body.name,
                                          defaultCenterIcon: body.defaultCenterIcon,
                                          drawStyle: .soild,
                                          avatarMetaObservable: .just(body.avatarMeta))
        let vc = CustomizeAvatarController(viewModel: vm)
        vc.savedCallback = body.savedCallback
        res.end(resource: vc)
    }
}

final class SendImageByAvatar: LarkSendImageUploader {
    private let chatAPI: ChatAPI
    private let chatId: String
    private let avatarMeta: RustPB.Basic_V1_AvatarMeta
    private let disposeBag: DisposeBag
    static private let logger = Logger.log(SendImageByAvatar.self, category: "LarkChatSetting.CustomizeGroupHandler")
    typealias AbstractType = String
    init(chatAPI: ChatAPI, chatId: String, avatarMeta: RustPB.Basic_V1_AvatarMeta, disposeBag: DisposeBag) {
        self.chatAPI = chatAPI
        self.chatId = chatId
        self.avatarMeta = avatarMeta
        self.disposeBag = disposeBag
    }
    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<AbstractType> {
        return Observable<AbstractType>.create { [weak self] observer in
            guard let `self` = self,
                  let imageSourceResult = request.getCompressResult()?.first?.result,
                  case .success(let imageResult) = imageSourceResult,
                  let iconData = imageResult.data
            else {
                observer.onError(CompressError.requestRelease)
                return Disposables.create()
            }
            self.chatAPI
                .updateChat(chatId: self.chatId, iconData: iconData, avatarMeta: self.avatarMeta)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    observer.onNext("")
                    SendImageByAvatar.logger.info("updateChat success")
                }, onError: { error in
                    observer.onError(error)
                    SendImageByAvatar.logger.error("updateChat error \(error)")
                }, onCompleted: {
                    observer.onCompleted()
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
}
