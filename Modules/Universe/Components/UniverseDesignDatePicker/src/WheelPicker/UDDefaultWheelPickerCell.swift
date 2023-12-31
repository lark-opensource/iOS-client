//
//  UDDatePickerCell.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2020/11/20.
//

import Foundation
import UIKit
import SnapKit

/// 自定义滚轮 cell 需要实现该协议，倘有自定义动画需要，则实现 animate 方法
public protocol UDWheelPickerCell: UIView {
    var labelAttributedString: NSAttributedString? { get set }
    func animate(frameInContainer: CGRect, supperView: UIView, rowNum: Int)
}

extension UDWheelPickerCell {
    func animate(frameInContainer: CGRect, supperView: UIView, rowNum: Int) {}
}

/// 滚轮 cell 默认实现
public final class UDDefaultWheelPickerCell: UIView, UDWheelPickerCell {
    public var labelAttributedString: NSAttributedString? {
        didSet {
            label.attributedText = labelAttributedString
        }
    }

    private let label = UILabel()
    /// 滚轮默认 cell 构造方法
    /// - Parameters:
    ///   - leadingOffsetMin: textLabel left padding, active when textAlignment == .left
    ///   - trailingOffsetMin: textLabel right padding, active when textAlignment == .right
    ///   - textAlignment: textLabel.textAlignment
    public init(leadingOffsetMin: CGFloat = 12,
                trailingOffsetMin: CGFloat = -12,
                textAlignment: NSTextAlignment = .center) {
        super.init(frame: .zero)
        addSubview(label)
        label.textAlignment = textAlignment
        label.snp.makeConstraints({make in
            make.centerY.equalToSuperview()
            if textAlignment == .left {
                make.left.equalToSuperview().offset(leadingOffsetMin)
            } else if textAlignment == .right {
                make.right.equalToSuperview().offset(trailingOffsetMin)
            } else {
                make.centerX.equalToSuperview()
            }
        })
    }

    /// 缩放动画实现方法，业务方无需调用
    /// - Parameters:
    ///   - frameInContainer: cellFrame
    ///   - supperView: supperView of cell
    ///   - rowNum: 滚轮行数
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
