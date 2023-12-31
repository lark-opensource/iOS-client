//
//  URLCardService.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/8/9.
//

import RustPB
import LarkModel
import LarkStorage
import LarkContainer
import TangramService
import RenderRouterInterface

public protocol URLCardContext: EngineComponentFactoryContext {
    var userResolver: UserResolver { get }
    var templateService: URLTemplateService? { get }
    func canCreateEngine(
        property: Basic_V1_URLPreviewComponent.EngineProperty,
        style: Basic_V1_URLPreviewComponent.Style
    ) -> Bool
}

public final class URLCardService {
    let container = URLCardContainer()
    private let userStore: KVStore
    // URLSDK级别服务是否注册完成
    private var serviceRegistered = false
    private var rwLock = pthread_rwlock_t()

    public init(userID: String) {
        self.userStore = KVStores.udkv(
            space: .user(id: userID),
            domain: Domain.biz.messenger.child("Tangram")
        )
        pthread_rwlock_init(&rwLock, nil)
    }

    public func canCreate(entity: URLPreviewEntity, context: URLCardContext) -> Bool {
        var valid = false
        let hasURL = entity.url.hasIos || entity.url.hasURL
        // 本地爬虫
        if entity.isLocalPreview,
           let localPreviewBody = entity.localPreviewBody,
           !localPreviewBody.title.isEmpty {
            valid = true
        } else if let renderRouter = entity.renderRouter, !renderRouter.elements.isEmpty { // 多引擎结构
            let previewID = entity.previewID
            // 包含不能创建的引擎时，视为卡片整体不能创建
            valid = !renderRouter.elements.contains { (componentID, component) in
                if let componentVM = ComponentCardRegistry.renderRouterComponentVMs[component.type],
                   let engineEntity = renderRouter.engineEntities[componentID] {
                    return !componentVM.canCreate(
                        previewID: previewID,
                        componentID: componentID,
                        component: component,
                        engineEntity: engineEntity,
                        context: context
                    )
                }
                return true
            }
        } else if hasURL { // 自建引擎
            let newEntity = ComponentPreprocesser.transformToState(entity: entity)
            if let previewBody = newEntity.previewBody,
               let state = previewBody.states[previewBody.currentStateID],
               let template = newEntity.localTemplates[state.templateID] ?? context.templateService?.getTemplate(id: state.templateID),
               !template.elements.isEmpty {
                valid = !template.elements.contains { (_, component) in
                    if let componentVM = ComponentCardRegistry.componentVMs[component.type] {
                        return !componentVM.canCreate(component: component, context: context)
                    }
                    return true
                }
            }
        }
        return valid && !isPreviewClosed(previewID: entity.previewID)
    }

    public func createCard(entity: URLPreviewEntity, cardDependency: URLCardDependency, config: URLCardConfig) -> URLCardViewModel? {
        registerServices(cardDependency: cardDependency)
        return URLCardViewModel(entity: entity, urlCardService: self, cardDependency: cardDependency, config: config)
    }

    public func closePreview(previewID: String) {
        userStore[previewID] = true
    }

    public func isPreviewClosed(previewID: String) -> Bool {
        return userStore.bool(forKey: previewID)
    }
}

// MARK: - private func
extension URLCardService {
    private func registerServices(cardDependency: URLCardDependency) {
        guard !self.serviceRegistered else { return }
        pthread_rwlock_wrlock(&rwLock)
        // 为了避免重复注册，拿到写锁之后仍需判断下是否已注册
        if self.serviceRegistered {
            return
        }
        self.serviceRegistered = true
        pthread_rwlock_unlock(&rwLock)

        EngineComponentRegistry.getAllFactories().values.forEach({ $0.registerServices(container: container, dependency: cardDependency) })
    }
}
