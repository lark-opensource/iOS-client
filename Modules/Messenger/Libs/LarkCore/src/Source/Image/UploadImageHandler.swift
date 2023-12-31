//
//  UploadImageHandler.swift
//  Lark
//
//  Created by liuwanlin on 2018/5/18.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkUIKit
import LarkMessengerInterface
import EENavigator
import Swinject
import RxSwift
import LarkSDKInterface
import LarkAvatar
import LarkAssetsBrowser
import LarkImageEditor
import ByteWebImage
import LarkNavigator
extension Asset {
    public func transform() -> LKDisplayAsset {
        let displayAsset: LKDisplayAsset
        if !self.isVideo {
            displayAsset = LKDisplayAsset()
            displayAsset.originalUrl = self.originalUrl
        } else {
            displayAsset = LKDisplayAsset.initWith(
                videoUrl: self.videoUrl,
                videoCoverUrl: self.videoCoverUrl,
                videoSize: self.videoSize)
            displayAsset.isVideoMuted = self.isVideoMuted
            displayAsset.isLocalVideoUrl = self.isLocalVideoUrl
            displayAsset.duration = self.duration
        }
        displayAsset.key = self.key
        displayAsset.fsUnit = self.fsUnit
        displayAsset.placeHolder = self.placeHolder
        displayAsset.originalImageKey = self.originKey
        displayAsset.intactImageKey = self.intactKey
        displayAsset.originalImageSize = self.originImageFileSize
        displayAsset.isAutoLoadOriginalImage = self.isAutoLoadOrigin
        displayAsset.forceLoadOrigin = self.forceLoadOrigin
        displayAsset.detectCanTranslate = self.detectCanTranslate
        displayAsset.permissionState = self.permissionState
        displayAsset.visibleThumbnail = self.visibleThumbnail
        displayAsset.extraInfo = self.extraInfo
        displayAsset.extraInfo[ImageAssetExtraInfo] = LKDisplayAsset.transform(sourceType: self.sourceType)
        displayAsset.trackExtraInfo = self.trackExtraInfo
        displayAsset.translateProperty = DisplayAssetTranslationProperty(rawValue: self.translateProperty.rawValue) ?? .origin
        displayAsset.riskObjectKeys = self.riskObjectKeys

        return displayAsset
    }
}

open class UploadImageHandler: UserTypedRouterHandler {

    public func handle(_ body: UploadImageBody, req: EENavigator.Request, res: Response) throws {
        let imageAPI = try userResolver.resolve(assert: ImageAPI.self)

        let controller = UploadImageViewController(
            multiple: body.multiple,
            max: body.max,
            imageUploader: DefaultImageUploader(imageAPI: imageAPI),
            userResolver: userResolver,
            crop: false,
            finish: { (uploader, urls, _) in
                uploader.dismiss()
                body.uploadSuccess?(urls)
            }
        )

        res.end(resource: controller)
    }
}
