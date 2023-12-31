//
//  TemplateAPI+Select.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/6/10.
//  选择模板相关API及定义


import Foundation

/// 模板选择Delegate
public protocol TemplateSelectedDelegate: AnyObject {
    
    /// 选择模板回调，仅在userTemplateType=.template时生效
    /// - Parameter item: 模板
    func templateOnItemSelected(_ viewController: UIViewController, item: TemplateItem)
    
    /// 创建文档回调，仅在userTemplateType=.create或createAndOpen时生效
    /// - Parameters:
    ///   - url: 文档url
    ///   - token: 文档token
    ///   - type: 文档类型
    ///   - error: 创建Error
    func templateOnCreateDoc(url: String?, token: String?, type: DocsType?, error: Error?)
    
    /// 传递模板页的事件
    func templateOnEvent(onEvent event: TemplatePageEvent)
}

/// 模板页的事件
public enum TemplatePageEvent: CustomStringConvertible {
    /// 即将关闭
    case willClose(type: TemplatePageType)
    ///  导航按钮点击
    case onNavigationItemClick(item: String)
    
    public var description: String {
        //数据含有token，打印时只打印operation
        switch self {
        case .willClose(type: let type):
            return "willClose:\(type)"
        case .onNavigationItemClick(item: let item):
            return "onNavigationItemClick:\(item)"
        }
    }
}

/// 选择模板配置
public struct TemplatePageConfig {
    
    /// 使用模式方式
    public let useTemplateType: UseTemplateType
    /// 选择模板后自动Dissmiss
    public let autoDismiss: Bool
    /// 模板是否可以分享
    public let enableShare: Bool
    /// 模板选择页显示成关闭按钮
    public let showCloseButton: Bool
    /// 同UIViewController.isModalInPresentation
    public let isModalInPresentation: Bool?
    /// 显示创建空白文档Item
    public let showCreateBlankItem: Bool
    /// 点击模板Item行为
    public let clickTemplateItemType: ClickTemplateItemType
    /// 隐藏副标题
    public let hideItemSubTitle: Bool
    
    
    public init(useTemplateType: UseTemplateType,
                autoDismiss: Bool,
                enableShare: Bool = false,
                showCloseButton: Bool = false,
                isModalInPresentation: Bool? = nil,
                showCreateBlankItem: Bool = false,
                clickTemplateItemType: ClickTemplateItemType = .preview,
                hideItemSubTitle: Bool = false) {
        self.useTemplateType = useTemplateType
        self.autoDismiss = autoDismiss
        self.enableShare = enableShare
        self.showCloseButton = showCloseButton
        self.isModalInPresentation = isModalInPresentation
        self.showCreateBlankItem = showCreateBlankItem
        self.clickTemplateItemType = clickTemplateItemType
        self.hideItemSubTitle = hideItemSubTitle
    }
    
    public static let `default` = TemplatePageConfig(useTemplateType: .createAndOpen, autoDismiss: true)
}

/// 创建模板页参数
public struct CreateTemplatePageParam {
    
    /// 模板分类ID
    public let categoryId: String
    
    /// DocComponent 场景ID，从DocComponent打开时需要传入
    public let dcSceneId: String?
    
    /// 模板来源
    public let templateSource: String
    
    public var templatePageConfig: TemplatePageConfig
    
    public init(categoryId: String,
                templateSource: String,
                templatePageConfig: TemplatePageConfig,
                dcSceneId: String? = nil) {
        self.categoryId = categoryId
        self.dcSceneId = dcSceneId
        self.templateSource = templateSource
        self.templatePageConfig = templatePageConfig
    }
}

/// “使用模板”的类型
public enum UseTemplateType: Int {
    case createAndOpen //创建并打开文档
    case create       //仅创建文档但不打开，回调返回文档url
    case template      //不创建文档，仅回调返回模板
}


/// 点击模板Item类型
public enum ClickTemplateItemType {
    case preview //进入预览模板
    case select  //选中模板
}

/// 模板页类型
public enum TemplatePageType {
    /// 选择模板页
    case select
    /// 预览页
    case preview
}
