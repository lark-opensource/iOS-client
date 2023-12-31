//
//  BTContainerNativeRenderPlugin.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/31.
//  

import SKCommon
import SKInfra
import SKBrowser
import SKFoundation

final class BTContainerNativeRenderPlugin: BTContainerBasePlugin {
    private weak var nativeRenderVC: NativeRenderBaseController?
    
    var searchMode: BrowserViewController.SearchMode? {
        didSet {
            nativeRenderVC?.searchModeDidChange(searchMode: searchMode)
        }
    }
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        nativeRenderVC?.view.transform.ty = (new.canSwitchToolBar && new.toolBarHidden) ? -BTContainer.Constaints.toolBarHeight : 0
    }
    
    func hideNativeRenderView() {
        guard let nativeRenderVC = nativeRenderVC,
              nativeRenderVC.parent != nil else {
            return
        }
        
        nativeRenderVC.view.isHidden = true
    }
    
    func showNativeRenderView() {
        guard let nativeRenderVC = nativeRenderVC,
              nativeRenderVC.parent != nil else {
            return
        }
        
        nativeRenderVC.view.isHidden = false
    }
    
    func showNativeRenderView(nativeRenderVC: NativeRenderBaseController) {
        self.nativeRenderVC = nativeRenderVC
        guard let service = service else {
            DocsLogger.btError("show nativeRender invalid service")
            return
        }
        
        guard let parentVC = service.browserViewController else {
            DocsLogger.btError("show nativeRender invalid parentVC")
            return
        }
        
        guard let viewContainer = service.getPlugin(BTContainerViewContainerPlugin.self)?.view else {
            DocsLogger.btError("show nativeRender invalid viewContainer")
            return
        }
        
        guard let toolBarView = service.getPlugin(BTContainerToolBarPlugin.self)?.view, toolBarView.superview == viewContainer else {
            DocsLogger.btError("show nativeRender invalid toolBarView")
            return
        }
        
        parentVC.addChild(nativeRenderVC)
        viewContainer.addSubview(nativeRenderVC.view)
        nativeRenderVC.didMove(toParent: parentVC)
        nativeRenderVC.view.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(toolBarView.snp.bottom)
        }
        
        service.gesturePlugin?.resetToTop()
        service.gesturePlugin?.registerAncestorView(view: nativeRenderVC.view)
    }
    
    deinit {
        if let view = nativeRenderVC?.view {
            service?.gesturePlugin?.unregisterAncestorView(view: view)
        }
    }
    
    func updateModel(model: NativeRenderBaseModel?) {
        self.nativeRenderVC?.updateModel(model: model)
    }
}
