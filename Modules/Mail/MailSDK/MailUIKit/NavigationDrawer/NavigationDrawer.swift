//
//  NavigationDrawer.swift
//  MailSDK
//
//  Created by majx on 2019/7/15.
//

import Foundation
import EENavigator

private class DrawerBackgroundView: UIView {
    var leftEdgePanSelector = #selector(DrawerBackgroundView.handleLeftEdgeScreenPan(ges:))
    private let leftEdgePanAction: (UIScreenEdgePanGestureRecognizer) -> Void
    private let tapedAction:() -> Void
    private let panAction: (UIPanGestureRecognizer) -> Void
    private var bg: UIControl = UIControl()
    private(set) lazy var alphaView: UIView = {
        bg.backgroundColor = UIColor.ud.bgMask
        bg.frame = self.bounds
        bg.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        insertSubview(bg, at: 0)
        return bg
    }()

    init(leftEdgePanAction: @escaping (UIScreenEdgePanGestureRecognizer) -> Void,
         tapedAction: @escaping () -> Void,
         panAction: @escaping (UIPanGestureRecognizer) -> Void) {
        self.leftEdgePanAction = leftEdgePanAction
        self.tapedAction = tapedAction
        self.panAction = panAction
        super.init(frame: CGRect.zero)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(ges:)))
        addGestureRecognizer(panGesture)
        self.alphaView.alpha = 0.0

    }

    override func layoutSubviews() {
        self.bg.frame = self.bounds
    }

    @objc
    private func tapped() {
        tapedAction()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func handleLeftEdgeScreenPan(ges: UIScreenEdgePanGestureRecognizer) {
        leftEdgePanAction(ges)
    }

    @objc
    private func handlePanGesture(ges: UIPanGestureRecognizer) {
        panAction(ges)
    }
}
