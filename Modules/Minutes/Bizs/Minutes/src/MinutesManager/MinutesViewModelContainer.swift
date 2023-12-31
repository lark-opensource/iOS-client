//
//  MinutesViewModelContainer.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/10/30.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

protocol MinutesViewModelResolver: AnyObject {
    var minutes: Minutes { get }
    func resolve<ViewModel: MinutesViewModelComponent>(_ type: ViewModel.Type) -> ViewModel?
}

extension MinutesViewModelResolver {
    /// 只用在类型可被推断的情况下
    func resolve<ViewModel: MinutesViewModelComponent>() -> ViewModel? {
        resolve(ViewModel.self)
    }
}

protocol MinutesViewModelComponent {
    init(resolver: MinutesViewModelResolver)
}

struct MinutesViewModelConfig: CustomStringConvertible {
    let id: ObjectIdentifier
    let isLazy: Bool
    let componentType: MinutesViewModelComponent.Type
    let description: String

    init<ViewModel: MinutesViewModelComponent>(_ vmType: ViewModel.Type, isLazy: Bool) {
        self.id = ObjectIdentifier(vmType)
        self.isLazy = isLazy
        self.componentType = vmType
        self.description = "\(vmType)"
    }

    func create(resolver: MinutesViewModelResolver) -> MinutesViewModelComponent {
        let obj = componentType.init(resolver: resolver)
        MinutesLogger.common.info("create viewmodel success: \(self.description)")
        return obj
    }
}

final class MinutesViewModelContainer {
    let resolver: MinutesViewModelResolver
    private let configs: [ObjectIdentifier: MinutesViewModelConfig] = MinutesViewModelRegistry.shared.viewModelConfigs
    private var cache: [ObjectIdentifier: MinutesViewModelComponent] = [:]

    init(minutes: Minutes) {
        let resolver = MinutesViewModelResolverImpl(minutes: minutes)
        self.resolver = resolver
        resolver.container = self
    }

    func resolveNonLazyObjects() {
        configs.forEach { (_, config) in
            if !config.isLazy {
                _ = resolve(config)
            }
        }
    }

    fileprivate func resolve<T: MinutesViewModelComponent>(_ type: T.Type) -> T? {
        if let config = configs[ObjectIdentifier(type)] {
            return resolve(config) as? T
        }
        return nil
    }

    fileprivate func resolve(_ config: MinutesViewModelConfig) -> MinutesViewModelComponent {
        let id = config.id
        if let obj = cache[id] {
            return obj
        }
        let obj = config.create(resolver: resolver)
        cache[id] = obj
        return obj
    }
}

private class MinutesViewModelResolverImpl: MinutesViewModelResolver {
    var minutes: Minutes
    weak var container: MinutesViewModelContainer?

    init(minutes: Minutes) {
        self.minutes = minutes
    }

    func resolve<ViewModel>(_ type: ViewModel.Type) -> ViewModel? where ViewModel: MinutesViewModelComponent {
        container?.resolve(type)
    }
}
