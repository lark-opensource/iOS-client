//
//  ICNSDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/8/2.
//

import Foundation

public enum ICNS {

    public final class Decoder: ImageIODecoder {

        public var config = ImageDecoderConfig()

        public init() {}

        public var imageFileFormat: ImageFileFormat { .icns }
    }
}
