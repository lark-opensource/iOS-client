//
//  UIView+Border.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/5.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
extension UIView {

    public static let defaultLineWidth: CGFloat = 0.5

    @discardableResult
    public func addTopBorder(inset: UIEdgeInsets = .zero,
                             lineHeight: CGFloat = defaultLineWidth) -> UIView {
        addTopBorder(inset: inset, lineHeight: lineHeight, bgColor: nil)
    }

    @discardableResult
    public func addTopBorder(inset: UIEdgeInsets = .zero,
                             lineHeight: CGFloat = defaultLineWidth,
                             bgColor: UIColor?) -> UIView {
        assertLog(Thread.isMainThread)
        let border = self.borderView()
        self.addSubview(border)
        if let bgColor = bgColor {
            border.backgroundColor = bgColor
        }
        border.snp.makeConstraints { (make) in
            make.height.equalTo(lineHeight).priority(.low)
            make.left.equalToSuperview().offset(inset.left).priority(.low)
            make.right.equalToSuperview().offset(-inset.right).priority(.low)
            make.top.equalToSuperview().priority(.low)
        }
        return border
    }

    @discardableResult
    public func addBottomBorder(inset: UIEdgeInsets = .zero,
                                lineHeight: CGFloat = defaultLineWidth,
                                bgColor: UIColor? = nil) -> UIView {
        assertLog(Thread.isMainThread)
        let border = self.borderView()
        self.addSubview(border)
        if let bgColor = bgColor {
            border.backgroundColor = bgColor
        }
        border.snp.makeConstraints { (make) in
            make.height.equalTo(lineHeight).priority(.low)
            make.left.equalToSuperview().offset(inset.left).priority(.low)
            make.right.equalToSuperview().offset(-inset.right).priority(.low)
            make.bottom.equalToSuperview().priority(.low)
        }
        return border
    }

    @discardableResult
    // IG 统一 Cell bottom border, 左边留 16
    public func addCellBottomBorder() -> UIView {
        assertLog(Thread.isMainThread)
        let border = self.borderView()
        self.addSubview(border)
        border.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.left.equalToSuperview().inset(16)
            make.bottom.right.equalToSuperview()
        }
        return border
    }

    @discardableResult
    public func addRightBorder(inset: UIEdgeInsets = .zero,
                       lineWidth: CGFloat = defaultLineWidth) -> UIView {
        assertLog(Thread.isMainThread)
        let border = self.borderView()
        self.addSubview(border)
        border.snp.makeConstraints { (make) in
            make.width.equalTo(lineWidth).priority(.low)
            make.right.equalToSuperview().priority(.low)
            make.bottom.equalToSuperview().offset(-inset.bottom).priority(.low)
            make.top.equalToSuperview().offset(inset.top).priority(.low)
        }
        return border
    }

    private func borderView() -> UIView {
        let border = UIView(frame: .zero)
        border.backgroundColor = UIColor.ud.lineDividerDefault
        return border
    }
}
