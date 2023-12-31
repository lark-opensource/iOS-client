//
//  TemplateCollection.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/5/29.
//  


import Foundation

public final class TemplateCollection: Codable {
    let id: String
    let name: String
    var templates: [TemplateModel]
    let appLink: String? // 若为生态模板，点击通过applink跳转。普通套组模板返回为空
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case templates = "template_collection"
        case appLink = "app_link"
    }
    
    public init(id: String,
                name: String,
                templates: [TemplateModel],
                appLink: String?) {
        self.id = id
        self.name = name
        self.templates = templates
        self.appLink = appLink
    }
}
