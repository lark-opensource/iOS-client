//
//  UIScrollView+Bitable.swift
//  SKBitable
//
//  Created by yinyuan on 2023/10/9.
//

import Foundation

extension UIScrollView {
    
    var btScrolledToTop: Bool {
        let yOffset = self.contentOffset.y + self.contentInset.top
        return yOffset <= 0
    }
}
