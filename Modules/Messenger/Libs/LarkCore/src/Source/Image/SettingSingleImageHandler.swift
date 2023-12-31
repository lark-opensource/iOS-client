//
//  PreviewGroupAvatarHandler.swift
//  Lark
//
//  Created by liuwanlin on 2018/8/17.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkUIKit
import Swinject
import LarkMessengerInterface
import EENavigator
import LarkAvatar
import LarkAssetsBrowser
import LarkImageEditor
import ByteWebImage
import LarkNavigator

open class SettingSingleImageHandler: UserTypedRouterHandler {

    public func handle(_ body: SettingSingeImageBody, req: EENavigator.Request, res: Response) throws {
        let chatSecurityAuditService = try userResolver.resolve(assert: ChatSecurityAuditService.self)

        let asset = body.asset.transform()
        let controller = AvatarSettingViewController(
            assets: [asset],
            pageIndex: 0,
            labelText: body.modifyAvatarString ??
                BundleI18n.LarkCore.Lark_Legacy_ModifyAvatarGroupChat,
            showTips: body.type == .background ? true : false,
            navigator: userResolver.navigator,
            actionHandler: try AssetBrowserActionHandlerFactory.handler(
                with: userResolver,
                shouldDetectFile: true,
                canTranslate: false,
                canImageOCR: false,
                onSaveImage: { imageAsset in
                    chatSecurityAuditService.auditEvent(.saveImage(key: imageAsset.key),
                                                        isSecretChat: false)
                },
                onSaveVideo: { mediaInfoItem in
                    chatSecurityAuditService.auditEvent(.saveVideo(key: mediaInfoItem.key),
                                                        isSecretChat: false)
                })
            )
        let type = body.type
        controller.prepareAssetInfo = { displayAsset in
            var imagePassThrough: ImagePassThrough?
            if !body.asset.fsUnit.isEmpty {
                imagePassThrough = ImagePassThrough()
                imagePassThrough?.key = body.asset.key
                imagePassThrough?.fsUnit = body.asset.fsUnit
            }
            switch type {
            case .face:
                var entityId = ""
                if let extraInfo = asset.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType,
                case .avatar(_, let userId) = extraInfo {
                    entityId = userId ?? ""
                }
                return (LarkImageResource.avatar(key: displayAsset.key, entityID: entityId, params: .defaultBig),
                        imagePassThrough, TrackInfo(scene: .GroupAvatar, fromType: .avatar)) // SettingSingleImageBody 主要用于群头像
            case .image, .background:
                return (LarkImageResource.default(key: displayAsset.key), imagePassThrough, TrackInfo(scene: .Chat, fromType: .image))
            }
        }

        controller.isSavePhotoButtonHidden = true
        let userResolver = self.userResolver
        controller.provider = { finish in
            body.showUploadCallback?()
            return UploadImageViewController(
                multiple: false,
                max: 1,
                imageUploader: SettingSingleImageUploader(updateCallback: body.updateCallback),
                userResolver: userResolver,
                crop: true,
                editConfig: body.editConfig,
                actionCallback: { isPhoto in
                    body.actionCallback?(isPhoto)
                },
                finish: finish)
        }
        res.end(resource: controller)
    }
}
