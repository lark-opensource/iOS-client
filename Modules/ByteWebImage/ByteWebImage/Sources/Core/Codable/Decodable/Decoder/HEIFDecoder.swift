//
//  HEIFDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/27.
//

import Foundation

public enum HEIF {

    public final class Decoder: ImageIODecoder {

        public var config = ImageDecoderConfig()

        public init() {}

        public var imageFileFormat: ImageFileFormat { .heif }

        public var needSync: Bool {
            ImageConfiguration.heicSerialDecode
        }
    }
}
