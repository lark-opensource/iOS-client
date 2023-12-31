//
//  ViewExtensions.swift
//  ByteViewMessenger
//
//  Created by lutingting on 2022/9/19.
//

import Foundation


import UIKit

extension UIStackView {
    @discardableResult
    func insertArrangedSubview(_ view: UIView, belowArrangedSubview subview: UIView?) -> Bool {
        guard let subview = subview else {
            insertArrangedSubview(view, at: 0)
            return true
        }
        guard let index = arrangedSubviews.firstIndex(of: subview) else {
            return false
        }
        insertArrangedSubview(view, at: index + 1)
        return true
    }

    @discardableResult
    func insertArrangedSubview(_ view: UIView, aboveArrangedSubview subview: UIView?) -> Bool {
        guard let subview = subview else {
            insertArrangedSubview(view, at: subviews.count)
            return true
        }
        guard let index = arrangedSubviews.firstIndex(of: subview) else {
            return false
        }
        insertArrangedSubview(view, at: index)
        return true
    }
}
