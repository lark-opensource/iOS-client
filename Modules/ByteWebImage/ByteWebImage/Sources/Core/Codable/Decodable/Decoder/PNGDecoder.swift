//
//  PNGDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/22.
//

import Foundation

/// Portable Network Graphics
public enum PNG {

    /// 解码器
    public final class Decoder: ImageIODecoder, ImageIODecoderAnimatable {

        public var config = ImageDecoderConfig()

        public init() {}

        public var supportAnimation: Bool {
            true
        }

        public var imageFileFormat: ImageFileFormat { .png }

        public var kImagePropertyDictionary: String {
            kCGImagePropertyPNGDictionary as String
        }

        public var kImagePropertyDelayTime: String {
            kCGImagePropertyAPNGDelayTime as String
        }

        public var kImagePropertyUnclampedDelayTime: String {
            kCGImagePropertyAPNGUnclampedDelayTime as String
        }

        public var kImagePropertyLoopCount: String {
            kCGImagePropertyAPNGLoopCount as String
        }
    }
}
