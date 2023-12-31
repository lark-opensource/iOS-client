//
//  CheckInPickerCell.swift
//  Calendar
//
//  Created by huoyunjie on 2022/10/19.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignDatePicker

public final class CheckInPickerCell: UIView, UDWheelPickerCell {
    public var labelAttributedString: NSAttributedString? {
        didSet {
            label.attributedText = labelAttributedString
        }
    }

    private let label = UILabel()

    public init() {
        super.init(frame: .zero)
        addSubview(label)
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.snp.makeConstraints({make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(12)
        })
    }

    public func animate(frameInContainer: CGRect, supperView: UIView, rowNum: Int) {
        // 居中框 frame ,也就是变化参照物（画出框来，边框处即是变化的地方）
        let cellScaleRect = supperView.frame.insetBy(dx: 0, dy: CGFloat(48 * (rowNum / 2)))
        let intersection = frameInContainer.intersection(cellScaleRect)
        let calculatedcellScale = 0.8235 + (1.0 - 0.8235) * intersection.size.height / frameInContainer.size.height
        let transform = CGAffineTransform(scaleX: calculatedcellScale, y: calculatedcellScale)
        guard label.transform != transform else { return }
        label.transform = transform
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
