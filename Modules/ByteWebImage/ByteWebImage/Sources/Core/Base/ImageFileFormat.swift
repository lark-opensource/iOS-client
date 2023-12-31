//
//  ImageFileFormat.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/18.
//

import Foundation

/// 图片文件格式
public struct ImageFileFormat {

    /// 创建初始化类型
    /// - Parameters:
    ///   - identifier: Uniform Type Identifier (UTI)
    ///   - displayName: 展示用名称
    public init(_ identifier: String, displayName: String = "unknown") {
        self.identifier = identifier
        self.displayName = displayName
    }

    /// Uniform Type Identifier (UTI)
    public private(set) var identifier: String

    /// 展示用名称
    public private(set) var displayName: String
}

extension ImageFileFormat: Equatable, Hashable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension ImageFileFormat: Codable {
    private enum CodingKeys: String, CodingKey {
        case identifier = "identifier"
        case displayName = "display_name"
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(displayName, forKey: .displayName)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.displayName = try container.decode(String.self, forKey: .displayName)
    }
}

extension ImageFileFormat: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        displayName
    }

    public var debugDescription: String {
        displayName
    }
}

extension ImageFileFormat {

    /// Not Support
    public static let unknown = ImageFileFormat("")

    /// Graphics Interchange Format
    /// .gif
    public static let gif = ImageFileFormat("com.compuserve.gif", displayName: "gif")

    /// Joint Photographic Experts Group
    /// .jpg .jpeg .jfif .jp2 .j2c
    public static let jpeg = ImageFileFormat("public.jpeg", displayName: "jpeg")

    /// Portable Network Graphics
    /// .png
    public static let png = ImageFileFormat("public.png", displayName: "png")

    /// Web Picture
    /// .webp
    public static let webp = ImageFileFormat("org.webmproject.webp", displayName: "webp")

    /// High Efficiency Image File Format
    /// .heif .heifs
    public static let heif = ImageFileFormat("public.heif", displayName: "heif")

    /// High Efficiency Image Coding
    /// .heic
    public static let heic = ImageFileFormat("public.heic", displayName: "heic")

    /// Bitmap file
    /// .bmp .dib
    public static let bmp = ImageFileFormat("com.microsoft.bmp", displayName: "bmp")

    /// Microsoft Icon
    /// .ico .cur
    public static let ico = ImageFileFormat("com.microsoft.ico", displayName: "ico")

    /// Tagged Image File Format
    /// .tif .tiff
    public static let tiff = ImageFileFormat("public.tiff", displayName: "tiff")

    /// Apple Icon
    /// .icns
    public static let icns = ImageFileFormat("com.apple.icns", displayName: "icns")
}
