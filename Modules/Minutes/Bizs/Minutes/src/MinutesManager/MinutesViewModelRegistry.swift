//
//  MinutesViewModelRegistry.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/11/7.
//

import Foundation

final class MinutesViewModelRegistry {
    static let shared = MinutesViewModelRegistry()

    private init() {
    }

    let viewModelConfigs: [ObjectIdentifier: MinutesViewModelConfig] = {
        var configs: [ObjectIdentifier: MinutesViewModelConfig] = [:]
        func vm<T: MinutesViewModelComponent>(_ vmType: T.Type, isLazy: Bool = true) {
            let config = MinutesViewModelConfig(vmType, isLazy: isLazy)
            configs[config.id] = config
        }
        /// lazy

        /// no lazy
        vm(MinutesContainerViewModel.self, isLazy: false)
        return configs
    }()
}
