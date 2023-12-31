//
//  UITableViewCell+Ex.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/12.
//

import UIKit
import Foundation

extension UITableViewCell {

    static var identifier: String {
        return String(describing: self)
    }

}

extension UITableViewHeaderFooterView {

    static var identifier: String {
        return String(describing: self)
    }

}
