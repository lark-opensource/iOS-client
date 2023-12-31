//
//  UDScrollView.swift
//  Pods-UniverseDesignBreadcrumbDev
//
//  Created by 强淑婷 on 2020/8/23.
//

import Foundation
import UIKit

class UDScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        super.touchesShouldCancel(in: view)
        return true
    }
}
