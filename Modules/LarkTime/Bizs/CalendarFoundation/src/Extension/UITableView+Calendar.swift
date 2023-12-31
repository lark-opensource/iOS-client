//
//  UITableView+Calendar.swift
//  Calendar
//
//  Created by zhouyuan on 2018/12/11.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewCell {
    public func addCustomHighlightedView() {
        let customHighlightView = UIView()
        customHighlightView.backgroundColor = UIColor.ud.N300.withAlphaComponent(0.5)
        self.selectedBackgroundView = customHighlightView
    }
}
