//
//  UITableView.swift
//  Minutes_iOS
//
//  Created by panzaofeng on 2021/12/24.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

extension UITableView
{
    public func indexPathExists(indexPath:IndexPath) -> Bool {
        if indexPath.section >= 0 && indexPath.section < self.numberOfSections &&
            indexPath.row >= 0 && indexPath.row < self.numberOfRows(inSection: indexPath.section) {
            return true
        }
        return false
    }
}
