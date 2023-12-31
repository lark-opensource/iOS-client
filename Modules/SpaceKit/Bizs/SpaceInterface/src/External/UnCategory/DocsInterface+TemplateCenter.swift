//
//  DocsInterface+TemplateCenter.swift
//  SpaceInterface
//
//  Created by Gill on 2020/3/6.
//

import EENavigator

public struct TemplateCenterBody: PlainBody {
    public static let pattern = "//client/docs/template"

    // 0 : 系统模板
    // 1 : 自定义模板
    // 2 : 企业模板
    public var templateType: Int = 0

    /// 模板中心二级分类
    public var templateCategory: Int?
    
    /// 专题id，如果传了这个参数，就跳转到指定的专题列表页
    public var topicId: Int?
    
    /// Applink 来源，如果传入了，要加到埋点里面去
    public var from: String?
    
    /// 跳转到模板中心时，这个参数表示筛选文档类型，对应DocsType的rawValue
    public var objType: Int?

    /// 创建文档，action == ‘create’
    public var action: String?
    /// 创建文档，模版token
    public var token: String?
    /// 创建文档，点击来源
    public var clickFrom: String?
    /// 创建文档, 文档类型
    public var type: Int?
    /// 创建文档, 模版国际化ID
    public var templateId: String?
    
    public var enterSource: String?
    
    public var templateSource: String?
    /// DocComponent 场景ID
    public var dcSceneId: String?
    /// 生命周期回调
    public weak var selectedDelegate: TemplateSelectedDelegate?
    /// 选择模板配置
    public var templatePageConfig: TemplatePageConfig?
    
    public init() {
        
    }

    public init(queryDict: [String: String]) {
        // 解析一级分类
        if let openTemplateCenter = queryDict["openTemplateCenter"] {
            switch openTemplateCenter {
            case "custom":
                self.templateType = 1
            case "corporate":
                self.templateType = 2
            default:
                break
            }
        }
        // 解析二级分类
        if let templateCategory = queryDict["categoryId"], let secCate = Int(templateCategory) {
            self.templateCategory = secCate
        }
        // 解析专题模板id
        if let topicIDStr = queryDict["topicId"], let topicID = Int(topicIDStr) {
            topicId = topicID
        }
        if let aFromStr = queryDict["from"] {
            from = aFromStr
        }
        if let objTypeFromLink = queryDict["objType"], let type = Int(objTypeFromLink) {
            objType = type
        }
        action = queryDict["action"]
        token = queryDict["token"]
        clickFrom = queryDict["clickfrom"]
        templateId = queryDict["template_id"]
        enterSource = queryDict["enterSource"]
        dcSceneId = queryDict["dcSceneId"]
        if let typeStr = queryDict["type"] {
            type = Int(typeStr)
        }
        
        if let templateSource = queryDict["templateSource"] {
            self.templateSource = templateSource
        }
    }
}
