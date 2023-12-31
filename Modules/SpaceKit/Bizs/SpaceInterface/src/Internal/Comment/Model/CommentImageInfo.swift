//
//  CommentImageInfo.swift
//  SpaceInterface
//
//  Created by huayufan on 2022/11/15.
//


import UIKit

public final class CommentImageInfo: Codable, Equatable {
    
    public init(uuid: String?, token: String?, src: String, originalSrc: String?) {
        self.uuid = uuid
        self.token = token
        self.src = src
        self.originalSrc = originalSrc
    }
    
    public static func == (lhs: CommentImageInfo, rhs: CommentImageInfo) -> Bool {
        return lhs.src == rhs.src && lhs.originalSrc == rhs.originalSrc
    }
    
    public enum CodingKeys: String, CodingKey {
        case uuid
        case token
        case src
        case originalSrc
    }
    
    public static let commentImageMaxCount: Int = 9
    public static let commentImageMaxSize: Int = 20 * 1024 * 1024
    public let uuid: String? //未上传图片生成uuid（已上传的图片为空）
    public let token: String? //完成上传的图片token（未上传的图片为空）
    public let src: String //缩略图地址(或者待上传的图片地址)
    public let originalSrc: String? //原图地址
    
    public private(set) var status: LoadingStatus = .none
    
    public enum LoadingStatus: Equatable {
        public static func == (lhs: CommentImageInfo.LoadingStatus, rhs: CommentImageInfo.LoadingStatus) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true
            case (.loading, .loading):
                return true
            case (.fail, .fail):
                return true
            case (.success, .success):
                return true
            default:
                return false
            }
        }
        
        case none
        case loading
        case fail
        case success(ImageSource)
    }

    public enum ImageSource {
        case cache(UIImage)
        case network(UIImage)
    }
    
    public func update(status: LoadingStatus) {
        self.status = status
    }
    
    public var image: UIImage? {
        if case let .success(source) = status {
            switch source {
            case let .cache(img),
                let .network(img):
                return img
            }
        }
        return nil
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)
        token = try values.decodeIfPresent(String.self, forKey: .token)
        src = try values.decodeIfPresent(String.self, forKey: .src) ?? ""
        originalSrc = try values.decodeIfPresent(String.self, forKey: .originalSrc)
    }
}
