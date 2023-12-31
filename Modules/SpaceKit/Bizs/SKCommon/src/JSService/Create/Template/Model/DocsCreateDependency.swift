//
//  DocsCreateDependency.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/9/14.
//  


import Foundation

struct DocsCreateDependency {
    var trackParamterModule: PageModule
    var trackExtraParamter: [String: Any]?
    var templateCenterSource: SKCreateTracker.TemplateCenterSource
    var mountLocation: WorkspaceCreateLocation
    weak var targetPopVC: UIViewController?
    var createByTemplateHandler: ((TemplateModel, UIViewController, @escaping CreateCompletion) -> Void)?
}
