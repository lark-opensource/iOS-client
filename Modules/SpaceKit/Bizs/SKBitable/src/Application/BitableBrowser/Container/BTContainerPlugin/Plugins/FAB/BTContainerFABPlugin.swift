//
//  BTContainerFABPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/10.
//

import Foundation
import SKBrowser
import SKFoundation
import SKCommon

final class BTContainerFABPlugin: BTContainerBasePlugin {
    
    private var editorViewRightPadding: CGFloat = 0
    func updateEditorViewRightPadding(editorViewRightPadding: CGFloat, animationDuration: TimeInterval) {
        guard editorViewRightPadding != self.editorViewRightPadding else {
            return
        }
        self.editorViewRightPadding = editorViewRightPadding
        UIView.animate(withDuration: animationDuration) {
            self.remakeConstraints(status: self.status)
            self.toolbarsContainer?.superview?.layoutIfNeeded()
        }
    }
    
    private weak var toolbarsContainer: BTToolbarsContainerView?
    
    private func updateTransform(status: BTContainerStatus) {
        guard let toolbarsContainer = toolbarsContainer else {
            return
        }
        if status.isRegularMode {
            toolbarsContainer.transform = CGAffineTransform(translationX: 0, y: 0)
        } else {
            if status.blockCatalogueHidden {
                toolbarsContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            } else {
                toolbarsContainer.transform = CGAffineTransform(translationX: status.blockCatalogueWidth, y: 0)
            }
        }
    }
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        updateTransform(status: new)
    }
    
    func relayoutToolbarsContainer(toolbarsContainer: BTToolbarsContainerView, cardVC: UIViewController?) {
        self.toolbarsContainer = toolbarsContainer
        toolbarsContainer.removeFromSuperview()
        toolbarsContainer.snp.removeConstraints()
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard let browserVC = service.browserViewController else {
            DocsLogger.error("invalid browserVC")
            return
        }
        guard let mainContainerView = service.getOrCreatePlugin(BTContainerMainContainerPlugin.self).view else {
            DocsLogger.error("invalid mainContainerView")
            return
        }
        mainContainerView.addSubview(toolbarsContainer)
        browserVC.editor.fabContainer = toolbarsContainer.fabContainerView
        remakeConstraints(status: status)
        updateTransform(status: status)
        
        // FAB 添加的时候需要在 Loading 下面
        service.getPlugin(BTContainerViewContainerPlugin.self)?.bringLoadingToFront()
    }
    
    override func remakeConstraints(status: BTContainerStatus) {
        super.remakeConstraints(status: status)
        guard let toolbarsContainer = toolbarsContainer,
              toolbarsContainer.superview != nil else {
            return
        }
        toolbarsContainer.snp.remakeConstraints { (make) in
            make.left.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-editorViewRightPadding)
        }
    }
    
}
