//
//  SplitViewController+Column.swift
//  SplitViewControllerDemo
//
//  Created by Yaoguoguo on 2022/8/15.
//

import UIKit
import Foundation

extension SplitViewController {
    public enum Column: Int {

        // The column for the primary view controller.
        case primary = 0

        // The column for the supplementary view controller.
        case supplementary = 1 // Valid for UISplitViewControllerStyleTripleColumn only

        // The column for the secondary, or detail, view controller.
        case secondary = 2

        // The column for the view controller that’s shown when the split view controller is collapsed.
        case compact = 3 // If a vc is set for this column, it will be used when the UISVC is collapsed, instead of stacking the vc’s for the Primary, Supplementary, and Secondary columns
    }
}
