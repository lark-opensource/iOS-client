//
//  WorkItemBizDependencyImpl.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/4/14.
//

import Foundation
import LarkMeegoProjectBiz
import LarkMeegoWorkItemBiz
import LarkContainer

class WorkItemBizDependencyImpl: WorkItemBizDependency {
    private let userResolver: UserResolver
    private let projectService: ProjectService

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        projectService = try userResolver.resolve(assert: ProjectService.self)
    }

    func projectKey(by simpleName: String) -> String? {
        return projectService.cachedProjectKey(by: simpleName)
    }
}
