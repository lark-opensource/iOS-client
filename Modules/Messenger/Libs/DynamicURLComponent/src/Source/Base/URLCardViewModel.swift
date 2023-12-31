//
//  URLCardViewModel.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/8/9.
//

import RustPB
import LarkModel
import LKCommonsLogging
import TangramComponent
import TangramUIComponent
import ThreadSafeDataStructure

public struct URLCardConfig {
    // 是否隐藏根节点的border
    public var hideRootBorder: Bool
    // 是否隐藏本地爬虫卡片header
    public var hideHeader: Bool
    // 是否隐藏本地爬虫卡片title
    public var hideTitle: Bool

    public init(hideRootBorder: Bool = false,
                hideHeader: Bool = false,
                hideTitle: Bool = false) {
        self.hideRootBorder = hideRootBorder
        self.hideHeader = hideHeader
        self.hideTitle = hideTitle
    }
}

public final class URLCardViewModel {
    static let logger = Logger.log(URLCardViewModel.self, category: "DynamicURLComponent.URLCardViewModel")
    private static var empty: Component {
        return UIViewComponent<EmptyContext>(props: .init())
    }

    // entity存储原始数据，新老数据结构兼容在使用时做
    public private(set) var entity: URLPreviewEntity
    public let renderer: ComponentRenderer
    let dependency: ComponentURLDependency
    let urlCardService: URLCardService
    let config: URLCardConfig

    private var _rootViewModel: SafeAtomic<ComponentBaseViewModel?> = nil + .readWriteLock
    var rootViewModel: ComponentBaseViewModel? {
        get { return _rootViewModel.value }
        set { _rootViewModel.value = newValue }
    }
    // 记录本次刷新是否有template
    private var hasTemplate = false

    public init(entity: URLPreviewEntity,
                urlCardService: URLCardService,
                cardDependency: URLCardDependency,
                config: URLCardConfig) {
        self.entity = entity
        self.urlCardService = urlCardService
        self.dependency = ComponentURLDependency(dependencyProxy: cardDependency,
                                                 abilityProxy: nil,
                                                 userResolver: cardDependency.userResolver)
        self.config = config
        self.renderer = ComponentRenderer(rootComponent: URLCardViewModel.empty,
                                          preferMaxLayoutWidth: cardDependency.contentMaxWidth)
        self.dependency.abilityProxy = self
        if let rootViewModel = createCard(entity: entity) {
            self.rootViewModel = rootViewModel
            self.renderer.update(rootComponent: rootViewModel.component)
        }
    }

    public func update(entity: URLPreviewEntity) {
        guard canUpdate(newEntity: entity) else { return }
        self.entity = entity
        // 只针对RenderRouter结构支持update，URL中台自建引擎不支持update，每次新建
        if let renderRouter = entity.renderRouter,
           let component = renderRouter.elements[renderRouter.rootID],
           let renderRouterRoot = rootViewModel?.children.first as? RenderRouterBaseViewModel, // 第一个节点是本地包的Empty，其下子节点才是RenderRouter
           renderRouterRoot.canUpdate(component: component) {
            renderRouterRoot.update(componentID: renderRouter.rootID,
                                    component: component,
                                    engineEntity: renderRouter.engineEntities[renderRouter.rootID],
                                    entity: entity)
        } else {
            let rootViewModel = createCard(entity: entity)
            self.rootViewModel = rootViewModel
        }
        self.renderer.update(rootComponent: rootViewModel?.component ?? URLCardViewModel.empty)
        if self.renderer.preferMaxLayoutWidth != dependency.contentMaxWidth {
            self.renderer.update(preferMaxLayoutWidth: dependency.contentMaxWidth, preferMaxLayoutHeight: nil)
        }
    }

    // View将要出现的时候
    public func willDisplay() {
        self.rootViewModel?.innerWillDisplay()
    }

    // View不再显示的时候
    public func didEndDisplay() {
        self.rootViewModel?.innerDidEndDisplay()
    }

    // Size发生变化
    public func onResize() {
        self.rootViewModel?.innerOnResize()
        if self.renderer.preferMaxLayoutWidth != dependency.contentMaxWidth {
            self.renderer.update(preferMaxLayoutWidth: dependency.contentMaxWidth, preferMaxLayoutHeight: nil)
        }
    }

    public func getCardURL() -> Basic_V1_URL? {
        // 老的components结构
        if let body = self.entity.previewBody, body.states.isEmpty {
            return body.hasCardURL ? body.cardURL : nil
        }
        // 新的state结构
        if let body = self.entity.previewBody, let state = body.states[body.currentStateID] {
            return state.hasCardURL ? state.cardURL : nil
        }
        // 本地爬虫
        if let body = self.entity.localPreviewBody {
            return body.cardURL
        }
        return nil
    }
}

// MARK: - private func
extension URLCardViewModel {
    private func createCard(entity: URLPreviewEntity) -> ComponentBaseViewModel? {
        // 新老数据结构兼容
        let entity = ComponentPreprocesser.transformToState(entity: entity, hideHeader: config.hideHeader, hideTitle: config.hideTitle)
        if let renderRouter = entity.renderRouter, !renderRouter.elements.isEmpty {
            if let renderRouterVM = ComponentCardRegistry.createRenderRouter(entity: entity,
                                                                             componentID: renderRouter.rootID,
                                                                             renderRouterEntity: renderRouter,
                                                                             ability: dependency,
                                                                             dependency: dependency) {
                // RenderRouter根节点是布局节点，无法渲染，需要包一层UI节点
                return createRenderRouterRoot(entity: entity, children: [renderRouterVM], dependency: dependency)
            }
        } else if let previewBody = entity.previewBody {
            // 如果有本地构建的template，说明是旧结构或者本地抓取预览，不需要重新走接口拉template
            guard let state = previewBody.states[previewBody.currentStateID],
                  state.type == .card, // alert类型暂时不支持
                  let template = entity.localTemplates[state.templateID] ?? dependency.templateService?.getTemplate(id: state.templateID) else {
                return nil
            }
            return ComponentCardRegistry.createPreview(entity: entity,
                                                       stateID: previewBody.currentStateID,
                                                       state: state,
                                                       componentID: template.rootComponentID,
                                                       template: template,
                                                       ability: dependency,
                                                       dependency: dependency,
                                                       hideBorder: config.hideRootBorder)
        }
        return nil
    }

    private func createRenderRouterRoot(entity: URLPreviewEntity,
                                        children: [ComponentBaseViewModel],
                                        dependency: ComponentURLDependency) -> ComponentBaseViewModel {
        var component = Basic_V1_URLPreviewComponent()
        component.style.maxWidth.value = 400
        component.style.maxWidth.type = .point
        component.style.width.value = 100
        component.style.width.type = .percentage
        component.type = .empty
        return EmptyComponentViewModel(
            entity: entity,
            stateID: "",
            componentID: "",
            component: component,
            style: component.style,
            property: component.urlpreviewComponentProperty,
            children: children,
            ability: dependency,
            dependency: dependency
        )
    }

    private func canUpdate(newEntity: URLPreviewEntity) -> Bool {
        // 宽度变更，也需要刷新，比如会话内flag状态变化，会导致宽度变化
        if renderer.preferMaxLayoutWidth != self.dependency.contentMaxWidth {
            return true
        }
        // 不能单纯使用entity.version判等，因为懒加载时推送下来的version和拉取到的version可能相同
        if self.entity != newEntity { return true }
        // entity不变，但是template状态变更（从无到有或者从有到无）时，也需要触发刷新；
        // template内容变更的话templateID会变，前置的entity判等可以拦截
        if let previewBody = newEntity.previewBody,
           let state = previewBody.states[previewBody.currentStateID] {
            let hasTemplate = (dependency.templateService?.getTemplate(id: state.templateID) != nil)
            let lastHasTemplate = self.hasTemplate
            self.hasTemplate = hasTemplate
            return hasTemplate != lastHasTemplate
        }
        URLCardViewModel.logger.error("[URLPreview] no state and skip update: \(newEntity.tcDescription)")
        return false
    }
}
