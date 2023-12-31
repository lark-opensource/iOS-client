//
//  SettingModule.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/25.
//

import Foundation
import LarkContainer

final class SettingModuleContainerContext {
    weak var viewController: UIViewController?
    weak var containerView: ModuleContainerView?
    init() { }
}

class SettingBaseModule: ModuleItem, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    var containerContext: SettingModuleContainerContext!
    var view: UIView { UIView() }

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func setup() { }
}
