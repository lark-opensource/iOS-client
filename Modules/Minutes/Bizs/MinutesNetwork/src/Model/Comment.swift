//
//  Comment.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/2.
//

import Foundation

public struct Comment: Codable {

    public let uuid: String
    public let quote: String
    public var contents: [CommentContent]
    public let createTime: Int
    public let updateTime: Int
    public let id: String

    public init(uuid: String, quote: String, contents: [CommentContent], createTime: Int, updateTime: Int, id: String) {
        self.uuid = uuid
        self.quote = quote
        self.contents = contents
        self.createTime = createTime
        self.updateTime = updateTime
        self.id = id
    }

    private enum CodingKeys: String, CodingKey {
        case uuid = "uuid"
        case quote = "quote"
        case contents = "comment_content_list"
        case createTime = "create_time"
        case updateTime = "update_time"
        case id = "comment_id"
    }
}

public struct CommentImageAttr: Codable {
    public let key: String
    public let fsUnit: String
    public let width: Int32?
    public let height: Int32?
    
    public init(key: String, fsUnit: String, width: Int32, height: Int32) {
        self.key = key
        self.fsUnit = fsUnit
        self.width = width
        self.height = height
    }
    
    private enum CodingKeys: String, CodingKey {
        case key = "key"
        case fsUnit = "fs_unit"
        case width = "width"
        case height = "height"
    }
}

public struct CommentImageCipher: Codable {
    public let secret: String
    public let nonce: String
    
    public init(secret: String, nonce: String) {
        self.secret = secret
        self.nonce = nonce
    }
    
    private enum CodingKeys: String, CodingKey {
        case secret = "secret"
        case nonce = "nonce"
    }
}

public struct CommentImageCrypto: Codable {
    public let type: Int32
    public let cipher: CommentImageCipher
    
    public init(type: Int32, cipher: CommentImageCipher) {
        self.type = type
        self.cipher = cipher
    }
    
    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case cipher = "cipher"
    }
}

public struct CommentForIMFileIconMata: Codable {
    public let type: Int64?
    public let key: String?
    public let objType: Int64?
    public let fileType: String?
    
    public init(type: Int64, key: String, objType: Int64, fileType:String) {
        self.type = type
        self.key = key
        self.objType = objType
        self.fileType = fileType
    }
    
    private enum CodingKeys: String, CodingKey {
        case type = "type"
        case key = "key"
        case objType = "obj_type"
        case fileType = "file_type"
    }
    
}


public struct CommentForIMFileIcon: Codable {
    public let iconInfo: CommentForIMFileIconMata?
    public let iconUri: String?
    
    public init(iconInfo: CommentForIMFileIconMata?, iconUri: String) {
        self.iconInfo = iconInfo
        self.iconUri = iconUri
    }
    
    private enum CodingKeys: String, CodingKey {
        case iconInfo = "iconInfo"
        case iconUri = "iconUri"
    }
    
}

public struct ContentForIMItemAttr: Codable {
    public let messageId: String?
    public let crypto: CommentImageCrypto?
    public let type: String?
    public let token: String?
    public let key: String?
    public let href: String?
    public let origin: CommentImageAttr?
    public let thumbnail: CommentImageAttr?
    public let docsType: Int32?
    public let iconInfo: CommentForIMFileIcon?
    
    public init(type: String, token: String, key: String, messageId: String, crypto: CommentImageCrypto?, origin: CommentImageAttr?, thumbnail: CommentImageAttr?, href: String, docsType: Int32, iconInfo: CommentForIMFileIcon?) {
        self.type = type
        self.token = token
        self.key = key
        self.messageId = messageId
        self.crypto = crypto
        self.origin = origin
        self.thumbnail = thumbnail
        self.href = href
        self.docsType = docsType
        self.iconInfo = iconInfo
    }
    
    
    private enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case crypto = "crypto"
        case type = "type"
        case token = "token"
        case key = "key"
        case href = "href"
        case origin = "origin"
        case thumbnail = "thumbnail"
        case docsType = "docs_type"
        case iconInfo = "icon_info"
    }
}

public struct ContentForIMItem: Codable {
    public let contentType: String
    public let content: String
    public let attr: ContentForIMItemAttr?
    
    public init(contentType: String, content: String, attr: ContentForIMItemAttr?) {
        self.contentType = contentType
        self.content = content
        self.attr = attr
    }
    
    private enum CodingKeys: String, CodingKey {
        case contentType = "content_type"
        case content = "text_content"
        case attr = "attr"
    }
    
}

public struct CommentContent: Codable {

    public let avatarUrl: String
    public let userID: String
    public let userName: String
    public let content: String
    public let contentForIM: [ContentForIMItem]?
    public let createTime: Int
    public let updateTime: Int
    public let id: String

    public init(avatarUrl: String, userID: String, userName: String, content: String, contentForIM: [ContentForIMItem]?, createTime: Int, updateTime: Int, id: String) {
        self.avatarUrl = avatarUrl
        self.userID = userID
        self.userName = userName
        self.content = content
        self.contentForIM = contentForIM
        self.createTime = createTime
        self.updateTime = updateTime
        self.id = id
    }

    private enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case userID = "user_id"
        case userName = "user_name"
        case content = "content"
        case createTime = "create_time"
        case updateTime = "update_time"
        case id = "content_id"
        case contentForIM = "content_for_im"
    }
}
