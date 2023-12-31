//
//  DriveTagLabel.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/4/12.
//

import UIKit

class DriveMarginLabel: UILabel {

    var margin: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        textAlignment = .center
    }
}

extension DriveMarginLabel {
    override public var intrinsicContentSize: CGSize {
        if margin == UIEdgeInsets.zero {
            return super.intrinsicContentSize
        }

        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        guard let boundingBox = text?.boundingRect(with: constraintRect,
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: [NSAttributedString.Key.font: self.font as Any],
                                                   context: nil) else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }

        if boundingBox.width == 0 || boundingBox.height == 0 {
            return CGSize.zero
        }
        return CGSize(width: boundingBox.width + margin.left + margin.right,
                      height: boundingBox.height + margin.top + margin.bottom)
    }
}
