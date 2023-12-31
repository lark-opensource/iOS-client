//
//  WPHomeRootVC+NetDiagnose.swift
//  LarkWorkplace
//
//  Created by 窦坚 on 2022/5/10.
//

import EENavigator
import LarkNavigator
import UIKit

extension WPHomeRootVC: WPNetDiagnoseBarDelegate {

    var jumpFromViewController: UIViewController {
        return self
    }

    func netDiagnoseBarStatusDidChange(_ netDiagnoseBar: WPNetDiagnoseBar) {
        let isHidden = netDiagnoseBar.barStatus.shouldHideStatusBar
        netDiagnoseBar.isHidden = isHidden
        if isHidden {
            // 使网络诊断栏顶部&底部约束失效，topContainer 会恢复到不包含网络诊断栏的高度
            netDiagnoseTopConstraint?.deactivate()
            netDiagnoseBottomConstraint?.deactivate()
        } else {
            // 激活网络诊断栏顶部&底部约束，topContainer 的高度会包含网络诊断栏
            netDiagnoseTopConstraint?.activate()
            netDiagnoseBottomConstraint?.activate()
        }
    }
}
