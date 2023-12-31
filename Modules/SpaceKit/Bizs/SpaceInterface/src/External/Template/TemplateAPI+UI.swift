//
//  TemplateAPI+UI.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/6/10.
//  模板UI相关API及定义


import Foundation


//水平模板列表View
public protocol TemplateHorizontalListViewProtocol: UIView {
    
    /// 开始加载模板
    func start()
}

//水平模板列表Delegate
public protocol TemplateHorizontalListViewDelegate: TemplateSelectedDelegate {
    
    /// 点击模板回调
    func templateHorizontalListView(_ listView: TemplateHorizontalListViewProtocol, didClick templateId: String) -> Bool
    
    
    /// 创建文档回调
    /// - Parameters:
    ///   - result: 创建后的文档结果
    ///   - error: 错误信息
    func templateHorizontalListView(_ listView: TemplateHorizontalListViewProtocol, onCreateDoc result: DocsTemplateCreateResult?, error: Error?)


    /// 模版列表展示状态为失败
    func templateHorizontalListView(_ listView: TemplateHorizontalListViewProtocol, onFailedStatus: Bool)
}

/// 水平模板视图参数
public struct HorizontalTemplateParams {
    public let itemHeight: CGFloat
    /// 模板数量
    public let pageSize: Int
    /// 模板分类ID
    public let categoryId: String
    /// DocComponent场景ID
    public let docComponentSceneId: String?
    /// 模板创建参数
    public let createDocParams: CreateDocTitleParams
    /// UI 配置参数，不传时使用 ccm 内部默认配置
    public var uiConfig: HorizontalTemplateUIConfig?
    /// 选择模板配置
    public let templatePageConfig: TemplatePageConfig?
    
    public let templateSource: String
    
    public init(itemHeight: CGFloat,
                pageSize: Int,
                categoryId: String,
                createDocParams: CreateDocTitleParams,
                templateSource: String,
                docComponentSceneId: String? = nil,
                uiConfig: HorizontalTemplateUIConfig? = nil,
                templatePageConfig: TemplatePageConfig? = nil) {
        self.itemHeight = itemHeight
        self.pageSize = pageSize
        self.categoryId = categoryId
        self.templateSource = templateSource
        self.docComponentSceneId = docComponentSceneId
        self.createDocParams = createDocParams
        self.uiConfig = uiConfig
        self.templatePageConfig = templatePageConfig
    }
}

/// 模版 Item UI 配置
public struct HorizontalTemplateUIConfig {
    
    public struct Layout {
        public static let defaultMinimumLineSpacing: CGFloat = 20.0
    }
    /// UICollectView items 间距，默认 20
    public let minimumLineSpacing: CGFloat

    /// UICollectionView 内边距，默认 UIEdgeInsets(top: 0, left: 16, bottom: padding, right: 16)
    public let sectionInset: UIEdgeInsets

    /// 展示【更多模版】View，默认展示
    public let showMoreTemplateView: Bool
    
    /// 隐藏副标题
    public let hideItemSubTitle: Bool

    public init(minimumLineSpacing: CGFloat = Layout.defaultMinimumLineSpacing,
                sectionInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16),
                showMoreTemplateView: Bool = true,
                hideItemSubTitle: Bool = false) {

        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
        self.showMoreTemplateView = showMoreTemplateView
        self.hideItemSubTitle = hideItemSubTitle
    }
}
