//
//  UIView+Extension.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/24.
//

import UIKit

extension UIView {

    var parentViewController: UIViewController? {
        weak var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController                
            }
        }
        return nil
    }
}
