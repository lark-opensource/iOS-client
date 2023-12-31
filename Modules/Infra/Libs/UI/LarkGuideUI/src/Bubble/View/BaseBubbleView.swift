//
//  BaseBubbleView.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/6/6.
//

import UIKit
import Foundation
import LarkExtensions

// 提供气泡的圆角外形，带箭头
public class BaseBubbleView: UIView {
    /// 箭头方向，默认朝上
    var arrowDirection: BubbleArrowDirection = .up
    /// 箭头的偏移量
    private var arrowOffset: CGFloat = 0
    public var arrowView: BubbleViewArrow = BubbleViewArrow()
    /// 气泡内容容器
    var contentView: UIView = UIView()
    /// 气泡点击事件
    var contentTappedHandle: ((BaseBubbleView) -> Void)?
    /// 气泡背景色
    public var bubbleBackColor: UIColor? {
        didSet {
            contentView.backgroundColor = self.bubbleBackColor ?? Style.bgViewBackgroundColor
            arrowView.arrowColor = contentView.backgroundColor ?? Style.bgViewBackgroundColor
        }
    }
    /// 气泡阴影色
    public var bubbleShadowColor: UIColor? {
        didSet {
            contentView.layer.ud.setShadowColor(self.bubbleShadowColor ?? Style.bgViewShadowColor)
        }
    }

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    private func setupViews() {
        contentView.layer.cornerRadius = Layout.backgroundCornerRadius
        contentView.backgroundColor = self.bubbleBackColor ?? Style.bgViewBackgroundColor
        contentView.layer.ud.setShadowColor(self.bubbleShadowColor ?? Style.bgViewShadowColor)
        contentView.layer.shadowOpacity = Layout.bgViewShadowOpacity
        contentView.layer.shadowOffset = Layout.bgViewShadowOffset
        self.addSubview(contentView)

        contentView.snp.makeConstraints { (make) in
            make.leading.top.trailing.bottom.equalToSuperview()
        }

        arrowView.arrowColor = self.bubbleBackColor ?? Style.bgViewBackgroundColor
        self.addSubview(arrowView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BaseBubbleView {
    enum Layout {
        // 箭头和所指目标区域间距
        static let arrowSpacing: CGFloat = 8
        static let backgroundCornerRadius: CGFloat = 8
        static let defaultMaxWidth: CGFloat = 280
        static let bgViewShadowOpacity: Float = 0.3
        static let bgViewShadowOffset: CGSize = CGSize(width: 0, height: 5)
    }
    enum Style {
        static let bgViewShadowColor = UIColor.ud.shadowDefaultLg
        static let bgViewBackgroundColor = UIColor.ud.primaryFillHover
    }
}
