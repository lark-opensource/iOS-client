//
//  CommentDraft-Model.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/16.
// swiftlint:disable pattern_matching_keywords


import Foundation

// MARK: 评论草稿图片

/// 评论草稿图片
public struct CommentDraftImage: Codable {
    public let uuid: String?           // 未上传图片生成uuid（已上传的图片为空）
    public let token: String?          // 完成上传的图片token（未上传的图片为空）
    public let source: String          // 缩略图地址(或者待上传的图片地址)
    public let originSrc: String?      // 原图地址
    
    public enum CodingKeys: CodingKey {
        case uuid, token, source, originSrc
    }
    
    public init(from: CommentImageInfo) {
        self.uuid = from.uuid
        self.token = from.token
        self.source = from.src
        self.originSrc = from.originalSrc
    }
    
    public func lagacyModel() -> CommentImageInfo {
        CommentImageInfo(uuid: uuid,
                         token: token,
                         src: source,
                         originalSrc: originSrc)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)
        token = try values.decodeIfPresent(String.self, forKey: .token)
        source = try values.decodeIfPresent(String.self, forKey: .source) ?? ""
        originSrc = try values.decodeIfPresent(String.self, forKey: .originSrc)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(token, forKey: .token)
        try container.encode(source, forKey: .source)
        try container.encode(originSrc, forKey: .originSrc)
    }
}

// MARK: 评论草稿 Model

/// 评论草稿
public struct CommentDraftModel: Codable, CustomDebugStringConvertible {
    
    public enum OriginFromType: Int { // 原始来源，有值则上报时当做无草稿
        case edit = 1
        case reply = 2
    }
    
    public let content: String                 // 编码后的文字
    public let imageList: [CommentDraftImage]  // 图片数组
    public let originFrom: OriginFromType?     // 来源类型
    public private(set) var lastAccessTime: Int64 // 上次访问时间戳,单位秒
    
    enum CodingKeys: CodingKey {
        case content, imageList, originFrom, lastAccessTime
    }
    
    public init(content: String, imageList: [CommentDraftImage], originFrom: OriginFromType? = nil) {
        self.content = content
        self.imageList = imageList
        self.originFrom = originFrom
        self.lastAccessTime = Int64(CFAbsoluteTimeGetCurrent())
    }
    
    /// 标记一次访问 (更新访问时间)
    public mutating func markAccessed() {
        self.lastAccessTime = Int64(CFAbsoluteTimeGetCurrent())
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try values.decodeIfPresent(String.self, forKey: .content) ?? ""
        imageList = try values.decodeIfPresent([CommentDraftImage].self, forKey: .imageList) ?? []
        originFrom = OriginFromType(rawValue: (try values.decodeIfPresent(Int.self, forKey: .originFrom)) ?? 0)
        lastAccessTime = try values.decodeIfPresent(Int64.self, forKey: .lastAccessTime) ?? Int64(0)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(imageList, forKey: .imageList)
        try container.encode(originFrom?.rawValue ?? 0, forKey: .originFrom)
        try container.encode(lastAccessTime, forKey: .lastAccessTime)
    }
    
    public var debugDescription: String {
        return "\(content) | count:\(imageList.count)"
    }
}

// MARK: 评论草稿 Key

public struct CommentDraftKey: CCMTextDraftKey {
    
    public let entityId: String?    // 文档或drive的唯一标识
    public let sceneType: CommentDraftKeyScene // 评论键盘输入场景
    
    public init(entityId: String?, sceneType: CommentDraftKeyScene) {
        self.entityId = entityId
        self.sceneType = sceneType
    }
    
    public var customKey: String { // 草稿Key
        let join = "@" // 注意特殊性
        switch sceneType {
        case .newComment(let isWhole):
            return isWhole ? "new_comment_whole" : "new_comment_part"
        case .newReply(let commentId):
            return "new_reply" + join + "\(commentId)"
        case .editExisting(let commentId, let replyId):
            return "\(replyId)" + join + "\(commentId)"
        }
    }
}
