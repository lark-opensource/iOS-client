//
//  DKMainViewController+DKFileCellContainerVC.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/14.
//

import UIKit

extension DKMainViewController: DKFileCellContainerVC {
    var topView: UIView? {
        if bannerStackView.superview != nil {
            return bannerStackView
        } else {
            return navigationBar
        }
    }
    var bottomView: UIView? {
        if commentBar.superview == nil {
            return nil
        }
        return commentBar
    }
}
