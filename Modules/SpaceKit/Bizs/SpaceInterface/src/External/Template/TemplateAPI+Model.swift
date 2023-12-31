//
//  TemplateAPI+Model.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/6/10.
//  


import Foundation

/// 从模板创建文档的标题参数
public struct CreateDocTitleParams {
    /// 文档标题
    public let title: String?
    /// 文档标题前缀
    public let titlePrefix: String?
    /// 文档标题后缀
    public let titleSuffix: String?
    
    public init(title: String? = nil, titlePrefix: String? = nil, titleSuffix: String? = nil) {
        self.title = title
        self.titlePrefix = titlePrefix
        self.titleSuffix = titleSuffix
    }
}

/// 模板分类
public final class TemplateCategoryPageInfo {
    public let categoryId: String
    public let hasMore: Bool
    public let pageIndex: Int
    public let templates: [TemplateItem]
    public init(categoryId: String, templates: [TemplateItem], pageIndex: Int, hasMore: Bool) {
        self.hasMore = hasMore
        self.pageIndex = pageIndex
        self.templates = templates
        self.categoryId = categoryId
    }
}


/// 模板Item  (字段按需增加)
public struct TemplateItem {
    
    public let id: String
    public let name: String
    public let objToken: String
    public let objType: Int
    
    public init(id: String, name: String, objToken: String, objType: Int) {
        self.id = id
        self.name = name
        self.objToken = objToken
        self.objType = objType
    }
}

/// 模板API通用错误
public enum TemplateAPIError: Error {
    case parseDataError
    case permissionError
    case runtimeError
}

