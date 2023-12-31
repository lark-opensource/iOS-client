//
//  Data+LarkFoundation.swift
//  LarkFoundation
//
//  Created by ChalrieSu on 08/03/2018.
//  Copyright © 2018 com.bytedance.lark. All rights reserved.
//

import Foundation
import LarkCompatible

extension Data: LarkFoundationExtensionCompatible {}

extension LarkFoundationExtension where BaseType == Data {
    public func fileFormat() -> FileFormat {
        for typeData in HeaderData.typeDatas {
            if self.base.count < typeData.offset + typeData.data.count {
                continue
            }
            var buffer = [UInt8](repeating: 0, count: typeData.data.count)
            (self.base as NSData).getBytes(&buffer, range: NSRange(location: typeData.offset, length: typeData.data.count))

            if !typeData.data.enumerated().contains(where: { (idx, byte) -> Bool in
                return byte != nil && byte != buffer[idx]
            }) {
                return typeData.format
            }
        }
        return .unknown
    }
}

extension LarkFoundationExtension where BaseType == String {
    public func mimeType() -> String {
        return MimeType.mimeType(ext: (self.base as NSString).pathExtension)
    }

    // swiftlint:disable cyclomatic_complexity
    public func fileFormat() -> FileFormat {
        let pathExtension: String = (self.base as NSString).pathExtension.lowercased()

        var format = FileFormat.unknown

        switch pathExtension {
        case "txt", "text":
            format = .txt
        case "md":
            format = .md
        case "html":
            format = .html
        case "json", "JSON":
            format = .json
        case "pdf":
            format = .pdf
        case "rtf":
            format = .rtf
        case "png", "jpeg", "gif", "flif", "webp", "bmp", "tif", "svg":
            if let imageFormat = ImageFormat(rawValue: pathExtension) {
                format = .image(imageFormat)
            }
        case "mp3", "m4a", "opus", "ogg", "flac", "amr", "wav", "aac", "au":
            if let audioFormat = AudioFormat(rawValue: pathExtension) {
                format = .audio(audioFormat)
            }
        case "avi", "mpeg4", "wmv", "mpg", "flv":
            if let videoFormat = VideoFormat(rawValue: pathExtension) {
                format = .video(videoFormat)
            }
        case "doc", "docx":
            format = .office(.doc)
        case "ppt", "pptx":
            format = .office(.ppt)
        case "xls", "xlsx":
            format = .office(.xls)
        case "key":
            format = .appleOffice(.key)
        case "numbers":
            format = .appleOffice(.numbers)
        case "pages":
            format = .appleOffice(.pages)
        default:
            break
        }
        return format
    }
    // swiftlint:enable cyclomatic_complexity
}
