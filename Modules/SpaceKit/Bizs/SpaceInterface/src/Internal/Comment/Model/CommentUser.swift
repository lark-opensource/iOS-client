//
//  CommentUser.swift
//  SKCommon
//
//  Created by huayufan on 2021/11/4.
//  


import Foundation

public struct CommentUser {
    
    public var id: String?
    public var name: String?
    public var avatarUrl: String?
    
    public var useOpenId = false
    
    enum CommentError: Error {
        case paramsInvalid
    }
    
    public init(params: [String: Any]) throws {
        guard let user = params["user"] as? [String: Any] else {
            throw CommentError.paramsInvalid
        }
        if let id = user["id"] as? String {
            self.id = id
        } else {
            throw CommentError.paramsInvalid
        }
        
        if let name = user["name"] as? String {
            self.name = name
        }
        
        if let type = user["user_id_type"] as? Int,
           type == 1 {
            self.useOpenId = true
        }
        
        if let avatarUrl = user["avatar_url"] as? String {
            self.avatarUrl = avatarUrl
        }
    }
}
