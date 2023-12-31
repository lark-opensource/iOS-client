//
//  WebPDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/25.
//

import Foundation

extension WebP {

    public enum Encoder {

        /// 根据图像生成WebP数据
        /// - Parameters:
        ///   - image: 图像
        ///   - quality: 质量(0-100，0最低，100最佳)
        public static func data(image: CGImage, quality: Float) -> Data? {
            EncoderWebpBridge.encode(withImageRef: image, quality: max(min(quality, 100), 0))
        }
    }
}
