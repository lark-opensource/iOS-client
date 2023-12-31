//
//  UIScrollView+BounceDetection.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/20.
//

import UIKit

extension UIScrollView {
    public var isBouncing: Bool {
        return isBouncingTop || isBouncingLeft || isBouncingBottom || isBouncingRight
    }
    public var isBouncingTop: Bool {
        return contentOffset.y < -contentInset.top
    }
    public var isBouncingLeft: Bool {
        return contentOffset.x < -contentInset.left
    }
    public var isBouncingBottom: Bool {
        let contentFillsScrollEdges = contentSize.height + contentInset.top + contentInset.bottom >= bounds.height
        return contentFillsScrollEdges && contentOffset.y > contentSize.height - bounds.height + contentInset.bottom
    }
    public var isBouncingRight: Bool {
        let contentFillsScrollEdges = contentSize.width + contentInset.left + contentInset.right >= bounds.width
        return contentFillsScrollEdges && contentOffset.x > contentSize.width - bounds.width + contentInset.right
    }
}
