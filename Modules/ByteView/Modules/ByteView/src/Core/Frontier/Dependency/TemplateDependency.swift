//
//  TemplateDependency.swift
//  ByteViewDependency
//
//  Created by liurundong.henry on 2023/6/12.
//

import Foundation

public protocol BVTemplate: AnyObject {

    func createTemplateViewController(with delegate: BVTemplateSelectedDelegate, categoryId: String, fromVC: UIViewController) -> UIViewController?
}

public protocol BVTemplateSelectedDelegate: AnyObject {

    /// 选择模板回调，仅在userTemplateType=.template时生效
    /// - Parameter item: 模板
    func templateOnItemSelected(_ viewController: UIViewController, item: BVTemplateItem)

    /// 传递模板页的事件
    func templateOnEvent(onEvent event: BVTemplatePageEvent)

}

/// 选择模板配置
public struct BVTemplatePageConfig {

    /// 使用模式方式
    public let useTemplateType: BVUseTemplateType
    /// 选择模板后自动Dissmiss
    public let autoDismiss: Bool
    /// 模板是否可以分享
    public let enableShare: Bool
    /// 模板选择页显示成关闭按钮
    public let showCloseButton: Bool

    public init(useTemplateType: BVUseTemplateType,
                autoDismiss: Bool,
                enableShare: Bool = false,
                showCloseButton: Bool = false) {
        self.useTemplateType = useTemplateType
        self.autoDismiss = autoDismiss
        self.enableShare = enableShare
        self.showCloseButton = showCloseButton
    }

    public static let `default` = BVTemplatePageConfig(useTemplateType: .createAndOpen, autoDismiss: true)
}

/// 创建模板页参数
public struct BVCreateTemplatePageParam {

    /// 模板分类ID
    public let categoryId: String

    /// DocComponent 场景ID，从DocComponent打开时需要传入
    public let dcSceneId: String?

    public let enterSource: String?

    public var templatePageConfig: BVTemplatePageConfig

    public init(categoryId: String,
                dcSceneId: String? = nil,
                enterSource: String? = nil,
                templatePageConfig: BVTemplatePageConfig) {
        self.categoryId = categoryId
        self.dcSceneId = dcSceneId
        self.enterSource = enterSource
        self.templatePageConfig = templatePageConfig
    }
}

/// “使用模板”的类型
public enum BVUseTemplateType: Int {
    case createAndOpen //创建并打开文档
    case create       //仅创建文档但不打开，回调返回文档url
    case template      //不创建文档，仅回调返回模板
}

public enum BVDocsType: Equatable, Hashable {
    /// 文件夹
    case folder
    /// 回收站
    case trash
    /// 文档
    case doc
    /// 表格
    case sheet
    /// 我的文档
    case myFolder
    /// Bitable
    case bitable
    /// 多维表格记录新建，不支持模板
    /// case baseAdd
    /// 思维笔记
    case mindnote
    /// Drive 文件
    case file
    /// Slide
    case slides
    /// Wiki
    case wiki
    /// 画板
    case whiteboard
    /*
     后端不会下发mediaFile，mediaFile 和 SpaceEntry没有任何关系。mediaFile 只用于新建模板页面上传图片入口展示。
     由来： 新建文档模板 DocsCreateView,上传这一列有 “图片”mediaFile 、“文件”file 两个入口，弹出不同的选择视图,
     mediaFile用来标识”图片“这个入口
     实际上，两个入口选中的内容被上传后都是file类型，因此也不要用mediaFile去做其它业务的逻辑判断。
     */
    case mediaFile
    /// IM消息中文件实体
    case imMsgFile
    /// DocX
    case docX
    /// 同步块
    case sync
    /// wiki 目录类型，理论上不会在 space 中单独出现，必须作为 wiki 的子类型
    case wikiCatalog
    /// 妙计(28)
    case minutes
    /// 未知文件
    case unknown(_ value: Int)
}

/// 模板Item
public struct BVTemplateItem: CustomStringConvertible {

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

    public var description: String {
        return String("""
        id: \(id)
        name.hash: \(name.hash)
        objToken.isEmpty: \(objToken.isEmpty)
        objType: \(objType)
        """
        )
    }
}

/// 模板页类型
public enum BVTemplatePageType {
    /// 选择模板页
    case select
    /// 预览页
    case preview
}

/// 模板页的事件
public enum BVTemplatePageEvent {
    /// 即将关闭
    case willClose(type: BVTemplatePageType)
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
