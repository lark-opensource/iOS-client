//
//  BTContainerToolBarPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import SKFoundation
import SKBrowser
import SKCommon
import UniverseDesignColor
import SKUIKit

final class BTContainerToolBarPlugin: BTContainerBasePlugin {
    
    override var view: UIView? {
        get {
            viewToolBar
        }
    }
    
    override func setupView(hostView: UIView) {
        hostView.addSubview(viewToolBar)
    }
    
    lazy var viewToolBar: ViewToolBar = {
        let toolbar = ViewToolBar()
        return toolbar
    }()

    required init(status: BTContainerStatus) {
        super.init(status: status)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(statusBarOrientationDidChange(_:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
    }

    @objc
    private func statusBarOrientationDidChange(_ notification: Notification) {
        remakeConstraints(status: status)
    }

    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        viewToolBar.isHidden = new.fullScreenType != .none
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        
        if stage == .finalStage {
            viewToolBar.isHidden = new.toolBarHidden
        } else if stage == .animationEndStage {
            if !new.baseHeaderHidden {
                viewToolBar.isHidden = new.toolBarHidden
            }
        }
        viewToolBar.alpha = new.toolBarHidden ? 0 : 1
        viewToolBar.transform.ty = new.toolBarHidden ? -BTContainer.Constaints.toolBarHeight : 0
        
        if new.darkMode != old?.darkMode {
            viewToolBar.updateDarkMode()
        }
    }
    
    override func remakeConstraints(status: BTContainerStatus) {
        super.remakeConstraints(status: status)
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard viewToolBar.superview != nil else {
            DocsLogger.error("invalid viewToolBar")
            return
        }
        guard let viewCatalogueContainer = service.getOrCreatePlugin(BTContainerPluginSet.viewCatalogueBanner).view,
                viewCatalogueContainer.superview == viewToolBar.superview else {
            DocsLogger.error("invalid view")
            return
        }
        
        viewToolBar.snp.remakeConstraints { make in
            make.top.equalTo(viewCatalogueContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(BTContainer.Constaints.toolBarHeight)
        }
    }
    
    func trySwitchToolBar(toolBarHidden: Bool) {
        DocsLogger.info("trySwitchToolBar")
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard status.viewContainerType == .hasViewCatalogHasToolBar else {
            DocsLogger.info("viewContainerType no ToolBar")
            return  // 没有 ToolBar
        }
        guard status.canSwitchToolBar else {
            DocsLogger.info("viewContainerType canSwitchToolBar=false")
            return  // 不允许切换 ToolBar
        }
        if toolBarHidden != status.toolBarHidden {
            DocsLogger.info("trySwitchToolBar:\(toolBarHidden)")
            service.setToolBarHidden(toolBarHidden: toolBarHidden, animated: true)
        }
    }
}
