//
//  SKBlurPanelController.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/8/24.
//

import Foundation
import SnapKit
import UniverseDesignColor

/// 提供半透明效果的面板
public typealias SKTranslucentPanelController = SKBlurPanelController
open class SKBlurPanelController: SKPanelController {

    private lazy var blurEffectView: SKBlurEffectView = {
        let view = SKBlurEffectView()
        view.set(cornerRadius: 12, corners: .top)
        return view
    }()

    public override func setupPopover(sourceView: UIView, direction: UIPopoverArrowDirection) {
        super.setupPopover(sourceView: sourceView, direction: direction)
        popoverPresentationController?.backgroundColor = .clear
    }

    open override func setupUI() {
        super.setupUI()
        view.insertSubview(blurEffectView, belowSubview: containerView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalTo(containerView.snp.edges)
        }
    }

    open override func transitionToRegularSize() {
        super.transitionToRegularSize()
        blurEffectView.updateMaskColor(isPopover: true)
        containerView.backgroundColor = .clear
        blurEffectView.snp.remakeConstraints { make in
            // 延伸到 SafeArea 下，挡住 popover 小箭头
            make.edges.equalToSuperview()
        }
    }

    open override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        blurEffectView.updateMaskColor(isPopover: false)
        containerView.backgroundColor = .clear
        blurEffectView.snp.remakeConstraints { make in
            make.edges.equalTo(containerView.snp.edges)
        }
    }
}
