//
//  EngineComponentDependency.swift
//  RenderRouterInterface
//
//  Created by Ping on 2023/7/31.
//

import UIKit
import RustPB
import EENavigator
import LarkContainer
import TangramComponent

// 需要外部宿主提供的依赖，可被强持有
public protocol EngineComponentDependency: AnyObject, UniversalCardActionDependency {
    // 用户态容器
    var userResolver: UserResolver { get }
    // 容器VC
    var targetVC: UIViewController? { get }
}

// 超链接的的来源场景, 用于 applink 统计
public enum UniversalCardLinkSceneType: Int {
    // 话题
    case topic
    // 单聊
    case single
    // 群聊
    case multi
    // 非聊天等其他场景
    case other
}

public protocol UniversalCardActionDependency: AnyObject {
    // 打开角色详情页
    func openProfile(
        chatterID: String,
        from: UIViewController
    )

    // 预览图片
    func showImagePreview(
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    )

    func getChatID() -> String?
    
    // 当前卡片所在的场景, 用于 applink 跳转时统计用
    func getCardLinkScene() -> UniversalCardLinkSceneType?

}

// URLSDK提供的内置能力，可被强持有
public protocol EngineComponentAbility: AnyObject {
    // URLSDK级别容器
    var cardContainer: URLCardContainer { get }

    // 更新UI，宿主非TableView场景animation不生效
    func updatePreview(component: Component, animation: UITableView.RowAnimation)
}

public extension EngineComponentAbility {
    func updatePreview(component: Component) {
        updatePreview(component: component, animation: .none)
    }
}
