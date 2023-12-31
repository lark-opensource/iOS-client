//
//  MenuTitleAdditionView.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/24.
//

import Foundation
import UIKit
import SnapKit

/// 标题附加视图，显示一串文本，文本被分为三段，中间的文本会因空间不足而自动缩进
public final class MenuTitleAdditionView: UIView {

    /// 左边的文本
    private var leftTitleLabel: UILabel?
    /// 中间的文本
    private var middleTitleLabel: UILabel?
    /// 右边的文本
    private var rightTitleLabel: UILabel?
    /// 三个文本的Stack容器
    private var titleStackView: UIStackView?

    /// 字号
    private var titleFont = UIFont.systemFont(ofSize: 12)
    /// 颜色
    private var titleColor = UIColor.menu.additionTitleColor

    /// 容器底部边距
    private let labelBottomSpacing: CGFloat = 12
    /// 容器顶部边距
    private let labelTopSpacing: CGFloat = 12
    /// 容器左边距
    private let labelLeftSpacing: CGFloat = 24
    /// 容器右边距
    private let labelRightSpacing: CGFloat = 24
    /// 容器高度
    private let labelHeight: CGFloat = 20

    /// 初始化标题视图
    /// - Parameters:
    ///   - leftTitle: 左边的文本
    ///   - middleTitle: 中间的文本
    ///   - rightTitle: 右边的文本
    @objc
    public init(leftTitle: String, middleTitle: String, rightTitle: String) {
        super.init(frame: .zero)

        setupSubViews()
        setupSubViewsStaticConstrain()

        setTitleText(leftTitle: leftTitle, middleTitle: middleTitle, rightTitle: rightTitle)
    }

    /// 初始化视图
    private func setupSubViews() {
        setupStackView()
        setupTitleLabel()
    }

    /// 初始化约束
    private func setupSubViewsStaticConstrain() {
        setupTitleStackStaticConstrain()
        setupTitleLeftLabelStaticConstrain()
        setupTitleRightLabelStaticConstrain()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化容器
    private func setupStackView() {
        if let stackView = self.titleStackView {
            stackView.removeFromSuperview()
            self.titleStackView = nil
        }
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 0
        self.titleStackView = stackView
        self.addSubview(stackView)
    }

    /// 初始化文本
    private func setupTitleLabel() {
        if let label = self.leftTitleLabel {
            label.removeFromSuperview()
            self.leftTitleLabel = nil
        }
        if let label = self.middleTitleLabel {
            label.removeFromSuperview()
            self.middleTitleLabel = nil
        }
        if let label = self.rightTitleLabel {
            label.removeFromSuperview()
            self.rightTitleLabel = nil
        }

        guard let stackView = self.titleStackView else {
            return
        }

        let leftLabel = UILabel()
        setupUILabel(for: leftLabel)
        self.leftTitleLabel = leftLabel
        stackView.addArrangedSubview(leftLabel)

        let middleLabel = UILabel()
        setupUILabel(for: middleLabel, isOmit: true)
        self.middleTitleLabel = middleLabel
        stackView.addArrangedSubview(middleLabel)

        let rightlabel = UILabel()
        setupUILabel(for: rightlabel)
        self.rightTitleLabel = rightlabel
        stackView.addArrangedSubview(rightlabel)
    }

    /// 帮助方法，快速定制标签样式
    /// - Parameters:
    ///   - label: 需要定制样式的标签
    ///   - isOmit: 标签内容超出长度是否进行省略
    private func setupUILabel(for label: UILabel, isOmit: Bool = false) {
        label.lineBreakMode = isOmit ? .byTruncatingTail : .byClipping
        label.textColor = self.titleColor
        label.font = self.titleFont
        label.textAlignment = .center
        label.numberOfLines = 1
    }

    /// 初始化容器约束
    private func setupTitleStackStaticConstrain() {
        guard let stack = self.titleStackView else {
            return
        }
        stack.snp.makeConstraints {
            make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-self.labelBottomSpacing)
            make.top.equalToSuperview().offset(self.labelTopSpacing)
            make.height.equalTo(self.labelHeight)
            make.width.equalTo(0)
        }
    }

    /// 初始化左边的标签约束
    private func setupTitleLeftLabelStaticConstrain() {
        guard let leftLabel = self.leftTitleLabel else {
            return
        }
        leftLabel.snp.makeConstraints {
            make in
            make.width.equalTo(0)
        }
    }

    /// 初始化右边的标签约束
    private func setupTitleRightLabelStaticConstrain() {
        guard let rightLabel = self.rightTitleLabel else {
            return
        }
        rightLabel.snp.makeConstraints {
            make in
            make.width.equalTo(0)
        }
    }

    /// 设置标签的字体
    /// - Parameter font: 新的字体
    @objc
    public func setTitleFont(for font: UIFont) {
        self.titleFont = font
        self.leftTitleLabel?.font = font
        self.middleTitleLabel?.font = font
        self.rightTitleLabel?.font = font

        setNeedsLayout()
        layoutIfNeeded()
    }

    /// 设置标签的颜色
    /// - Parameter color: 新的颜色
    @objc
    public func setTitleColor(for color: UIColor) {
        self.titleColor = color
        self.leftTitleLabel?.textColor = color
        self.middleTitleLabel?.textColor = color
        self.rightTitleLabel?.textColor = color
    }

    /// 设置标签的文本
    /// - Parameters:
    ///   - leftTitle: 新的左部文本
    ///   - middleTitle: 新的中部文本
    ///   - rightTitle: 新的右部文本
    @objc
    public func setTitleText(leftTitle: String, middleTitle: String, rightTitle: String) {

        self.leftTitleLabel?.text = leftTitle
        self.middleTitleLabel?.text = middleTitle
        self.rightTitleLabel?.text = rightTitle

        setNeedsLayout()
        layoutIfNeeded()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateDynamicConstrain()
    }

    /// 更新约束
    private func updateDynamicConstrain() {
        updateStackViewDynamicConstrain()
    }

    /// 更新容器的约束
    private func updateStackViewDynamicConstrain() {
        guard let left = self.leftTitleLabel,
              let right = self.rightTitleLabel,
              let middle = self.middleTitleLabel,
              let stack = self.titleStackView else {
            return
        }

        let reallyLeftWidth = left.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))).width
        let reallyRightWidth = right.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))).width
        let reallyMiddleWidth = middle.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))).width

        // 去掉左右边距后的允许宽度
        let allowWidth = max(self.frame.width - self.labelLeftSpacing - self.labelRightSpacing, 0)

        let reallyStackWidth = reallyLeftWidth + reallyRightWidth + reallyMiddleWidth
        let stackWidth = min(reallyStackWidth, allowWidth)

        let leftWidth = min(reallyLeftWidth, stackWidth)
        let rightWidth = min(stackWidth - leftWidth, reallyRightWidth)
        stack.snp.updateConstraints {
            make in
            make.width.equalTo(stackWidth)
        }
        left.snp.updateConstraints {
            make in
            make.width.equalTo(leftWidth)
        }
        right.snp.updateConstraints {
            make in
            make.width.equalTo(rightWidth)
        }
    }
}

extension MenuTitleAdditionView: MenuForecastSizeProtocol {
    public func forecastSize() -> CGSize {
        var labelWidth: CGFloat = 0
        for label in [leftTitleLabel, middleTitleLabel, rightTitleLabel] {
            if let labelNoNil = label {
                labelWidth = labelNoNil.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))).width
            }
        }
        let totalWidth = labelWidth + self.labelLeftSpacing + self.labelRightSpacing
        let totalHeight = self.labelHeight + self.labelTopSpacing + self.labelBottomSpacing
        return CGSize(width: totalWidth, height: totalHeight)
    }

    public func reallySize(for suggestionSize: CGSize) -> CGSize {
        return forecastSize()
    }
}
