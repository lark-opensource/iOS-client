//
//  TemplateCenterRouter.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/2/10.
//  


import Foundation
import EENavigator
import UIKit
import SKFoundation


protocol TemplateRouter {
    func check(resource: SKRouterResource, params: [AnyHashable: Any]?) -> Bool
    func targetVC(resource: SKRouterResource, params: [AnyHashable: Any]?) -> UIViewController
}

public final class TemplateCenterRouter: TemplateRouter {
    enum Action: String {
        case preview
        case topic
    }
    
    public init() {}
    
    public func check(resource: SKRouterResource, params: [AnyHashable: Any]?) -> Bool {
        return URLValidator.isDocsURL(resource.url) && resource.url.path == "/drive/template-center"
    }
    public func targetVC(resource: SKRouterResource, params: [AnyHashable: Any]?) -> UIViewController {
        var params: [String: String] = [:]
        if let url = resource as? URL, let queryParams = url.docs.queryParams {
            params = queryParams
        }
        var source: TemplateCenterTracker.EnterTemplateSource = .promotionalDocs
        if let from = params["from"], let enterSource = TemplateCenterTracker.EnterTemplateSource(rawValue: from) {
            source = enterSource
        }
        let id = params["id"]
        let objType = Int(params["objType"] ?? "")
        let enterSource = params["templateSource"]
        
        var targetVC: UIViewController?
        if let actionStr = params["action"] as? String, let action = Action(rawValue: actionStr) {
            switch action {
            case .preview:
                targetVC = getTemplatePreviewVC(id: id, type: params["templateType"], source: source, enterSource: enterSource)
            case .topic:
                // 专题模板
                targetVC = getThemeListViewController(id: id, objType: objType, source: source, enterSource: enterSource)
            }
        }
        if let targetVC = targetVC {
            return targetVC
        }
        
        let dataProvider = TemplateDataProvider()
        let vm = TemplateCenterViewModel(
            depandency: (networkAPI: dataProvider, cacheAPI: dataProvider),
            shouldCacheFilter: false
        )
        let initialType: TemplateMainType = TemplateMainType(string: params["openTemplateCenter"] ?? "") ?? .gallery
        var categoryId: Int?
        if let categoryIdStr = params["categoryId"] {
            categoryId = Int(categoryIdStr)
        }
        let vc = TemplateCenterViewController(
            viewModel: vm,
            initialType: initialType,
            templateCategory: categoryId,
            objType: objType,
            mountLocation: .spaceDefault,
            source: source,
            enterSource: enterSource
        )
        return vc
    }
    
    private func getThemeListViewController(id: String?, objType: Int?, source: TemplateCenterTracker.EnterTemplateSource, enterSource: String?) -> TemplateThemeListViewController? {
        guard let id = id, let topicId = Int(id) else {
            return nil
        }
        var objTypeInt: Int?
        if let objType = objType {
            objTypeInt = Int(objType)
        }
        let dataProvider = TemplateDataProvider()
        let vm = TemplateThemeViewModel(networkAPI: dataProvider, cacheAPI: dataProvider, topID: topicId, objType: objTypeInt)
        let fromVC = Navigator.shared.mainSceneWindow?.fromViewController
        let vc = TemplateThemeListViewController(
            fromViewWidth: fromVC?.view.frame.size.width ?? 0,
            viewModel: vm,
            filterType: nil,
            objType: objTypeInt,
            mountLocation: .spaceDefault,
            targetPopVC: fromVC,
            source: source,
            templateSource: .init(enterSource: enterSource, source: source)
        )
        return vc
    }
    
    private func getTemplatePreviewVC(id: String?, type: String?, source: TemplateCenterTracker.EnterTemplateSource, enterSource: String?) -> UIViewController? {
        guard let id = id, let typeStr = type, let typeInt = Int(typeStr), let type = TemplateModel.TemplateType(rawValue: typeInt) else { return nil }
        switch type {
        case .normal:
            return SingleTemplatePreviewVC(templateID: id)
        case .collection, .ecology:
            return TemplateCollectionPreviewViewController(collectionId: id,
                                                           networkAPI: TemplateDataProvider(),
                                                           templateSource: .init(enterSource: enterSource, source: source),
                                                           type: type)
        }
    }
}

public final class TemplateDocsCreateRouter: TemplateRouter {
    public init() {}
    
    public func check(resource: SKRouterResource, params: [AnyHashable: Any]?) -> Bool {
        return URLValidator.isDocsURL(resource.url) && resource.url.path == "/space/api/obj_template/create_i18n_obj"
    }
    public func targetVC(resource: SKRouterResource, params: [AnyHashable: Any]?) -> UIViewController {
        var params: [String: String] = [:]
        if let url = resource as? URL, let queryParams = url.docs.queryParams {
            params = queryParams
        }
        let templateId = params["template_i18n_id"]
        let from = params["create_source"] ?? params["from"]
        
        return TemplateDocsCreateViewController(templateToken: nil, templateId: templateId, docsType: nil, clickFrom: from)
    }
}
