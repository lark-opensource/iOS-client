//
//  CommentCacheInterface.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/31.
//  


import Foundation

public protocol CommentImageCacheInterface {
    func getImage(byKey key: String, token: String?) -> NSCoding?
    func getAssetWith(fileTokens: [String]) -> [SKAssetInfo]
}

public protocol CommentSubScribeCacheInterface {
    func getCommentSubScribe(encryptedToken: String) -> Bool
    func setCommentSubScribe(_ isSubscribe: Bool, _ encryptedToken: String)
}
