//
//  CommentAPIContent.swift
//  SKComment
//
//  Created by huayufan on 2023/3/30.
//  


import SpaceInterface
import SKFoundation

extension CommentAPIContent {
    
    mutating func update(key: APIKey, value: Any) {
        params[key.rawValue] = value
    }
    
    mutating func update(params: [APIKey: Any]) {
        for (key, value) in params {
            self.params[key.rawValue] = value
        }
    }
    
    public mutating func set(_ callback: @escaping CommentResponseType) {
        self.resonse = callback
    }
}
