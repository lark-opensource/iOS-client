//
//  BTContainerStatusBarPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import SKFoundation
import SKCommon
import UniverseDesignColor

final class BTContainerStatusBarPlugin: BTContainerBasePlugin {
    
    override var view: UIView? {
        get {
            statusBar
        }
    }
    
    private var statusBar: BaseViewController.StatusBarView? {
        get {
            service?.browserViewController?.statusBar
        }
    }
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        guard let statusBar = statusBar else {
            return
        }
        if new.containerState == .statePgae {
            // 正在显示失败页，或权限申请页，statusBar 不能透明
            statusBar.backgroundColor = UDColor.bgBody
            return
        }
        if service?.browserViewController?.docsInfo?.inherentType == .baseAdd {
            statusBar.backgroundColor = .clear
            return
        }
        if new.isRegularMode {
            statusBar.backgroundColor = .clear
        } else {
            if new.blockCatalogueHidden {
                if new.baseHeaderHidden {
                    statusBar.backgroundColor = BTContainer.Constaints.viewCatalogueTopColor
                } else {
                    statusBar.backgroundColor = .clear
                }
            } else {
                statusBar.backgroundColor = .clear
            }
        }
    }
}
