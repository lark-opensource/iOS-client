//
//  DriveCacheType.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/3/2.
//

import SKFoundation
import SpaceInterface
import SKCommon

/// 为了解决一个drive文件可能需要同时保存多种不同的预览文件，除原有的 origin/preview 外，额外提供自定义ID的类型，避免互相覆盖
/// 相似文件上下文：https://bytedance.feishu.cn/docs/doccnijDerAVs9sghKdtuGT5U7f?new_source=message
public enum DriveCacheType {
    static let originIdentifier = "origin"
    static let previewIdentifier = "preview"
    static let associateIdentifier = "associate"
    static let similarIdentifier = "similar"
    case origin
    case similar
    case preview
    case associate(customID: String)
    case unknown
    
    init(with identifier: String) {
        switch identifier {
        case Self.originIdentifier:
            self = .origin
        case Self.previewIdentifier:
            self = .preview
        case Self.similarIdentifier:
            self = .similar
        default:
            let prefix = "\(Self.associateIdentifier)-"
            if identifier.hasPrefix(prefix) {
                let customID = identifier.dropFirst(prefix.count)
                self = .associate(customID: String(customID))
            } else {
                spaceAssertionFailure("unknown cache type identifier \(identifier)")
                self = .unknown
            }
        }
    }

    static let partialPDF: DriveCacheType = .associate(customID: "partial-pdf")
    static let videoInfo: DriveCacheType = .associate(customID: "video-info")
    static let htmlExtraInfo: DriveCacheType = .associate(customID: "html-extra-info")
    static let oggInfo: DriveCacheType = .associate(customID: "ogg-info")
    static let webOfficeInfo: DriveCacheType = .associate(customID: "web-office-info")
    static func htmlSubData(id: String) -> Self {
        return .associate(customID: "html-sub-data-" + id)
    }
    static func imageCover(width: Int, height: Int) -> Self {
        return .associate(customID: "image-cover-\(width)x\(height)")
    }
    
    var customID: String? {
        switch self {
        case .origin, .preview, .similar:
            return nil
        case let .associate(customID):
            return customID
        case .unknown:
            spaceAssertionFailure("unknown cache type")
            return nil
        }
    }

    var identifier: String {
        switch self {
        case .origin:
            return Self.originIdentifier
        case .preview:
            return Self.previewIdentifier
        case .similar:
            return Self.similarIdentifier
        case let .associate(customID):
            return "\(Self.associateIdentifier)-\(customID)"
        case .unknown:
            spaceAssertionFailure("unknown cache type")
            return "unknown"
        }
    }

    var offlineAvailable: Bool {
        switch self {
        case .origin, .preview, .similar:
            return true
        case .associate:
            if self == .htmlExtraInfo {
                return true
            }
            return false
        case .unknown:
            spaceAssertionFailure("unknown cache type")
            return false
        }
    }

    init(downloadType: DocCommonDownloadType) {
        switch downloadType {
        case let .cover(width, height, _):
            self = .imageCover(width: width, height: height)
        case .image:
            //目前本地上传的图片cacheType为.similar
            self = .similar
        case .originFile:
            self = .origin
        case .previewFile:
            self = .preview
        @unknown default:
            self = .origin
            spaceAssertionFailure()
        }
    }
}

extension DriveCacheType: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension DriveCacheType: Codable {

    private enum CodingKeys: String, CodingKey {
        case baseType
        case customID
    }

    private enum BaseType: String, Codable {
        case origin
        case preview
        case similar
        case associate
        case unknown
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let baseType = try container.decode(BaseType.self, forKey: .baseType)
        switch baseType {
        case .origin:
            self = .origin
        case .preview:
            self = .preview
        case .similar:
            self = .similar
        case .associate:
            let customID = try container.decode(String.self, forKey: .customID)
            self = .associate(customID: customID)
        case .unknown:
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .origin:
            try container.encode(BaseType.origin,
                                 forKey: .baseType)
        case .preview:
            try container.encode(BaseType.preview,
                                 forKey: .baseType)
        case .associate(let customID):
            try container.encode(BaseType.associate,
                                 forKey: .baseType)
            try container.encode(customID,
                                 forKey: .customID)
        case .unknown:
            try container.encode(BaseType.unknown,
                                 forKey: .baseType)
        case .similar:
            try container.encode(BaseType.similar,
                                 forKey: .baseType)
        }
    }
}
