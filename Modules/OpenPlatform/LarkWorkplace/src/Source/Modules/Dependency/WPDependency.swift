//
//  WPDependency.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/3/24.
//

import Foundation
import Swinject
import AppContainer

final class WPDependency {

    private let dependency: WorkPlaceDependency
    private let internalDependency: WPInternalDependency

    init(dependency: WorkPlaceDependency, internalDependency: WPInternalDependency) {
        self.dependency = dependency
        self.internalDependency = internalDependency
    }

    // swiftlint:disable force_unwrapping
    var share: WorkPlaceDependencyShare {
        return dependency
    }

    var badge: WorkPlaceDependencyBadge {
        return dependency
    }

    var navigator: WorkPlaceDependencyNavigation {
        return dependency
    }

    var internalNavigator: WorkplaceInternalDependencyNavation {
        return internalDependency
    }

    var guide: WorkPlaceDependencyGuide {
        return internalDependency
    }
}
