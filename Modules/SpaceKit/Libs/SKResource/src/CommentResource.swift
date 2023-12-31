//
//  CommentResource.swift
//  SKResource
//
//  Created by huayufan on 2021/7/29.
//  


public final class CommentResource {
    
    public var commentJSUrl: URL? {
        let bundle = I18n.resourceBundle
        // 命名固定
        let path = bundle.path(forResource: "comment_for_gadget", ofType: "js") ?? ""
        return URL(fileURLWithPath: path)
    }
    
    public var commentJSVersion: String? {
        return "1.0.1.71"
    }
    
    public init() {}
    
}
