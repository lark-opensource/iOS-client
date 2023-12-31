//
//  ImageFormat.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/28.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

/// Represents image format.
///
/// - unknown: The format cannot be recognized or not supported yet.
/// - PNG: PNG image format.
/// - JPEG: JPEG image format.
/// - GIF: GIF image format.
public enum ImageFormat {
    /// The format cannot be recognized or not supported yet.
    case unknown
    /// PNG image format.
    case PNG
    /// JPEG image format.
    case JPEG
    /// GIF image format.
    case GIF
    /// webp image format
    case WEBP
    /// heif/heic image format
    case HEIF
    
    struct HeaderData {
        static var PNG: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        static var JPEG_SOI: [UInt8] = [0xFF, 0xD8]
        static var JPEG_IF: [UInt8] = [0xFF]
        static var GIF: [UInt8] = [0x47, 0x49, 0x46]
        static var WEBP: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x57, 0x45, 0x42, 0x50]
        static var HEIF: [UInt8] = [0x0, 0x0, 0x0, 0x18, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x69, 0x66, 0x31]
    }
}

extension Data: KingfisherCompatibleValue {}

// MARK: - Misc Helpers
extension KingfisherWrapper where Base == Data {
    /// Gets the image format corresponding to the data.
    public var imageFormat: ImageFormat {
        var buffer = [UInt8](repeating: 0, count: 12)
        (base as NSData).getBytes(&buffer, length: 12)
        if Array(buffer[0..<8]) == ImageFormat.HeaderData.PNG {
            return .PNG
        } else if buffer[0] == ImageFormat.HeaderData.JPEG_SOI[0] &&
            buffer[1] == ImageFormat.HeaderData.JPEG_SOI[1] &&
            buffer[2] == ImageFormat.HeaderData.JPEG_IF[0]
        {
            return .JPEG
        } else if buffer[0] == ImageFormat.HeaderData.GIF[0] &&
            buffer[1] == ImageFormat.HeaderData.GIF[1] &&
            buffer[2] == ImageFormat.HeaderData.GIF[2]
        {
            return .GIF
        } else if buffer[0] == ImageFormat.HeaderData.WEBP[0] &&
            buffer[1] == ImageFormat.HeaderData.WEBP[1] &&
            buffer[2] == ImageFormat.HeaderData.WEBP[2] &&
            buffer[3] == ImageFormat.HeaderData.WEBP[3] &&
            buffer[8] == ImageFormat.HeaderData.WEBP[4] &&
            buffer[9] == ImageFormat.HeaderData.WEBP[5] &&
            buffer[10] == ImageFormat.HeaderData.WEBP[6] &&
            buffer[11] == ImageFormat.HeaderData.WEBP[7]
        {
            return .WEBP
        } else if buffer == ImageFormat.HeaderData.HEIF {
            return .HEIF
        }
        
        return .unknown
    }
}
