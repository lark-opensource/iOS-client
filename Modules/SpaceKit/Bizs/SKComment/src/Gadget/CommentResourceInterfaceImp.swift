//
//  CommentResourceInterfaceImp.swift
//  SKComment
//
//  Created by huangzhikai on 2023/4/23.
//

import Foundation
import SpaceInterface
import SKResource

public class CommentResourceInterfaceImp: CommentResourceInterface {
    
    private let source = CommentResource()
    
    public init() {}
    
    public var commentJSUrl: URL? {
        return source.commentJSUrl
    }

    public var commentJSVersion: String? {
        return source.commentJSVersion
    }
}
