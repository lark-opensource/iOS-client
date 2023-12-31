//
//  DocsUrlInfo.swift
//  SKCommon
//
//  Created by huangzhikai on 2022/12/28.
//

import Foundation

public final class DocsUrlInfo {
    public var docsApiPrefix: String? // 文档api
    public var frontierDomain = [String]()  // 文档使用长链
    public var unit: String? //所属mg
    public var brand: String? // 所属品牌
    
    public var srcHost: String? //原始url的域名
    public var srcUrl: String? //原始url
}
