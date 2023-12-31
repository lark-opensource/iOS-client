//
//  TTHEIFDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2023/2/21.
//

import Foundation

extension HEIF {

    public final class TTDecoder: LibHEIFDecoder {

        public var config = ImageDecoderConfig()

        public init() {}

        public var imageFileFormat: ImageFileFormat { .heif }
    }
}
