//
//  ProjectBizAssembly.swift
//  LarkMeegoProjectBiz
//
//  Created by shizhengyu on 2023/4/14.
//

import Foundation
import LarkAssembler
import LarkContainer
import LarkSetting

private enum ProjectBiz {
    public static var userScopeCompatibleMode: Bool {
        return !FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.meego")
    }
    // 用于替换 .user, FG 控制是否开启兼容模式。兼容模式下和 .user 表现一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
}

public class ProjectBizAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(ProjectBiz.userScope)

        user.register(ProjectService.self) { r in
            return try ProjectServiceImpl(userResolver: r)
        }
    }
}
