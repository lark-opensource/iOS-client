//
//  Data+ImageFileFormat.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/20.
//

import Foundation

extension ImageWrapper where Base: DataProtocol, Base.Index == Int {

    /// 图片文件格式
    ///
    /// 线程安全，通过读取 Data 头部特征判断格式，几乎不耗时
    ///
    /// [List of file signatures - Wikipedia](https://en.wikipedia.org/wiki/List_of_file_signatures)
    public var imageFileFormat: ImageFileFormat {

        // .gif
        if compare([0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) { return .gif }
        if compare([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) { return .gif }

        // .jpg .jpeg .jfif
        if compare([0xFF, 0xD8, 0xFF]) { return .jpeg }
        // .jp2
        if compare([0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50, 0x20, 0x20, 0x0D, 0x0A, 0x87, 0x0A]) { return .jpeg }
        // .j2c
        if compare([0xFF, 0x4F, 0xFF, 0x51]) { return .jpeg }

        // .png
        if compare([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return .png }

        // .webp
        if compare([0x52, 0x49, 0x46, 0x46, nil, nil, nil, nil, 0x57, 0x45, 0x42, 0x50]) { return .webp }

        // http://nokiatech.github.io/heif/technical.html
        if compare([0x66, 0x74, 0x79, 0x70], offset: 4) {
            // .heif .heifs
            if compare([0x6D, 0x69, 0x66, 0x31], offset: 8) { return .heif }
            if compare([0x6D, 0x73, 0x66, 0x31], offset: 8) { return .heif }

            // .heic
            if compare([0x68, 0x65, 0x69, 0x63], offset: 8) { return .heic }
            if compare([0x68, 0x65, 0x69, 0x78], offset: 8) { return .heic }
            if compare([0x68, 0x65, 0x76, 0x63], offset: 8) { return .heic }
            if compare([0x68, 0x65, 0x76, 0x78], offset: 8) { return .heic }
        }

        // .bmp .dib
        if compare([0x42, 0x4D]) { return .bmp }

        // .ico
        if compare([0x00, 0x00, 0x01, 0x00]) { return .ico }
        // .cur
        if compare([0x00, 0x00, 0x02, 0x00]) { return .ico }

        // .tif .tiff
        if compare([0x49, 0x49, 0x2A, 0x00]) { return .tiff }
        if compare([0x4D, 0x4D, 0x00, 0x2A]) { return .tiff }

        // .icns
        if compare([0x69, 0x63, 0x6E, 0x73]) { return .icns }

        return .unknown
    }

    private func compare(_ bytes: [UInt8?], offset: Int = 0) -> Bool {
        guard bytes.count + offset < base.count else { return false }
        let result = zip(bytes.indices, bytes).allSatisfy { index, byte in
            guard let byte = byte else { return true }
            return base[index + offset] == byte
        }
        return result
    }
}
