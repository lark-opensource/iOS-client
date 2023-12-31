//
//  CalendarCornerCell.swift
//  CTFoundation
//
//  Created by JackZhao on 2023/6/1.
//

import Foundation

// 可设置顶部或者底部的左右两边圆角的cell
open class CalendarCornerCell: UITableViewCell {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var roundingCorners: UIRectCorner?

    // 设置顶部或者底部的左右两边圆角
    /// 输入: row、数据源数量
    /// 输出: 设置的圆角结果
    @discardableResult
    public func setHorizontalConrner(row: Int, dataCount: Int) -> UIRectCorner? {
        // 判断是否只有一个cell
        if row == 0, row == dataCount - 1 {
            let rectCorner: UIRectCorner = [.allCorners]
            self.roundingCorners = rectCorner
            return rectCorner
        }
        // 判断是否是第一个cell
        if row == 0 {
            let rectCorner: UIRectCorner = [.topLeft, .topRight]
            self.roundingCorners = rectCorner
            return rectCorner
        }
        // 判断是否是最后一个cell
        if row == dataCount - 1 {
            let rectCorner: UIRectCorner = [.bottomLeft, .bottomRight]
            self.roundingCorners = rectCorner
            return rectCorner
        }
        self.roundingCorners = nil
        return nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if let roundingCorners = roundingCorners {
            let path = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: roundingCorners,
                                    cornerRadii: CGSize(width: 10, height: 10))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
        } else {
            self.layer.mask = nil
        }
    }
}
