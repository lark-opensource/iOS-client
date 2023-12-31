//
//  BTContainerFormViewPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/13.
//

import Foundation
import SKFoundation

class BTContainerFormViewPlugin: BTContainerBasePlugin {
    
    weak var currentFormVC: BTController?
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        
        if new.isRegularMode, new.blockCatalogueHidden != old?.blockCatalogueHidden,
            let currentFormVC = currentFormVC,
            currentFormVC.view.superview != nil {
            currentFormVC.view.superview?.layoutIfNeeded()
            currentFormVC.reloadCardsView()
        }
    }
    
    func showForm(formVC: BTController) {
        DocsLogger.info("BTContainerFormViewPlugin.showForm")
        guard let service = service else {
            DocsLogger.error("showForm invalid service")
            return
        }
        guard let parentVC = service.browserViewController else {
            DocsLogger.error("showForm invalid parentVC")
            return
        }
        guard let viewContainer = service.getPlugin(BTContainerViewContainerPlugin.self)?.view else {
            DocsLogger.error("showForm invalid viewContainer")
            return
        }
        guard let viewCatalogue = service.getPlugin(BTContainerViewCataloguePlugin.self)?.view, viewCatalogue.superview == viewContainer else {
            DocsLogger.error("showForm invalid viewCatalogue")
            return
        }
        self.currentFormVC = formVC
        
        parentVC.addChild(formVC)
        viewContainer.addSubview(formVC.view)
        formVC.didMove(toParent: parentVC)
        formVC.view.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(viewCatalogue.snp.bottom)
        }
        
        service.gesturePlugin?.resetToTop()

        service.gesturePlugin?.registerAncestorView(view: formVC.view)
    }

    deinit {
        if let view = currentFormVC?.view {
            service?.gesturePlugin?.unregisterAncestorView(view: view)
        }
    }

    func didScroll(_ scrollView: UIScrollView) {
        service?.gesturePlugin?.scrolledToTop(scrollView.btScrolledToTop)
    }
}
