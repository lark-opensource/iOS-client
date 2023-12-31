//
//  ThumbnailSizeUtil.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/6.
//

import Foundation

enum ThumbnailSize: CGFloat {
    case xxhight = 1280
    case xhight = 850
    case hight = 720
    case middle = 480
    case low = 360

    // 根据展示尺寸计算目标缩略图尺寸
    static func thumbSize(targetSize: CGFloat) -> CGSize {
        if (targetSize > ThumbnailSize.xhight.rawValue) {
            return CGSize(width: ThumbnailSize.xxhight.rawValue, height: ThumbnailSize.xxhight.rawValue)
        } else if (targetSize > ThumbnailSize.hight.rawValue) {
            return CGSize(width: ThumbnailSize.xhight.rawValue, height: ThumbnailSize.xhight.rawValue)
        } else if (targetSize > ThumbnailSize.middle.rawValue) {
            return CGSize(width: ThumbnailSize.hight.rawValue, height: ThumbnailSize.hight.rawValue)
        } else if (targetSize > ThumbnailSize.low.rawValue) {
            return CGSize(width: ThumbnailSize.middle.rawValue, height: ThumbnailSize.middle.rawValue)
        } else {
            return CGSize(width: ThumbnailSize.low.rawValue, height: ThumbnailSize.low.rawValue)
        }
    }

    // 判断是否为超长图: 高度 > 宽度 * 2 并且高度 > xxhight
    static func checkIsLongImage(imageSize: CGSize, webviewWith: CGFloat) -> Bool {
        guard webviewWith > 0 else { return false }
        guard imageSize.height > 0, imageSize.width > 0 else {
            return false
        }
        let displayWidth = webviewWith * UIScreen.main.scale
        let maxThumbHeight = ThumbnailSize.xxhight.rawValue
        guard imageSize.height > imageSize.width * longImageScale(), imageSize.height > maxThumbHeight else {
            return false
        }

        let scale = imageSize.width / displayWidth
        let scaleHeight = imageSize.height / scale
        return scaleHeight > maxThumbHeight
    }

    // 新增配置，后续可以灵活调整长图宽高比例
    static private func longImageScale() -> CGFloat {
        if let scale = ProviderManager.default.commonSettingProvider?.floatValue(key: "longImageScale") {
            return CGFloat(scale)
        } else {
            return 1.0
        }
    }
}

extension ThumbnailSize: CaseIterable {}
