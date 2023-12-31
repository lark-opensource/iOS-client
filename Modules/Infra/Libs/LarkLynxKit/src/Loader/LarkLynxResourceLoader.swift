//
//  LarkLynxResourceLoader.swift
//  LarkLynxKit
//
//  Created by bytedance on 2023/3/23.
//

import Foundation

public struct LarkLynxTemplateInfo {
    // Lynx 模板数据
    public let templateData: Data
    // Lynx 文件路径，埋点用
    public var filePath: String?
    // Lynx 模板资源版本，埋点用
    public var version: String?
    // 由哪一个 loader 加载，埋点用
    public var loaderID: String?
}

// 实现根据 templatePath 获取 TemplateModel 的具体加载逻辑
public protocol LarkLynxResourceLoader {
    typealias LoaderCompletion = (Result<LarkLynxTemplateInfo, Error>) -> Void
    // 核心的加载资源逻辑，业务方需要构造好 Lynx 页面所需的资源
    func load(templatePath: String, completion: @escaping LoaderCompletion)
}
