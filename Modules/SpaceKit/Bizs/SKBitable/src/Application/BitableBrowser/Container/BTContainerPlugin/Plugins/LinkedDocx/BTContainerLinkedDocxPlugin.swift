//
//  BTContainerLinkedDocxPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/13.
//

import Foundation
import SKBrowser
import SKFoundation
import SKCommon
import SpaceInterface

class BTContainerLinkedDocxPlugin: BTContainerBasePlugin {
    
    private var docxVC: BrowserViewController?
    
    func bringDocxViewUp() {
        guard let viewContainer = service?.getPlugin(BTContainerViewContainerPlugin.self)?.view else {
            DocsLogger.error("showLinkedDocx invalid viewContainer")
            return
        }
        if let loadingPlugin = service?.getOrCreatePlugin(BTContainerPluginSet.viewContainer), let docxView = self.docxVC?.view {
            viewContainer.bringSubviewToFront(docxView)
            loadingPlugin.bringLoadingToFront()
        }
    }
    
    static func newDocxVC(with token: String) -> BrowserViewController? {
        let type = DocsType.docX
        let docsType = EditorManager.getDocsBrowserType(type)
        var fileConfig = FileConfig(vcType: docsType)
        let docxURL = DocsUrlUtil.url(type: type, token: token)
            .docs
            .addOrChangeEncodeQuery(
                parameters: [
                    "from": OpenDocsFrom.baseInstructionDocx.rawValue,
                    CCMOpenTypeKey: CCMOpenType.baseInstructionDocx.rawValue,
                ]
            )

        let openResult = EditorManager.shared.open(docxURL, fileConfig: fileConfig)
        let docxVC = openResult.targetVC
        return docxVC
    }
    // 已预加载的调用
    func showLinkedDocx(docxVC: BrowserViewController) {
        guard let browserVC = service?.browserViewController else {
            DocsLogger.error("showLinkedDocx invalid browserVC")
            return
        }
        showDocx(docxVC)
    }
    
    /// 参数说明 必传Docx token
    func showLinkedDocx(_ params: [String: Any]) {
        DocsLogger.info("showLinkedDocx")
        guard let token = params["token"] as? String else {
            DocsLogger.error("showLinkedDocx invalid token")
            return
        }
        
        guard let browserVC = service?.browserViewController else {
            DocsLogger.error("showLinkedDocx invalid browserVC")
            return
        }
        
        guard docxVC?.docsInfo?.token != token else {
            DocsLogger.info("showLinkedDocx docxToken is Same")
            if let vc = docxVC, vc.view.superview == nil {
                DocsLogger.info("showLinkedDocx")
                showDocx(vc)
            } else {
                DocsLogger.info("showLinkedDocx has show")
            }
            return
        }
        
        // 先隐藏旧的 Docx
        hideLinkedDocx()
        let docxVC = Self.newDocxVC(with: token)
        guard let docxVC = docxVC else {
            DocsLogger.error("showLinkedDocx invalid docxVC")
            return
        }
        showDocx(docxVC)
        self.docxVC = docxVC
    }
    
    func hideLinkedDocx() {
        guard let docxVC = docxVC else {
            DocsLogger.info("hideLinkedDocx no docxVC")
            return
        }
        DocsLogger.info("hideLinkedDocx")
        docxVC.editor.scrollViewProxy.removeObserver(self)
        docxVC.willMove(toParent: nil)
        docxVC.removeSelfFromParentVC()
        docxVC.view.removeFromSuperview()
        docxVC.didMove(toParent: nil)
        service?.gesturePlugin?.unregisterAncestorView(view: docxVC.editor.editorView)
        self.docxVC = nil
    }
    
    private func isShowOnboarding(_ parentVC: UIViewController) -> Bool {
        return OnboardingManager.shared.getCurrentTopOnboardingID(in: parentVC) == .bitableExposeCatalogIntro
    }
    
    private func showDocx(_ docxVC: BrowserViewController) {
        guard let service = service else {
            return
        }
        guard let parentVC = service.browserViewController else {
            DocsLogger.error("showLinkedDocx invalid parentVC")
            return
        }
        guard let viewContainer = service.getPlugin(BTContainerViewContainerPlugin.self)?.view else {
            DocsLogger.error("showLinkedDocx invalid viewContainer")
            return
        }
        // 作为childVC 不需要重复添加水印了
        docxVC.watermarkConfig.needAddWatermark = false
        
        // Docx in base 的加载流程使用同一个 traceId
        if let traceId = parentVC.fileConfig?.getOpenFileTraceId() {
            docxVC.fileConfig?.update(openBaseTraceId: traceId)
        }
        
        self.docxVC = docxVC
        parentVC.addChild(docxVC)
        viewContainer.addSubview(docxVC.view)
        docxVC.didMove(toParent: parentVC)
        docxVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 圆角
        docxVC.view.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
        docxVC.view.layer.masksToBounds = true
        docxVC.view.layer.maskedCorners = .top
        
        service.gesturePlugin?.resetToTop()
        docxVC.editor.scrollViewProxy.addObserver(self)

        service.gesturePlugin?.registerAncestorView(view: docxVC.editor.editorView)
    }
}

extension BTContainerLinkedDocxPlugin: EditorScrollViewObserver {
    func editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        guard let scrollView = editorViewScrollViewProxy.getScrollView() else {
            return
        }
        service?.gesturePlugin?.scrolledToTop(scrollView.btScrolledToTop)
    }
}
