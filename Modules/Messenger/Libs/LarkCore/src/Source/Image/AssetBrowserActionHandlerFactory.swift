//
//  AssetBrowserActionHandlerFactory.swift
//  Action
//
//  Created by K3 on 2018/8/28.
//

import UIKit
import Foundation
import LarkContainer
import Swinject
import LarkMessengerInterface
import LarkUIKit
import LarkAccountInterface
import LarkSDKInterface
import LarkAssetsBrowser

final public class AssetBrowserActionHandlerFactory {
    static public func handler(with resoler: UserResolver,
                               shouldDetectFile: Bool,
                               canSaveImage: Bool = true,
                               canEditImage: Bool = false,
                               canTranslate: Bool = true,
                               canImageOCR: Bool = false,
                               scanQR: ((String) -> Void)? = nil,
                               loadMoreOldAsset: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)? = nil,
                               loadMoreNewAsset: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)? = nil,
                               showSaveToCloud: Bool? = nil,
                               shareImage: ((String, UIImage) -> Void)? = nil,
                               viewInChat: ((LKDisplayAsset) -> Void)? = nil,
                               viewInChatTitle: String? = nil,
                               fromWhere: PreviewImagesFromWhere = .other,
                               onSaveImage: ((LKDisplayAsset) -> Void)? = nil,
                               saveImageFinishCallBack: ((LKDisplayAsset?, _ succeed: Bool) -> Void)? = nil,
                               onEditImage: ((LKDisplayAsset) -> Void)? = nil,
                               onNextImage: ((LKDisplayAsset) -> Void)? = nil,
                               onSaveVideo: ((MediaInfoItem) -> Void)? = nil,
                               addToSticker: ((LKDisplayAsset) -> Void)? = nil) throws -> AssetBrowserActionHandler {

        let resourceAPI = try resoler.resolve(assert: ResourceAPI.self)
        let videoSaveService = try resoler.resolve(assert: VideoSaveService.self)
        let passportUser = try resoler.resolve(assert: PassportUserService.self)
        var showSaveToCloudTmp: Bool = false
        let isByteDancer = passportUser.user.tenant.isByteDancer
        if let saveToCloud = showSaveToCloud {
            showSaveToCloudTmp = saveToCloud && isByteDancer
        } else {
            showSaveToCloudTmp = isByteDancer
        }

    return AssetBrowserActionHandler(
        userResolver: resoler,
        resourceAPI: resourceAPI,
        videoSaveService: videoSaveService,
        shouldDetectFile: shouldDetectFile,
        showSaveToCloud: showSaveToCloudTmp,
        canSaveImage: canSaveImage,
        canEditImage: canEditImage,
        canTranslate: canTranslate,
        canImageOCR: canImageOCR,
        scanQR: scanQR,
        loadMoreOldAsset: loadMoreOldAsset,
        loadMoreNewAsset: loadMoreNewAsset,
        shareImage: shareImage,
        viewInChat: viewInChat,
        viewInChatTitle: viewInChatTitle ?? BundleI18n.LarkCore.Lark_Legacy_JumpToChat,
        fromWhere: fromWhere,
        onSaveImage: onSaveImage,
        saveImageFinishCallBack: saveImageFinishCallBack,
        onEditImage: onEditImage,
        onNextImage: onNextImage,
        onSaveVideo: onSaveVideo,
        addToSticker: addToSticker
        )
    }
}
