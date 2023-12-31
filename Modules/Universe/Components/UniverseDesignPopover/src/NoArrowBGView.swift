//
//  NoArrowBGView.swift
//  UniverseDesignPopover
//
//  Created by 白镜吾 on 2023/6/29.
//

import UIKit

public class NoArrowPopoverBackgroundView: UIPopoverBackgroundView {
    public override var arrowOffset: CGFloat {
        get { return 0 }
        set { }
    }

    public override var arrowDirection: UIPopoverArrowDirection {
        get { return .any }
        set { }
    }

    public override class func contentViewInsets() -> UIEdgeInsets {
        return .zero
    }

    public override class func arrowHeight() -> CGFloat {
        return 0
    }

    public override class func arrowBase() -> CGFloat {
        return 0
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowOpacity = 0
    }
}
