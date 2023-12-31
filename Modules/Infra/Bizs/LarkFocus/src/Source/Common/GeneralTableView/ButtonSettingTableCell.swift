//
//  ButtonSettingTableCell.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/9.
//

import Foundation
import UIKit
import LarkInteraction

public final class ButtonSettingTableCell: BaseTableCell {

    enum Style {
        case `default`
        case destructive
    }

    var style: Style = .default {
        didSet {
            setButtonStyle()
        }
    }

    var title: String? {
        didSet {
            label.text = title
        }
    }

    var font: UIFont = UIFont.systemFont(ofSize: 14) {
        didSet {
            label.font = font
        }
    }

    var leftIcon: UIImage? {
        didSet {
            leftIconView.isHidden = leftIcon == nil
            leftIconView.image = leftIcon
        }
    }

    var rightIcon: UIImage? {
        didSet {
            rightIconView.isHidden = rightIcon == nil
            rightIconView.image = rightIcon
        }
    }

    public func setDividingLineHidden(_ isHidden: Bool) {
        dividingLine.isHidden = isHidden
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        setInitialViewState()
    }

    /// 横向 Cell 内容容器
    lazy var contentContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    /// 按钮
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var leftIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var rightIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    /// 下方分割线
    private lazy var dividingLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
        setupSubclass()
    }

    func setupSubclass() {}

    private func setupSubviews() {
        contentView.addSubview(contentContainer)
        contentView.addSubview(dividingLine)
        contentContainer.addArrangedSubview(leftIconView)
        contentContainer.addArrangedSubview(label)
        contentContainer.addArrangedSubview(rightIconView)
    }

    private func setupConstraints() {
        contentContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.greaterThanOrEqualTo(28)
            make.centerX.equalToSuperview()
        }
        dividingLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.trailing.bottom.equalToSuperview()
            make.leading.equalToSuperview()
        }
        leftIconView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        rightIconView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
    }

    private func setupAppearance() {
        setInitialViewState()
        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .hover()))
            contentView.addLKInteraction(action)
        }
    }

    private func setInitialViewState() {
        // 默认样式
        dividingLine.isHidden = true
        setButtonStyle()
    }

    private func setButtonStyle() {
        switch style {
        case .default:
            label.textColor = UIColor.ud.primaryContentDefault
        case .destructive:
            label.textColor = UIColor.ud.functionDangerContentDefault
        }
    }
}
