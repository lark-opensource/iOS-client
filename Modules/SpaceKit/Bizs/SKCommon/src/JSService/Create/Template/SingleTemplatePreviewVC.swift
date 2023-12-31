//
//  SingleTemplatePreviewVC.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/2/10.
//  

import UIKit
import SKFoundation
import SKUIKit
import SwiftyJSON
import RxSwift
import UniverseDesignToast
import EENavigator
import SpaceInterface
import SKInfra

class SingleTemplatePreviewVC: BaseViewController {
    private var templateID: String
    private var req: DocsRequest<TemplateModel>?
    private var templateSource: TemplateCenterTracker.TemplateSource?
    private lazy var defaultLoadingView: DocsLoadingViewProtocol = {
        DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()
    private var childVC: UIViewController?
    init(templateID: String) {
        self.templateID = templateID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(defaultLoadingView.displayContent)
        defaultLoadingView.displayContent.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        fetchTemplate()
    }
    
    private func fetchTemplate() {
        defaultLoadingView.startAnimation()
        
        let params: [String: Any] = [
            "template_id": templateID
        ]
        self.req = DocsRequest<TemplateModel>(path: OpenAPI.APIPath.templateInfoV2, params: params)
            .set(method: .GET)
            .set(transform: { json -> (TemplateModel?, error: Error?) in
                guard let json = json, DocsNetworkError.isSuccess(json["code"].int),
                      let data = json["data"]["template"].rawString()?.data(using: .utf8) else {
                    return (nil, DocsNetworkError.invalidData)
                }
                do {
                    let template = try JSONDecoder().decode(TemplateModel.self, from: data)
                    return (template, nil)
                } catch {
                    spaceAssertionFailure("parse data error \(error)")
                    return (nil, error)
                }
            })
            .start(callbackQueue: .main, result: { [weak self] object, error in
                guard let self = self else { return }
                self.defaultLoadingView.stopAnimation()
                self.defaultLoadingView.displayContent.isHidden = true
                if let template = object {
                    self.openPreviewVC(template)
                } else if let error = error {
                    UDToast.showFailure(with: error.localizedDescription, on: self.view.window ?? self.view)
                }
            })
    }
    
    private func openPreviewVC(_ template: TemplateModel) {
        guard let vc = NormalTemplatesPreviewVC(templates: [template], currentIndex: 0, templateSource: templateSource) else { return }
        self.addChild(vc)
        self.view.addSubview(vc.view)
        vc.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        vc.didMove(toParent: self)
        childVC = vc
    }
    
    private func removeChildVC() {
        guard let childVC = childVC else {
            return
        }
        childVC.willMove(toParent: nil)
        childVC.view.snp.removeConstraints()
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }
}

extension SingleTemplatePreviewVC: FragmentLocate {
    /// 在vc场景下，可能出现先点击预览链接A打开预览页面，未关闭该页面的前提下，又点击预览链接B。如果链接里有带fragment，就能走这里刷新
    func customLocate(by fragment: String, with context: [String: Any], animated: Bool) {
        guard let id = context["id"] as? String, id != templateID else {
            return
        }
        templateID = id
        removeChildVC()
        fetchTemplate()
    }
}
