//
//  URLCardDependency.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/8/9.
//

import UIKit
import RustPB
import RxSwift
import LarkModel
import Foundation
import LarkContainer
import LarkRustClient
import TangramService
import LarkMessageBase
import TangramComponent
import TangramUIComponent
import RenderRouterInterface

// URLCardDependency是外部需要实现的依赖
public typealias URLCardLinkSceneType = UniversalCardLinkSceneType
public protocol URLCardDependency: AnyObject, EngineComponentDependency {
    var userResolver: UserResolver { get }
    var templateService: URLTemplateService? { get }
    var targetVC: UIViewController? { get }
    var contentMaxWidth: CGFloat { get }
    var senderID: String { get }
    // 卡片内组件点击时埋点上报的额外参数
    var extraTrackParams: [AnyHashable: Any] { get }
    // 是否支持关闭预览
    var supportClosePreview: Bool { get }

    func reloadRow(animation: UITableView.RowAnimation, updateVM: Bool)

    func getColor(for key: ColorKey, type: Type) -> UIColor

    // 获取原始URL
    func getOriginURL(previewID: String) -> String

    func downloadDocThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], viewSize: CGSize) -> Observable<UIImage>

    func createEngine(
        entity: URLPreviewEntity,
        property: Basic_V1_URLPreviewComponent.EngineProperty,
        style: Basic_V1_URLPreviewComponent.Style,
        renderStyle: RenderComponentStyle
    ) -> URLEngineAbility?

    // 打开详情页(卡片依赖)
    func openProfile(
        chatterID: String,
        from: UIViewController
    )

    // 预览大图(卡片依赖)
    func showImagePreview(
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    )

    func getChatID() -> String?

    func getCardLinkScene() -> URLCardLinkSceneType?
}

// 卡片通用上下文与能力
public protocol ComponentAbility: AnyObject, EngineComponentAbility {
    // update component(root or sub)
    func updatePreview(component: Component, animation: UITableView.RowAnimation)
    // 关闭预览
    func closePreview()
}

// ComponentURLDependency用于URL中台内部流转
// 为了内部不weak使用 & 避免业务方强持有dependency导致引用循环，此处单独封装为一个class
final class ComponentURLDependency {
    weak var dependencyProxy: URLCardDependency?
    weak var abilityProxy: ComponentAbility?
    let userResolver: UserResolver

    init(dependencyProxy: URLCardDependency?,
         abilityProxy: ComponentAbility?,
         userResolver: UserResolver) {
        self.dependencyProxy = dependencyProxy
        self.abilityProxy = abilityProxy
        self.userResolver = userResolver
    }
}

extension ComponentURLDependency: ComponentAbility {
    var cardContainer: URLCardContainer {
        return self.abilityProxy?.cardContainer ?? URLCardContainer()
    }

    func updatePreview(component: Component, animation: UITableView.RowAnimation) {
        abilityProxy?.updatePreview(component: component, animation: animation)
    }

    // 关闭预览
    func closePreview() {
        abilityProxy?.closePreview()
    }
}

extension ComponentURLDependency: URLCardDependency {
    var templateService: URLTemplateService? {
        return dependencyProxy?.templateService
    }

    var senderID: String {
        return dependencyProxy?.senderID ?? ""
    }

    weak var targetVC: UIViewController? {
        return dependencyProxy?.targetVC
    }

    var contentMaxWidth: CGFloat {
        return dependencyProxy?.contentMaxWidth ?? 0
    }

    var extraTrackParams: [AnyHashable: Any] {
        return dependencyProxy?.extraTrackParams ?? [:]
    }

    var supportClosePreview: Bool {
        return dependencyProxy?.supportClosePreview ?? true
    }

    func reloadRow(animation: UITableView.RowAnimation, updateVM: Bool) {
        dependencyProxy?.reloadRow(animation: animation, updateVM: updateVM)
    }

    // 获取原始URL
    func getOriginURL(previewID: String) -> String {
        return dependencyProxy?.getOriginURL(previewID: previewID) ?? ""
    }

    func downloadDocThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], viewSize: CGSize) -> Observable<UIImage> {
        return dependencyProxy?.downloadDocThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, viewSize: viewSize) ?? .empty()
    }

    func getColor(for key: ColorKey, type: Type) -> UIColor {
        return dependencyProxy?.getColor(for: key, type: type) ?? UIColor.clear
    }

    func createEngine(
        entity: URLPreviewEntity,
        property: Basic_V1_URLPreviewComponent.EngineProperty,
        style: Basic_V1_URLPreviewComponent.Style,
        renderStyle: RenderComponentStyle
    ) -> URLEngineAbility? {
        return dependencyProxy?.createEngine(entity: entity, property: property, style: style, renderStyle: renderStyle)
    }

    func openProfile(
        chatterID: String,
        from: UIViewController
    ) {
        dependencyProxy?.openProfile(chatterID: chatterID, from: from)
    }

    func showImagePreview(
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    ) {
        dependencyProxy?.showImagePreview(properties: properties, index: index, from: from)
    }

    func getChatID() -> String? {
        return dependencyProxy?.getChatID()
    }

    func getCardLinkScene() -> URLCardLinkSceneType? {
        return dependencyProxy?.getCardLinkScene()
    }
}
