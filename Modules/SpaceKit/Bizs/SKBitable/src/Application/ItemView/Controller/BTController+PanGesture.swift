//
//  BTController+input.swift
//  DocsSDK
//
//  Created by Webster on 2020/3/17.
//

import Foundation
import SKCommon
import SKUIKit

protocol BTPanGestureManager: AnyObject {
    var midTop: CGFloat { get }
    var midHeight: CGFloat { get }
    var maxTop: CGFloat { get }
    var maxHeight: CGFloat { get }
    func panToChangeSize(ofPanel: UIView, sender: UIPanGestureRecognizer)
    func resizePanel(panel: UIView, to: PanelHeightLevel)
    func resizePanel(panel: UIView, to: CGFloat)
}

enum PanelHeightLevel {
    case max // panel.height = view.height * 0.8
    case mid // panel.height = view.height * 0.6
}

extension BTController: BTPanGestureManager {

    var midTop: CGFloat { view.bounds.height - midHeight }
    var midHeight: CGFloat { view.bounds.height * 0.6 }
    var maxTop: CGFloat { view.bounds.height - maxHeight }
    var maxHeight: CGFloat { view.bounds.height * 0.8 }

    func panToChangeSize(ofPanel panel: UIView, sender: UIPanGestureRecognizer) {
        let fingerY = sender.location(in: view).y
        let translationY = sender.translation(in: view).y
        switch sender.state {
        case .began: startPanningY = fingerY
        case .changed: duringPanning(panel: panel, translation: translationY)
        case .ended: endedPanning(panel: panel, to: fingerY)
        default: break
        }
    }

    func duringPanning(panel: UIView, translation: CGFloat) {
        panel.snp.updateConstraints { it in
            it.top.equalTo(startPanningY + translation)
        }
        panel.layoutIfNeeded()
    }

    func endedPanning(panel: UIView, to y: CGFloat) {
        var targetTop: CGFloat = midTop
        if y > midTop { // 面板很低，即将收起
            currentEditAgent?.stopEditing(immediately: false)
            return
        } else if y < maxTop { // 面板超过了最大高度
            targetTop = maxTop
        } else {
            // 这里的 startPanningY 最后会恢复成 -1，所以如果调用 resizePanel(panel:to:) 时，确保传入的 y 要相对于 -1 来取关系
            if startPanningY < y {
                targetTop = midTop
            } else {
                targetTop = maxTop
            }
        }
        UIView.animate(withDuration: 0.25) {
            panel.snp.updateConstraints { it in
                it.top.equalTo(targetTop)
            }
            panel.layoutIfNeeded()
        }
        startPanningY = -1
    }

    func resizePanel(panel: UIView, to level: PanelHeightLevel) {
        switch level {
        case .max: endedPanning(panel: panel, to: 0) // 0 > -1, targetTop = maxTop
        case .mid: endedPanning(panel: panel, to: -2) // -2 < -1, targetTop = midTop
        }
    }

    func resizePanel(panel: UIView, to y: CGFloat) {
        guard panel.superview != nil else { return }
        panel.snp.updateConstraints { it in
            it.top.equalTo(y)
        }
    }
}
