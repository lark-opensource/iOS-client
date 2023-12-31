//
//  BaseCellSelectView.swift
//  Lark
//
//  Created by 吴子鸿 on 2017/7/14.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor

open class BaseTableViewCell: UITableViewCell {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupBackgroundViews()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupBackgroundViews()
    }
}

open class BaseCellSelectView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class BaseCellBackgroundView: UIView {
    public var highlightView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setupHighlightView() {
        highlightView?.removeFromSuperview()

        let backView = highlightView ?? UIView()
        backView.backgroundColor = UIColor.ud.bgBody
        backView.layer.cornerRadius = 6.0
        addSubview(backView)
        backView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 1.0, left: 6.0, bottom: 1.0, right: 6.0))
        }
        highlightView = backView
    }
}

extension UITableViewCell {
    public func setupBackgroundViews(highlightOn: Bool = false) {
        if highlightOn {
            let backView = BaseCellBackgroundView()
            backView.setupHighlightView()
            backgroundView = backView
        } else {
            backgroundView = BaseCellBackgroundView()
        }
        backgroundView?.backgroundColor = UIColor.ud.bgBody

        selectedBackgroundView = BaseCellSelectView()
    }

    public func setBackViewColor(_ color: UIColor) {
        if let backView = self.backgroundView as? BaseCellBackgroundView {
            backView.highlightView?.backgroundColor = color
        }
    }

    public func setBackViewLayout(_ insets: UIEdgeInsets?, _ cornerRadius: CGFloat?) {
        if let backView = self.backgroundView as? BaseCellBackgroundView {
            if let insets = insets {
                backView.highlightView?.snp.remakeConstraints { make in
                    make.edges.equalToSuperview().inset(insets)
                }
            }
            if let cornerRadius = cornerRadius {
                backView.highlightView?.layer.cornerRadius = cornerRadius
            }
        }
    }
}

// 用于设置页和群设置的cell，提供默认背景色以及hover时的颜色
open class BaseSettingCell: UITableViewCell {

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupBackgroundViews()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBackgroundViews()
    }

    public func setupBackgroundViews() {
        backgroundView = DefaultBackgroundView()
        selectedBackgroundView = DefaultSelectedBackgroundView()
    }

    public func DefaultSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.fillHover
        return view
    }

    public func DefaultBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }
}
