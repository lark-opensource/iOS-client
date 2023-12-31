//
//  Dependency.swift
//  LarkMeegoViewBiz
//
//  Created by shizhengyu on 2023/4/13.
//

import Foundation

public protocol ViewBizDependency {
    func projectKey(by simpleName: String) -> String?
}
