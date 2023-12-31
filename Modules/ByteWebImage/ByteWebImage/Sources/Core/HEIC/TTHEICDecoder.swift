//
//  TTHEICDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2023/2/14.
//

import Foundation

extension HEIC {

    public final class TTDecoder: LibHEIFDecoder {

        public var config = ImageDecoderConfig()

        public init() {}

        public var imageFileFormat: ImageFileFormat { .heic }
    }
}
