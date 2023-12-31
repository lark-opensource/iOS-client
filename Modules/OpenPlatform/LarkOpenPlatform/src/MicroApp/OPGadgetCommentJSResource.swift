//
//  OPGadgetCommentJSResource.swift
//  LarkOpenPlatform
//
//  Created by baojianjun on 2023/4/23.
//

import Foundation
import RxSwift
import LarkContainer
import SpaceInterface
import LarkOpenPluginManager

final class OPGadgetCommentJSResource: NSObject, OpenJSWorkerResourceProtocol {
    
    @Injected var source: CommentResourceInterface
    
    public override init() {}
    
    public var scriptLocalUrl: URL? {
        return source.commentJSUrl
    }

    public var scriptVersion: String? {
        return source.commentJSVersion
    }
    
}
