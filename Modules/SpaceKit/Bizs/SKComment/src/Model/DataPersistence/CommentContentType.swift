//
//  CommentContentType.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/4/1.
//  

import Foundation
import SpaceInterface

public struct CommentStoreContent: Codable {
    public let id: String
    public let contentText: String?
    public let imageInfos: [CommentImageInfo]?

    public init(id: String, contentText: String?, imageInfos: [CommentImageInfo]?) {
        self.id = id
        self.contentText = contentText
        self.imageInfos = imageInfos
    }
}
