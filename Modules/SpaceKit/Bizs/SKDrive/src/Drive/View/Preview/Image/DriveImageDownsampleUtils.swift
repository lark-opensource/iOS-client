//
//  DriveImageDownsampleUtils.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/8/29.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation

class DriveImageDownsampleUtils {
    private static let SacleMaxSize: CGFloat = 64
    /// 50M 超过 50M 进行 downSample
    static func defaultImageMaxSize(for windowSize: CGSize,
                                    scale: CGFloat = SKDisplay.scale) -> CGFloat {
        return max(windowSize.width, windowSize.height) * scale
    }
    static func needTileImage(imagePath: SKFilePath) -> Bool {
        return SKImagePreviewUtils.imageOverSize(imagePath: imagePath) && !imageSizeOverLimited(imagePath: imagePath)
    }

    static func needDownsample(imagePath: SKFilePath) -> Bool {
        return SKImagePreviewUtils.imageOverSize(imagePath: imagePath)
    }
    
    // 超出分块加载限制，当前屏幕分辨率的50倍
    static func imageSizeOverLimited(imagePath: SKFilePath) -> Bool {
        guard let size = SKImagePreviewUtils.originSizeOfImage(path: imagePath) else { return false }
        let screenSize = SKDisplay.mainScreenBounds.size
        let scale = SKDisplay.scale
        let limited = screenSize.width * screenSize.height * scale * scale * DriveImageDownsampleUtils.SacleMaxSize
        return size.width * size.height > limited
    }
}
