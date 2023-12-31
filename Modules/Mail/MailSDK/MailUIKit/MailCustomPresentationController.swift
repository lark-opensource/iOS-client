//
//  MailCustomPresentationController.swift
//  MailSDK
//
//  Created by Quanze Gao on 2023/4/28.
//

import Foundation

/// 自定义 present，避免影响 navigation bar 显示/隐藏
class MailCustomPresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return CGRect.zero }
        return containerView.bounds
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}
