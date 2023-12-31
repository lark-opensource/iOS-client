//
//  UDDrawerTransitionInteractPresent.swift
//  UniverseDesignDrawer
//
//  Created by 袁平 on 2021/3/12.
//

import UIKit
import Foundation
class UDDrawerTransitionInteractPresent: UIPercentDrivenInteractiveTransition, UIGestureRecognizerDelegate {
    weak var transitionManager: UDDrawerTransitionManager?
    var isAnimating: Bool = false
    private var edgeGestureArray: [UIScreenEdgePanGestureRecognizer] = []
    private let direction: UDDrawerDirection
    private var present: (() -> Void)?
    private var contentWidth: CGFloat?
    // 记录手势是否可点击
    private var gestureEnable: Bool = true
    private let gestureName = "UDDrawerTransitionInteractPresentGesture"

    init(direction: UDDrawerDirection) {
        self.direction = direction
    }

    func addDrawerEdgeGesture(to: UIView, present: @escaping () -> Void, contentWidth: CGFloat) {
        self.present = present
        self.contentWidth = contentWidth
        // 判断view是否添加过侧滑手势
        if (to.gestureRecognizers?.contains(where: { $0.name == gestureName })) != nil {
            return
        }
        let edgeGesture = UIScreenEdgePanGestureRecognizer()
        edgeGesture.edges = direction == .left ? .left : .right
        edgeGesture.addTarget(self, action: #selector(handleEdgePan(ges:)))
        edgeGesture.delegate = self
        edgeGesture.isEnabled = gestureEnable
        edgeGesture.name = gestureName
        to.addGestureRecognizer(edgeGesture)
        edgeGestureArray.append(edgeGesture)
    }

    func updateGestureEnable(isEnabled: Bool) {
        gestureEnable = isEnabled
        guard !edgeGestureArray.isEmpty else {
            return
        }
        self.edgeGestureArray.forEach( {$0.isEnabled = isEnabled} )
    }

    // Drawer手势优先级最高
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if edgeGestureArray.contains(where: { $0 == gestureRecognizer }) {
            return true
        }
        return false
    }

    @objc
    private func handleEdgePan(ges: UIScreenEdgePanGestureRecognizer) {
        guard let contentW: CGFloat = self.contentWidth else { return }
        if case .began = ges.state {
            isAnimating = true
            transitionManager?.state = .showing
            present?()
            return
        }
        var offset = ges.translation(in: ges.view?.superview).x
        var velocity = ges.velocity(in: ges.view?.superview).x
        if direction == .left {
            offset = min(contentW, max(0, offset))
        } else {
            offset = -min(0, max(-contentW, offset))
            velocity = -velocity
        }

        let progress = min(1.0, offset / contentW)
        switch ges.state {
        case .changed:
            update(progress)
        case .ended, .cancelled, .failed:
            isAnimating = false
            let offsetWorks = offset > contentW * UDDrawerValues.offsetThreshold
            let velocityWorks = velocity > UDDrawerValues.velocityThreshold
            if offsetWorks || velocityWorks {
                completionCurve = .easeIn
                transitionManager?.state = .shown
                finish()
            } else {
                completionCurve = .easeOut
                transitionManager?.state = .hidden
                cancel()
            }
        default: break
        }
    }
}
