//
//  MBProgressHUD+Calendar.swift
//  Calendar
//
//  Created by zhuchao on 2018/2/7.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

import MBProgressHUD

final class CDProgressHUD {
    @discardableResult
    static func showTextHUD(hint: String, on view: UIView, duration: Double = 0.6, yOffset: CGFloat? = 0) -> MBProgressHUD {
        let HUD = MBProgressHUD(view: view)
        view.addSubview(HUD)
        HUD.mode = .text
        HUD.margin = 20
        HUD.minSize = CGSize(width: 120, height: 30)
        HUD.bezelView.style = .solidColor
        HUD.bezelView.backgroundColor = UIColor.ud.textTitle.withAlphaComponent(0.8)
        HUD.contentColor = UIColor.ud.bgBody
        HUD.label.text = hint
        HUD.label.numberOfLines = 0
        HUD.label.font = UIFont.systemFont(ofSize: 17)
        HUD.bezelView.center = HUD.superview!.center
        HUD.layoutIfNeeded()
        HUD.show(animated: true)
        HUD.hide(animated: true, afterDelay: duration)
        HUD.removeFromSuperViewOnHide = true
        return HUD
    }
}
