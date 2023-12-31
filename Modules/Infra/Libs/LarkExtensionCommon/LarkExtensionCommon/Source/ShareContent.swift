//
//  ShareContent.swift
//  LarkExtensionCommon
//
//  Created by K3 on 2018/7/3.
//  Copyright © 2018年 bytedance. All rights reserved.
//

import UIKit
import Foundation

public enum ShareContentType: Int, Codable {
    case text
    case image
    case fileUrl
    case movie
    case multiple
}

public enum ShareTagetType: Int, Codable {
    case myself
    case friend
    case toutiaoquan
    case eml
}

public final class ShareContent: Codable {
    public var targetType: ShareTagetType
    public var contentType: ShareContentType
    public var contentData: Data

    public init(targetType: ShareTagetType, contentType: ShareContentType, contentData: Data) {
        self.targetType = targetType
        self.contentType = contentType
        self.contentData = contentData
    }

    public func data() -> Data? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return data
    }

    public convenience init?(_ data: Data) {
        guard let new: ShareContent = try? JSONDecoder().decode(ShareContent.self, from: data) else {
            return nil
        }
        self.init(targetType: new.targetType, contentType: new.contentType, contentData: new.contentData)
    }
}

public protocol ShareItemProtocol: Codable {
    func toJSONData() -> Data?
    init?(_ jsonData: Data)
}

public extension ShareItemProtocol {
    func toJSONData() -> Data? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return data
    }

    init?(_ jsonData: Data) {
        guard let new: Self = try? JSONDecoder().decode(Self.self, from: jsonData) else {
            return nil
        }
        self = new
    }
}

public final class ShareTextItem: ShareItemProtocol {
    public fileprivate(set) var text: String
    public init(text: String) {
        self.text = text
    }
}

public final class ShareImageItem: ShareItemProtocol {
    public fileprivate(set) var images: [URL]
    public init(images: [URL]) {
        self.images = images
    }
}

public final class ShareFileItem: ShareItemProtocol {
    public var url: URL
    public var name: String
    public init(url: URL, name: String) {
        self.url = url
        self.name = name
    }
}

public final class ShareMovieItem: ShareItemProtocol {
    public fileprivate(set) var url: URL
    public fileprivate(set) var movieSize: CGSize?
    public fileprivate(set) var isFallbackToFile: Bool
    public fileprivate(set) var name: String
    public fileprivate(set) var duration: TimeInterval
    public init(url: URL,
                isFallbackToFile: Bool,
                name: String,
                duration: TimeInterval,
                movieSize: CGSize?) {
        self.url = url
        self.isFallbackToFile = isFallbackToFile
        self.name = name
        self.movieSize = movieSize
        self.duration = duration
    }
}

public final class ShareMultipleItem: ShareItemProtocol {
    public var imageItem: ShareImageItem
    public var fileItems: [ShareFileItem]
    public init(imageItem: ShareImageItem, fileItems: [ShareFileItem]) {
        self.imageItem = imageItem
        self.fileItems = fileItems
    }
}
