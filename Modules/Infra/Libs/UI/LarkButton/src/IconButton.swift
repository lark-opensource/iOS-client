//
//  IconButton.swift
//  LarkUIKit
//
//  Created by Kongkaikai on 2018/12/25.
//

import Foundation
import UIKit

public final class IconButton: UIButton {
    public var icon: UIImage? {
        get {
            return self.image(for: .normal)
        }
        set {
            setImage(newValue, for: .normal)
        }
    }

    public convenience init(icon: UIImage) {
        self.init(type: .custom)
        self.adjustsImageWhenDisabled = false
        self.adjustsImageWhenHighlighted = false
        setImage(icon, for: .normal)
    }

    public override var isEnabled: Bool {
        didSet {
            self.alpha = isEnabled ? 1 : 0.5
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            self.alpha = isHighlighted ? 0.7 : 1
        }
    }
}
