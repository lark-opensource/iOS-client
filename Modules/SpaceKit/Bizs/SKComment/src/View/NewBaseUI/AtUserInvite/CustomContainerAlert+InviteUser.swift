//
//  CustomContainerAlert+InviteUser.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/10/29.
//

import Foundation
import SKCommon
import SpaceInterface

extension CustomContainerAlert {
    public class func getInviteTipsViewInPopoverStyle(delegate: AtUserInviteViewDelegate?, at: AtInfo, docsInfo: DocsInfo?, rectInView: CGRect) -> UIViewController {
        let alertVC = CustomContainerAlert()
        let arrowDirection: UIPopoverArrowDirection = .down
        let tipViewWidth: CGFloat = 375
        let inviteView = AtUserInviteView()
        inviteView.popoverInVC = alertVC
        inviteView.atUserInfo = at
        let atInviteConfig = AtUserInviteViewConfig.congfigWithAt(at, docsInfo: docsInfo)
        inviteView.showWithConfig(atInviteConfig, delegte: delegate)
        alertVC.setTipsView(inviteView, arrowUp: (arrowDirection == .up ? true : false))
        let widthConstraint = NSLayoutConstraint(item: inviteView,
                                                 attribute: .width,
                                                 relatedBy: .equal,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1,
                                                 constant: tipViewWidth)
        inviteView.addConstraint(widthConstraint)
        let size = inviteView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        inviteView.removeConstraint(widthConstraint)
        alertVC.preferredContentSize = CGSize(width: tipViewWidth, height: size.height)
        alertVC.modalPresentationStyle = .popover
        alertVC.popoverPresentationController?.sourceRect = rectInView
        alertVC.popoverPresentationController?.permittedArrowDirections = arrowDirection
        return alertVC
    }
}
