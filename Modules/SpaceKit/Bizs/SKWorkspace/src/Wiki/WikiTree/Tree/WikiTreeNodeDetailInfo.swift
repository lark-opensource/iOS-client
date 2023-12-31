//
//  WikiTreeNodeDetailInfo.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/7/3.
//

import Foundation

public struct WikiTreeNodeDetailInfo: Decodable, Equatable {
    let ownerId: String
    var createTime: TimeInterval?
    var editTime: TimeInterval?
    var thumbnail: WikiTreeNodeDetailInfoThumbnail?

    private enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"  //是否能新建一级节点
        case createTime = "create_time"
        case editTime = "edit_time"
        case thumbnail
    }

    public init(ownerId: String) {
        self.ownerId = ownerId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ownerId = try container.decode(String.self, forKey: .ownerId)

        if let createTime = try container.decodeIfPresent(String.self, forKey: .createTime) {
            self.createTime = TimeInterval(createTime)
        }
        if let editTime = try container.decodeIfPresent(String.self, forKey: .editTime) {
            self.editTime = TimeInterval(editTime)
        }

        if let thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail),
           let thumbnailData = thumbnail.data(using: .utf8) {
            self.thumbnail = try? JSONDecoder().decode(
                WikiTreeNodeDetailInfoThumbnail.self,
                from: thumbnailData
            )
        }
    }
}

public struct WikiTreeNodeDetailInfoThumbnail: Decodable, Equatable {
    var cipherType: Int = 0
    var decryptKey: String?
    var url: String?
    var nonce: String?
    var permitted: Bool = true

    private enum CodingKeys: String, CodingKey {
        case cipherType = "cipher_type"
        case decryptKey = "decrypt_key"
        case url
        case nonce
        case permitted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cipherType = try container.decodeIfPresent(Int.self, forKey: .cipherType) ?? 0
        decryptKey = try container.decodeIfPresent(String.self, forKey: .decryptKey)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        nonce = try container.decodeIfPresent(String.self, forKey: .nonce)
        permitted = try container.decodeIfPresent(Bool.self, forKey: .permitted) ?? false
    }
    
    public var spaceThumbnailExtra: [String: Any]? {
        return [
            "type": cipherType,
            "secret": decryptKey ?? "",
            "url": url ?? "",
            "nonce": nonce ?? ""
        ]
    }
}
