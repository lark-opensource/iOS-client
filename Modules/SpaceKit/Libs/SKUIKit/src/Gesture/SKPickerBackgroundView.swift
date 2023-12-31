//
//  SKPickerBackgroundView.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/9/18.
//

import Foundation
import UniverseDesignColor
import RxSwift
import RxCocoa
import UIKit

open class SKPickerBackgroundView: UIView {
    public var isHighlighted: Bool = false {
        didSet {
            backgroundColor = currentBackgroundColor
        }
    }
    public var isHovered: Bool = false {
        didSet {
            backgroundColor = currentBackgroundColor
        }
    }

    public var pressedColor = UDColor.fillHover {
        didSet {
            backgroundColor = currentBackgroundColor
        }
    }
    public var hoverColor = UDColor.fillHover {
        didSet {
            backgroundColor = currentBackgroundColor
        }
    }
    public var standardBackgroundColor = UIColor.clear {
        didSet {
            backgroundColor = currentBackgroundColor
        }
    }

    public var currentBackgroundColor: UIColor {
        if isHighlighted {
            return pressedColor
        }
        if isHovered {
            return hoverColor
        }
        return standardBackgroundColor
    }
}
