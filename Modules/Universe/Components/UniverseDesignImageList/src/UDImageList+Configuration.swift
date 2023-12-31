//
//  UDImageList+Configuration.swift
//  UniverseDesignImageList
//
//  Created by 郭怡然 on 2022/9/29.
//

import UIKit
import Foundation

extension UDImageList {
    public struct Configuration {
        public var maxImageNumber: Int = 9
        public var cameraBackground: CameraBackground = .white
        public var leftRightMargin: CGFloat = 16
        public var interitemSpacing: CGFloat = 8
        public var defaultItemSize: CGFloat = 90

        /// - Parameters:
        ///   - maxImageNumber: 图片墙能显示的最大图片数
        ///   - cameraBackground: cameraCell的背景颜色
        ///   - leftRightMargin: 图片墙左右边的margin
        ///   - interitemSpacing: 图片间的间距
        ///   - defaultItemSize: 默认图片大小
        public init(maxImageNumber: Int = 9,
                    cameraBackground: CameraBackground = .white,
                    leftRightMargin: CGFloat = 16,
                    interitemSpacing: CGFloat = 8,
                    defaultItemSize: CGFloat = 90
        ) {
            if maxImageNumber <= 0 {
                assertionFailure("maxImageNumber should be a positive Integer!")
                self.maxImageNumber = 9
            } else {
                self.maxImageNumber = maxImageNumber
            }
            self.cameraBackground = cameraBackground
            self.leftRightMargin = leftRightMargin
            self.interitemSpacing = interitemSpacing
            self.defaultItemSize = defaultItemSize
        }
    }
}
