//
//  TitleNaviBar.swift
//  Lark
//
//  Created by ChalrieSu on 20/03/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkBadge
import UniverseDesignColor

/// 新UI导航栏
open class TitleNaviBar: UIView {
    /// 导航栏高度
    open var naviBarHeight: CGFloat {
        return 44
    }

    /// 导航栏宽度
    open var naviBarWidth: CGFloat = 0

    /// 导航栏标题 font
    open var titleFontSize: CGFloat {
        return 17
    }

    /// 导航栏font名字
    open var titleFontName: String? {
        return nil
    }

    /// 设置titleString的时候，NavigationBar会自动创建一个label当做titleView
    public var titleString: String? {
        didSet {
            guard let titleString = titleString else { return }
            titleView = TitleNaviBar.createTitleLabel(withTitleString: titleString,
                                                      fontSize: titleFontSize,
                                                      fontName: titleFontName)
        }
    }

    open override var backgroundColor: UIColor? {
        didSet {
            statusBarPlaceHolderView.backgroundColor = backgroundColor
            contentview.backgroundColor = backgroundColor
        }
    }

    /// titleView，需要调用方自行设置其宽，高约束
    public var titleView: UIView {
        willSet {
            titleView.removeFromSuperview()
        }
        didSet {
            addTapGestureToTitleView()
            contentview.addSubview(titleView)
            titleView.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.left.greaterThanOrEqualTo(_leftStackView.snp.right)
                make.right.lessThanOrEqualTo(_rightStackView.snp.left)
            }
        }
    }

    /// titleView点击事件
    public var titleViewTappedBlock: ((TitleNaviBar) -> Void)?
    /// titleView点击手势
    public let titleViewTapGestureRecognizer = UITapGestureRecognizer()
    /// 状态栏占位图
    private let statusBarPlaceHolderView = UIView()
    /// 出去状态栏的区域
    public let contentview = UIView()
    /// 代表内容区域的顶部
    public var contentTop: ConstraintItem {
        return contentview.snp.top
    }

    /// 左边按钮stackView
    let _leftStackView = UIStackView()
    /// 隐藏UIStackView类型，防止外界通过stackView直接addArrangedSubview
    public var leftStackView: UIView { return _leftStackView }

    /// 右边按钮stackView
    let _rightStackView = UIStackView()
    /// 隐藏UIStackView类型，防止外界通过stackView直接addArrangedSubview
    public var rightStackView: UIView { return _rightStackView }

    public convenience init(titleString: String,
                            leftBarItems: [TitleNaviBarItem] = [],
                            rightBarItems: [TitleNaviBarItem] = []) {
        let titleLabel = TitleNaviBar.createTitleLabel(withTitleString: titleString)
        self.init(titleView: titleLabel,
                  leftBarItems: leftBarItems,
                  rightBarItems: rightBarItems)
        if let fontName = titleFontName {
            titleLabel.font = UIFont(name: fontName, size: titleFontSize)
        } else {
            titleLabel.font = UIFont.boldSystemFont(ofSize: titleFontSize)
        }
    }

    public init(titleView: UIView,
                leftBarItems: [TitleNaviBarItem] = [],
                rightBarItems: [TitleNaviBarItem] = []) {
        self.titleView = titleView
        super.init(frame: CGRect.zero)

        backgroundColor = UIColor.ud.bgBody

        addSubview(statusBarPlaceHolderView)

        statusBarPlaceHolderView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            // iPadOS 13 之后，如果是模态弹窗，view 不会触及到顶部，不会调用`safeAreaInsetsDidChange`，所以需要先将高度置 0
            make.height.equalTo(0)
        }

        contentview.clipsToBounds = true
        addSubview(contentview)
        contentview.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(statusBarPlaceHolderView.snp.bottom)
            make.height.equalTo(self.naviBarHeight)
            make.bottom.equalToSuperview()
        }

        leftItems = leftBarItems
        rightItems = rightBarItems

        titleViewTapGestureRecognizer.addTarget(self, action: #selector(tapGestureInvoked))
        addTapGestureToTitleView()

        contentview.addSubview(titleView)
        titleView.lu.softer()

        contentview.addSubview(_leftStackView)
        _leftStackView.lu.harder()

        contentview.addSubview(_rightStackView)
        _rightStackView.lu.harder()

        titleView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.right.lessThanOrEqualTo(_rightStackView.snp.left)
            make.left.greaterThanOrEqualTo(_leftStackView.snp.right)
        }

        _leftStackView.axis = .horizontal
        _leftStackView.alignment = .center
        _leftStackView.distribution = .fill
        _leftStackView.spacing = 24
        _leftStackView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(12)
        }

        _rightStackView.axis = .horizontal
        _rightStackView.alignment = .center
        _rightStackView.distribution = .fill
        _rightStackView.spacing = 24
        _rightStackView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
    }

    open override func safeAreaInsetsDidChange() {
        statusBarPlaceHolderView.snp.updateConstraints({ (make) in
            make.height.equalTo(self.safeAreaInsets.top)
        })
    }

    open override func layoutSubviews() {
        if naviBarWidth != self.bounds.width {
            naviBarWidth = self.bounds.width
            let padding = calcButtonsStackPadding()
            _leftStackView.snp.updateConstraints {
                $0.left.equalToSuperview().offset(padding)
            }
            _rightStackView.snp.updateConstraints {
                $0.right.equalToSuperview().offset(-padding)
            }
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func tapGestureInvoked() {
        titleViewTappedBlock?(self)
    }

    private func addTapGestureToTitleView() {
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(titleViewTapGestureRecognizer)
    }

    private static func createTitleLabel(
        withTitleString titleString: String,
        fontSize: CGFloat? = nil,
        fontName: String? = nil
    ) -> UILabel {
        let label = UILabel()
        label.text = titleString
        label.textColor = UIColor.ud.textTitle
        if let fontSize = fontSize {
            if let fontName = fontName {
                label.font = UIFont(name: fontName, size: fontSize)
            } else {
                label.font = UIFont.boldSystemFont(ofSize: fontSize)
            }
        }
        return label
    }

    /// 根据导航栏宽度计算导航栏控件离两侧距离
    open func calcButtonsStackPadding() -> Int {
        // 设计希望不影响iPhone的视图，Pro Max宽度为428pt，iPad mini 竖2/3分屏为438pt，暂时以435作为分界
        return self.bounds.width > 435 ? 20 : 12
    }
}
