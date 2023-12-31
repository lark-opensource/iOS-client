//
//  RenderRouterBaseViewModel.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/7/31.
//

import RustPB
import LarkModel
import RenderRouterInterface

open class RenderRouterBaseViewModel: ComponentBaseViewModel {
    // 对于RenderRouter多引擎，需要支持更新，有多线程问题
    private var lock: pthread_mutex_t

    public required init(entity: URLPreviewEntity,
                         componentID: String,
                         component: Basic_V1_CardComponent,
                         engineEntity: Basic_V1_EngineEntity?,
                         children: [ComponentBaseViewModel],
                         ability: ComponentAbility,
                         dependency: URLCardDependency) {
        self.lock = pthread_mutex_t()
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&lock, &attr)
        pthread_mutexattr_destroy(&attr)
        super.init(entity: entity, children: children, ability: ability, dependency: dependency)
    }

    open func update(componentID: String,
                     component: Basic_V1_CardComponent,
                     engineEntity: Basic_V1_EngineEntity?,
                     entity: URLPreviewEntity) {
        self.entity = entity
    }

    open func canUpdate(component: Basic_V1_CardComponent) -> Bool {
        return false
    }

    /// 是否能创建当前组件
    open class func canCreate(previewID: String,
                              componentID: String,
                              component: Basic_V1_CardComponent,
                              engineEntity: Basic_V1_EngineEntity?,
                              context: EngineComponentFactoryContext) -> Bool {
        return true
    }

    deinit {
        pthread_mutex_destroy(&self.lock)
    }

    public override func safeRead<T>(_ read: () -> T) -> T {
        pthread_mutex_lock(&lock)
        defer { pthread_mutex_unlock(&lock) }
        return read()
    }

    public override func safeWrite(_ write: () -> Void) {
        pthread_mutex_lock(&lock)
        write()
        pthread_mutex_unlock(&lock)
    }
}
