//
//  UIView+LarkBadge.swift
//  LarkBadge
//
//  Created by 朱衡 on 2018/10/9.
//  Copyright © 2018年 朱衡. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import RxSwift
import SnapKit
import RxCocoa

extension UIView: LarkBadgeProtocol {

    var badge: UIImageView? {
        set {
            objc_setAssociatedObject(self, &BadgeObjectKey.badge, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &BadgeObjectKey.badge) as? UIImageView
        }
    }

    func badgeInit() {
        let badge = UIImageView()
        badge.isHidden = true
        self.addSubview(badge)
        self.bringSubviewToFront(badge)
        badge.snp.makeConstraints { (make) in
            make.width.equalTo(BadgeDefaultSetting.redDotSize.width)
            make.height.equalTo(BadgeDefaultSetting.redDotSize.height)
            make.top.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(0).priority(.low)
        }
        self.badge = badge
    }

    var badgeStyle: BadgeStyle {
        set {
            switch newValue {
            case .none:
                self.badge?.removeFromSuperview()
            case .redDot:
                badgeInit()
                badge?.layer.masksToBounds = true
                self.badge?.layer.cornerRadius = 4
            case .new:
                badgeInit()
                badge?.layer.cornerRadius = 0
                badge?.layer.masksToBounds = false
                badge?.backgroundColor = UIColor.clear
            }

            objc_setAssociatedObject(self, &BadgeObjectKey.badgeStyle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &BadgeObjectKey.badgeStyle) as? BadgeStyle ?? .none
        }
    }

    func setBadgeStyle(_ style: BadgeStyle) {
        self.badgeStyle = style
    }

    func setBadgeSize(_ size: CGSize) {
        if let badge = self.badge {
            if self.badgeStyle == .redDot {
                self.badge?.layer.cornerRadius = size.width / 2
            }

            badge.snp.updateConstraints { (make) in
                make.width.equalTo(size.width)
                make.height.equalTo(size.height)
            }
        } else {
            assertionFailureLog("no badge view")
        }
    }

    func setBadgeImageName(_ name: String) {
        assertLog(badgeStyle == .new, "no badge view")
        if let badge = self.badge {
            badge.image = UIImage.cd.image(named: name).withRenderingMode(.alwaysOriginal)
        } else {
            assertionFailureLog("no badge view")
        }
    }

    func setBadgeTopRightOffset(_ point: CGPoint) {
        self.badge?.snp.updateConstraints { (make) in
            make.top.equalToSuperview().offset(point.y)
            make.right.equalToSuperview().offset(point.x).priority(.low)
        }
    }

    func setBadgeEqualCenterY(_ rightOffset: CGFloat = -BadgeDefaultSetting.redDotSize.width) {
        self.badge?.snp.remakeConstraints { (make) in
            make.width.equalTo(BadgeDefaultSetting.redDotSize.width)
            make.height.equalTo(BadgeDefaultSetting.redDotSize.height)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(rightOffset).priority(.low)
        }
    }

    func setRedDotColor(_ color: UIColor) {
        assertLog(badgeStyle == .redDot, "no badge view")
        if let badge = self.badge {
            badge.backgroundColor = color
        } else {
            assertionFailureLog("no badge view")
        }
    }

    func changeStatus(_ status: BadgeStatus) {
        switch status {
        case .show:
            self.badge?.isHidden = false
        case .hidden:
            self.badge?.isHidden = true
        }
    }

}
