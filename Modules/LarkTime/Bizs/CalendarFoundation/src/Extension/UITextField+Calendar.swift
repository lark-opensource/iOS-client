//
//  UITextField+Calendar.swift
//  Calendar
//
//  Created by zhuchao on 2018/4/10.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignIcon

extension UITextField {
    public func addSearchIcon() {
        let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 24))

        let iconView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.searchOutlined).renderColor(with: .n3))
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 12, y: 0, width: 24, height: 24)
        wrapperView.addSubview(iconView)
        self.leftView = wrapperView
        self.leftViewMode = .always
    }
}
