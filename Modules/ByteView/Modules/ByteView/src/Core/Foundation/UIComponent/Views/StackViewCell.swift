//
//  StackViewCell.swift
//  ByteView
//
//  Created by wulv on 2022/3/1.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

final class VStackView: UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.axis = .vertical
        self.alignment = .leading
    }

    convenience init(spacing: CGFloat) {
        self.init(frame: .zero)
        self.spacing = spacing
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HStackView: UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.axis = .horizontal
        self.alignment = .center
    }

    convenience init(spacing: CGFloat) {
        self.init(frame: .zero)
        self.spacing = spacing
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIStackView {
    @discardableResult
    fileprivate func add(_ view: UIView) -> UIStackView {
        addArrangedSubview(view)
        return self
    }
}

/// 提供左、中、右三个stack view的样式框架，数字表示间隙
/// |---------------------------------------------------------|
/// |-16-LeftStackView-12-CenterStackView-8-RightStackView-16-｜
/// |---------------------------------------------------------|
class StackViewCell<CellModel>: UITableViewCell {
    final var cellModel: CellModel?
    private var lastSafeArea: UIEdgeInsets?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - stack view
    /// 左侧
    lazy var leftStackView = HStackView(spacing: 12)
    /// 中间
    lazy var centerStackView = VStackView(spacing: 0)
    /// 右侧
    lazy var rightStackView = HStackView(spacing: 16)
    /// 整体
    lazy var contentStackView = HStackView(spacing: 12)

    // MARK: - Override
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadSubViews()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        if let lastSafeArea = lastSafeArea, lastSafeArea == safeAreaInsets {
            return
        }
        lastSafeArea = safeAreaInsets
        updateMarginLayout()
    }

    // MARK: - Public
    func loadSubViews() {
        contentStackView.add(leftStackView).add(centerStackView).add(rightStackView)
        rightStackView.setCustomSpacing(8, after: centerStackView)
        contentView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalTo(safeAreaLayoutGuide).inset(16)
        }
    }

    func configure(with model: CellModel) {
        cellModel = model
    }

    func leftStack(add subViews: [UIView]) {
        addSubviewsTo(statck: leftStackView, subViews: subViews)
    }

    func centerStack(add subViews: [UIView]) {
        addSubviewsTo(statck: centerStackView, subViews: subViews)
    }

    func rightStack(add subViews: [UIView]) {
        addSubviewsTo(statck: rightStackView, subViews: subViews)
    }

    func addSubviewsTo(statck: UIStackView, subViews: [UIView]) {
        subViews.forEach {
            statck.addArrangedSubview($0)
        }
    }
}

// MARK: - Private
extension StackViewCell {

    private func updateMarginLayout() {
        contentStackView.snp.updateConstraints { (maker) in
            maker.left.right.equalTo(safeAreaLayoutGuide).inset(16)
        }
    }
}
