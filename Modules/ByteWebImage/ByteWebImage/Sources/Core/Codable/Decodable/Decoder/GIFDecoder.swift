//
//  GIFDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/8/1.
//

import Foundation

/// Graphics Interchange Format
public enum GIF {

    public final class Decoder: ImageIODecoder, ImageIODecoderAnimatable {

        public var config = ImageDecoderConfig()

        public init() {}

        public var supportAnimation: Bool {
            true
        }

        public var imageFileFormat: ImageFileFormat { .gif }

        public var kImagePropertyDictionary: String {
            kCGImagePropertyGIFDictionary as String
        }

        public var kImagePropertyDelayTime: String {
            kCGImagePropertyGIFDelayTime as String
        }

        public var kImagePropertyUnclampedDelayTime: String {
            kCGImagePropertyGIFUnclampedDelayTime as String
        }

        public var kImagePropertyLoopCount: String {
            kCGImagePropertyGIFLoopCount as String
        }
    }
}
