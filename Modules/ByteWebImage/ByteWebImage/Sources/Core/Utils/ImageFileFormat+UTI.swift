//
//  ImageFileFormat+UTI.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/18.
//

import Foundation
import UniformTypeIdentifiers

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension ImageFileFormat {

    /// 使用 UTI 初始化
    /// - Parameter UTI: Uniform Type Identifiers
    public init(from UTI: UTType) {
        switch UTI {
        case .gif:
            self = .gif
        case .jpeg:
            self = .jpeg
        case .png:
            self = .png
        case .webP:
            self = .webp
        case .heif:
            self = .heif
        case .heic:
            self = .heic
        case .bmp:
            self = .bmp
        case .ico:
            self = .ico
        case .tiff:
            self = .tiff
        case .icns:
            self = .icns
        default:
            self = .unknown
        }
    }
}

import CoreServices
@available(iOS, deprecated: 15.0, message: "Use init(from:) instead.")
public extension ImageFileFormat {

    /// 使用 UTI 初始化
    /// - Parameter UTI: Uniform Type Identifiers
    init(from UTI: CFString) {
        switch UTI {
        case kUTTypeGIF:
            self = .gif
        case kUTTypeJPEG, kUTTypeJPEG2000:
            self = .jpeg
        case kUTTypePNG:
            self = .png
        case kUTTypeWebP:
            self = .webp
        case kUTTypeHEIF:
            self = .heif
        case kUTTypeHEIC:
            self = .heic
        case kUTTypeBMP:
            self = .bmp
        case kUTTypeICO:
            self = .ico
        case kUTTypeTIFF, kUTTypeRAW:
            self = .tiff
        case kUTTypeAppleICNS:
            self = .icns
        default:
            self = .unknown
        }
    }
}

@available(iOS, deprecated: 15.0, message: "Use UTType.webP instead.")
public let kUTTypeWebP = "org.webmproject.webp" as CFString

@available(iOS, deprecated: 15.0, message: "Use UTType.heif instead.")
public let kUTTypeHEIF = "public.heif" as CFString

@available(iOS, deprecated: 15.0, message: "Use UTType.heic instead.")
public let kUTTypeHEIC = "public.heic" as CFString

public let kUTTypeRAW = "com.adobe.raw-image" as CFString
