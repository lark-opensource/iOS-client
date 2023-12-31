//
//  RustTranslateAPI.swift
//  Lark
//
//  Created by 姚启灏 on 2018/7/25.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface

final class RustTranslateAPI: LarkAPI, TranslateAPI {
    func translateURLInlines(inlineContexts: [URLInlineContext], isAutoTranslate: Bool) -> Observable<RustPB.Basic_V1_TranslateMessageUrlPreviewsResponse> {
        var request = Basic_V1_TranslateMessageUrlPreviewsRequest()
        request.translateContexts = inlineContexts.map({ $0.translateContext() })
        request.isAutoTranslate = isAutoTranslate
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 手动翻译一些消息
    func manualTranslate(contexts: [MessageContext], isFromMessageUpdate: Bool) -> Observable<RustPB.Im_V1_TranslateMessagesV3Response> {
        var request = RustPB.Im_V1_TranslateMessagesV3Request()
        request.translateContexts = contexts.map({ $0.translateContext() })
        request.isTranslateByUser = true
        request.isFromMessageUpdate = isFromMessageUpdate
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 自动检测一些消息
    func autoTranslate(contexts: [MessageContext], isFromMessageUpdate: Bool) -> Observable<RustPB.Im_V1_TranslateMessagesV3Response> {
        var request = RustPB.Im_V1_TranslateMessagesV3Request()
        request.translateContexts = contexts.map({ $0.translateContext() })
        request.isTranslateByUser = false
        request.isFromMessageUpdate = isFromMessageUpdate
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 获取消息主语言
    func getMessageLanguage(messageIds: [String]) -> Observable<[String: String]> {
        var request = Im_V1_GetMessageLanguageRequest()
        request.messageIds = messageIds
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_GetMessageLanguageResponse) -> [String: String] in
            return response.messageLanguage
        }).subscribeOn(scheduler)
    }

    /// 检测图片是否可翻译
    func detectImageTranslationAbility(imageKeys: [String]) -> Observable<[ImageTranslationAbility]> {
        var request = Im_V1_DetectImagesLanguageRequest()
        request.imageKeys = imageKeys
        return client.sendAsyncRequest(request) { (response: Im_V1_DetectImagesLanguageResponse) -> [ImageTranslationAbility] in
            return response.imagesTranslationAbility
        }.subscribeOn(scheduler)
    }

    /// 翻译图片
    func translateImages(entityId: String?,
                         entityType: EntityType?,
                         translateScene: Im_V1_ImageTranslateScene,
                         imageKeyInfos: [String: Bool],
                         targetLanguage: String?) -> Observable<TranslateImageKeysResponse> {
        var request = Im_V1_TranslateImageKeysRequest()
        if let entityId = entityId {
            request.entityID = entityId
        }
        if let entityType = entityType {
            switch entityType {
            case .message:
                request.entityType = .messageEntity
            case .other:
                request.entityType = .unknownEntity
            }
        }

        request.scene = translateScene

        if let targetLanguage = targetLanguage {
            request.targetLanguage = targetLanguage
        }
        var infos: [Im_V1_ImageKeyInfo] = []
        for (imageKey, isOrigin) in imageKeyInfos {
            var info = Im_V1_ImageKeyInfo()
            info.imageKey = imageKey
            info.isOrigin = isOrigin
            infos.append(info)
        }
        request.imageKeysInfo = infos
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 通过实体和译图信息换取原图信息
    func getOriginImageContext(entityId: String,
                               entityType: EntityType,
                               translateImageKey: String) -> Observable<GetOriginImageContextResponse> {
        var request = Im_V1_GetTranslateOriginImageRequest()
        request.entityID = entityId
        switch entityType {
        case .message:
            request.entityType = .messageEntity
        case .other:
            request.entityType = .unknownEntity
        }
        request.translateImageKey = translateImageKey
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 发送翻译反馈
    func sendTranslateFeedback(scene: RustPB.Ai_V1_TranslationScene,
                               score: Int,
                               originText: String,
                               targetText: String,
                               hasSuggestText: Bool,
                               suggestText: String,
                               editSuggestText: Bool,
                               originLanguage: String,
                               targetLanguage: String,
                               objectID: String? = nil) -> Observable<Void> {
        var request = RustPB.Ai_V1_PutTranslationFeedbackRequest()
        request.scene = scene
        if let messageID = objectID {
            request.objectID = messageID
        } else {
            // 客户端自己生成id
            request.objectID = UUID().uuidString
        }
        request.score = Int32(score)
        request.originText = originText
        request.targetText = targetText
        request.hasSuggestedText_p = hasSuggestText
        request.suggestedText = suggestText
        request.editedSuggestedText = editSuggestText
        request.originLanguage = originLanguage
        request.targetLanguage = targetLanguage
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
}
