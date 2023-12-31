//
//  SKImagePreviewStrategy.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/4.
//

import Foundation
import SKFoundation

public protocol SKImagePreviewStrategy {
    /// 生成预览图片，如果图片超出预览限制，可以返回downsample后的图片
    func imageForPreview(imagePath: SKFilePath) -> UIImage?
    /// 计算图片是否需要进行分块加载
    func needTileImage(imagePath: SKFilePath) -> Bool
}

public struct SKImagePreviewDefaultStrategy: SKImagePreviewStrategy {
    public func needTileImage(imagePath: SKFilePath) -> Bool {
        return false
    }
    
    public func imageForPreview(imagePath: SKFilePath) -> UIImage? {

        let image = try? UIImage.read(from: imagePath)
        return image
    }

    public init() {}
}
