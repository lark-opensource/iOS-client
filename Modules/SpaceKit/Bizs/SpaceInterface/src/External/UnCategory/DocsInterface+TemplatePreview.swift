//
//  DocsInterface+TemplatePreview.swift
//  SpaceInterface
//
//  Created by huayufan on 2022/12/13.
//

import EENavigator

public struct TemplatePreviewBody: PlainBody {
    public static let pattern = "//client/docs/open_doc_template"

    public enum TemplateSource: String {
        case imGuide = "im_new_group_guide"
    }

    public var chatId: String = ""
    public var action: String = ""
    public var objType: Int = 0
    public var objToken: String = ""
    public var templateSource: String = ""
    public var templateId: String = ""
    public weak var fromVC: UIViewController?
    
    /// DocComponent 场景ID
    public var dcSceneId: String?
//    /// 生命周期回调
    public weak var selectedDelegate: TemplateSelectedDelegate?
    /// 选择模板配置
    public var templatePageConfig: TemplatePageConfig?

    public var enumSource: TemplateSource? {
        return TemplateSource(rawValue: templateSource)
    }
    
    enum CodingKeys: String, CodingKey {
        case chatId
        case action
        case objType
        case objToken
        case objTypeValue
        case templateSource
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(action, forKey: .action)
        try container.encode(objType, forKey: .objTypeValue)
        try container.encode(objToken, forKey: .objToken)
        try container.encode(templateSource, forKey: .templateSource)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chatId = (try? container.decodeIfPresent(String.self, forKey: .chatId)) ?? ""
        action = (try? container.decodeIfPresent(String.self, forKey: .action)) ?? ""
        objType = (try? container.decodeIfPresent(Int.self, forKey: .objTypeValue)) ?? 0
        objToken = (try? container.decodeIfPresent(String.self, forKey: .objToken)) ?? ""
        templateSource = (try? container.decodeIfPresent(String.self, forKey: .templateSource)) ?? ""
    }
    
    public init(parameters: [String: Any], fromVC: UIViewController) {
        self.fromVC = fromVC
        // 解析一级分类
        if let chatId = parameters["chatId"] as? String {
            self.chatId = chatId
        }

        if let action = parameters["action"] as? String {
            self.action = action
        }

        if let objTypeValue = parameters["objTypeValue"] as? String,
           let objType = Int(objTypeValue) {
            self.objType = objType
        } else if let objTypeValue = parameters["objTypeValue"] as? Int {
            self.objType = objTypeValue
        }

        if let objToken = parameters["objToken"] as? String {
            self.objToken = objToken
        }

        if let templateSource = parameters["templateSource"] as? String {
            self.templateSource = templateSource
        }
        if let templateId = parameters["templateId"] as? String {
            self.templateId = templateId
        }
    }
}
