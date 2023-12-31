//
//  Dependency.swift
//  LarkMeegoWorkItemBiz
//
//  Created by shizhengyu on 2023/4/13.
//

import Foundation

public protocol WorkItemBizDependency {
    func projectKey(by simpleName: String) -> String?
}
