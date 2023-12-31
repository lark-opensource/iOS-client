//
//  ImageContent.swift
//  LarkModel
//
//  Created by chengzhipeng-bytedance on 2018/5/18.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public typealias Image = RustPB.Basic_V1_Image
public typealias ImageSet = RustPB.Basic_V1_ImageSet
public typealias ImageTranslationAbility = RustPB.Basic_V1_ImageTranslationAbility
public typealias TranslateImageKeysResponse = RustPB.Im_V1_TranslateImageKeysResponse
public typealias GetOriginImageContextResponse = RustPB.Im_V1_GetTranslateOriginImageResponse
public typealias ImageTranslationInfo = RustPB.Basic_V1_ImageTranslationInfo
public typealias ImageProperty = RustPB.Basic_V1_RichTextElement.ImageProperty
public typealias CompressParameters = RustPB.Media_V1_GetImageCompressParametersResponse

public struct ImageContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message

    // 固有字段
    public var image: ImageSet
    public let cryptoToken: String
    // 译图信息依赖这个结构
    public var imageTranslationInfo: Basic_V1_ImageTranslationInfo?
    public var isOriginSource: Bool
    public var originFileSize: UInt64 = 0

    public init(image: ImageSet, cryptoToken: String) {
        self.image = image
        self.cryptoToken = cryptoToken
        self.isOriginSource = false
    }

    public init(image: ImageSet, cryptoToken: String, isOriginSource: Bool, originFileSize: UInt64) {
        self.image = image
        self.cryptoToken = cryptoToken
        self.isOriginSource = isOriginSource
        self.originFileSize = originFileSize
    }

    public static func transform(pb: PBModel) -> ImageContent {
        return ImageContent(
            image: pb.content.image,
            cryptoToken: pb.content.cryptoToken,
            isOriginSource: pb.content.isOriginSource,
            originFileSize: pb.content.originSize
        )
    }

    public static func transform(pb: RustPB.Basic_V1_TranslateInfo) -> ImageContent {
        // server不会主动替换富文本中的图片节点，图片节点对应的译图信息需要端上从imageTranslationInfo取出手动替换
        let fixedKey = fixedTranslatedImageKey(originKey: pb.content.image.origin.key)
        let translatedImageSet = pb.imageTranslationInfo.translatedImages[fixedKey]?.translatedImageSet
        var content = ImageContent(
            image: translatedImageSet ?? pb.content.image,
            cryptoToken: pb.content.cryptoToken,
            isOriginSource: pb.content.isOriginSource,
            originFileSize: pb.content.originSize
        )
        content.imageTranslationInfo = pb.imageTranslationInfo
        return content
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if let translatePB = entity.translateMessages[message.id] {
            message.translateState = .translated
            message.atomicExtra.unsafeValue.translateContent = ImageContent.transform(pb: translatePB)
        }
    }

    /// server下发下来的译图信息的key是不带品质前缀的，妥协历史原因，这里需要特殊处理下
    private static func fixedTranslatedImageKey(originKey: String) -> String {
        /// 待截断的图片品质前缀范围
        let imageQualityPrefixs = ["origin:", "middle:", "thumbnail:"]
        var fixedKey = originKey
        for prefix in imageQualityPrefixs {
            fixedKey = fixedKey.replacingOccurrences(of: prefix, with: "", options: .regularExpression)
        }
        return fixedKey
    }
}
