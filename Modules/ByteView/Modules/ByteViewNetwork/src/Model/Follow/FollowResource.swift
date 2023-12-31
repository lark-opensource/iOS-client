//
//  FollowResource.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_FollowResource
public struct FollowResource: Equatable {
    public init(id: String, version: String, type: FollowResourceType, content: String, path: String, isEntry: Bool) {
        self.id = id
        self.version = version
        self.type = type
        self.content = content
        self.path = path
        self.isEntry = isEntry
    }

    /// 资源唯一标识符
    public var id: String

    /// 资源版本号
    public var version: String

    /// 资源的类型，如JS文件
    public var type: FollowResourceType

    /// 资源的具体内容，如压缩后的JS文本文件内容，只给端上使用
    public var content: String

    /// 资源的url，只用于rust与服务端直接
    public var path: String

    /// 是否是入口文件
    public var isEntry: Bool
}


public enum FollowResourceType: Int, Hashable {
    case unknown // = 0
    case jsType // = 1
    case jsonStringType // = 2
}
