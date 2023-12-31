//
//  UIStackView+Calendar.swift
//  CalendarFoundation
//
//  Created by Rico on 2022/3/7.
//

import UIKit

public extension UIStackView {
    func clearSubviews() {
        for subview in arrangedSubviews {
            subview.removeFromSuperview()
            removeArrangedSubview(subview)
        }
    }
}
