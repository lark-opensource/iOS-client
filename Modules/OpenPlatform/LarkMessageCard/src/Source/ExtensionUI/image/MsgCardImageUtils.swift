//
//  MsgCardImageUtils.swift
//  LarkMessageCard
//
//  Created by zhujingcheng on 11/8/23.
//

import Foundation
import RustPB
import LarkOPInterface
import LarkModel
import LarkUIKit
import LarkCore
import LarkMessengerInterface
import LarkAccountInterface
import EENavigator

final class MsgCardImageUtils {
    static func getAttachmentImages(cardContext: MessageCardContainer.Context?, openPlatformService: OpenPlatformService?, isTranslateElement: Bool) -> [String : Basic_V1_RichTextElement.ImageProperty]? {
        let message = cardContext?.getBizContext(key: "message") as? Message
        var cardContent: CardContent?
        //消息场景
        if let msg = message {
            if isTranslateElement {
                cardContent = msg.translateContent as? CardContent
            } else {
                cardContent = msg.content as? CardContent
            }
        } else if let content = cardContext?.bizContext["pinPreviewContent"] as? CardContent {
            //unpin 预览场景
            cardContent = content
        } else {
            //sendMessageCard
            cardContent = openPlatformService?.fetchCardContent()
        }
        return cardContent?.jsonAttachment?.images
    }
    
    static func showPreviewImage(cardContext: MessageCardContainer.Context?, images: [String : Basic_V1_RichTextElement.ImageProperty]?, imageKey: String?, previewImages: [String]?) {
        guard let sourceVC = cardContext?.dependency?.sourceVC,
              let originImageProperies = images,
              let imageKey = imageKey,
              let message = cardContext?.getBizContext(key: "message") as? Message,
              !message.isDeleted, !message.isRecalled else {
            return
        }
        let chat = cardContext?.getBizContext(key: "chat") as? Chat
        
        var assets: [LKDisplayAsset] = []
        var assetPositionMap: [String: (position: Int32, id: String)] = [:]
        var imageProperies: [Basic_V1_RichTextElement.ImageProperty] = []
        
        if let previewImageKeys = previewImages {
            for imageKey in previewImageKeys {
                if let imageProperty = originImageProperies[imageKey] {
                    imageProperies.append(imageProperty)
                }
            }
        }
            
        let index = imageProperies.firstIndex{ (property) -> Bool in
            return property.originKey == imageKey
        }
        imageProperies.forEach { (imageProperty) in
            let imageAsset = LKDisplayAsset.createAsset(postImageProperty: imageProperty, isTranslated: false, isAutoLoadOrigin: AccountServiceAdapter.shared.currentChatterId == message.fromId)//测试代码，找IM的同学看下有没有DI方法
            imageAsset.detectCanTranslate = message.localStatus == .success
            imageAsset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
            imageAsset.extraInfo[ImageAssetMessageIdKey] = message.id
            imageAsset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
            assets.append(imageAsset)
            assetPositionMap[imageAsset.key] = (message.position, message.id)
        }
        let assetResult = CreateAssetsResult(assets: assets, selectIndex: index, assetPositionMap: assetPositionMap)
        guard !assetResult.assets.isEmpty, let index = assetResult.selectIndex else {
            return
        }
        var body: PreviewImagesBody
        if let chat = chat {
            body = PreviewImagesBody(assets: assetResult.assets.map { $0.transform() },
                                     pageIndex: index,
                                     scene: .normal(assetPositionMap: assetResult.assetPositionMap, chatId: chat.id),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canSaveImage: !chat.enableRestricted(.download),
                                     canShareImage: !chat.enableRestricted(.forward),
                                     canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
                                     showSaveToCloud: !chat.enableRestricted(.download),
                                     canTranslate: false,
                                     translateEntityContext: (message.id, .message))
        } else {
            body = PreviewImagesBody(assets: assetResult.assets.map { $0.transform() },
                                     pageIndex: index,
                                     scene: .normal(assetPositionMap: assetResult.assetPositionMap, chatId: nil),
                                     shouldDetectFile: chat?.shouldDetectFile ?? false,
                                     canTranslate: false,
                                     translateEntityContext: (message.id, .message))
        }
        Navigator.shared.present(body: body, from: sourceVC)
    }
}
