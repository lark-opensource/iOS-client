//
//  InMeetStatusDetailCell.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/20.
//

import UIKit
import UniverseDesignIcon

class InMeetStatusDetailCell: UITableViewCell {

    private let iconView = UIImageView()
    private var item: InMeetStatusItem?
    var onClick: (() -> Void)?

    static let buttonMaxWidth: CGFloat = 98
    static let buttonMinWidth: CGFloat = 60
    static let buttonFont = UIFont.systemFont(ofSize: 14, weight: .regular)

    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 2
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private let descLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private var actionButtons: [UIButton] = []
    private let buttonContainer = UIView()
    private let arrowView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 12, height: 12))
        return view
    }()

    lazy var bottomLine: UIView = {
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with item: InMeetStatusItem) {
        self.item = item
        selectionStyle = item.clickAction == nil ? .none : .default
        iconView.image = item.icon
        titleLabel.attributedText = NSAttributedString(string: item.title, config: .body)
        if let desc = item.desc {
            descLabel.attributedText = NSAttributedString(string: desc, config: .bodyAssist)
            descLabel.isHiddenInStackView = false
        } else {
            descLabel.isHiddenInStackView = true
        }
        updateActions(item)
        arrowView.isHidden = item.clickAction == nil
    }

    private func createActionButton() -> UIButton {
        let button = UIButton()
        button.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralPressed, for: .highlighted)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = Self.buttonFont
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.addTarget(self, action: #selector(handleButtonClick), for: .touchUpInside)
        return button
    }

    private func updateActions(_ item: InMeetStatusItem) {
        let currentButtonCount = actionButtons.count
        // 1. 如果缓存池里 button 数量小于 actions 的数量，创建新 button
        if currentButtonCount < item.actions.count {
            for _ in currentButtonCount..<item.actions.count {
                let button = createActionButton()
                buttonContainer.addSubview(button)
                actionButtons.append(button)
            }
        }

        // 2. 复用缓存池里的 button 到合适的位置
        for i in 0..<item.actions.count {
            let button = actionButtons[i]
            button.isHidden = false
            button.setTitle(item.actions[i].title, for: .normal)
            button.snp.remakeConstraints { make in
                if i == 0 {
                    make.left.equalToSuperview()
                } else {
                    make.left.equalTo(actionButtons[i - 1].snp.right).offset(12)
                }
                if i == item.actions.count - 1 {
                    make.right.equalToSuperview()
                }
                make.height.centerY.equalToSuperview()
                make.width.greaterThanOrEqualTo(Self.buttonMinWidth)
                make.width.lessThanOrEqualTo(Self.buttonMaxWidth)
            }
        }
        // 3. 将多余的 button（如果有）隐藏
        for i in item.actions.count..<actionButtons.count {
            let button = actionButtons[i]
            button.isHidden = true
            button.snp.removeConstraints()
        }
        // 4. 更新 title 和 desc 的约束
        stackView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalTo(iconView.snp.right).offset(12)
            if !actionButtons.isEmpty {
                make.right.lessThanOrEqualTo(buttonContainer.snp.left).offset(-12)
            } else if item.clickAction != nil {
                make.right.lessThanOrEqualTo(arrowView.snp.left).offset(-12)
            } else {
                make.right.lessThanOrEqualToSuperview().inset(12)
            }
        }
    }

    // disable-lint: duplicated code
    private func setupSubviews() {
        backgroundColor = .clear
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(15)
            make.size.equalTo(16)
        }

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.right.lessThanOrEqualToSuperview().inset(12)
            make.left.equalTo(iconView.snp.right).offset(12)
        }

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descLabel)

        contentView.addSubview(buttonContainer)
        buttonContainer.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
        }

        contentView.addSubview(arrowView)
        arrowView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.size.equalTo(12)
        }

        contentView.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.right.equalToSuperview()
            make.left.equalTo(titleLabel)
        }
    }
    // enable-lint: duplicated code

    @objc
    private func handleButtonClick(_ sender: UIButton) {
        guard let item = item, let index = actionButtons.firstIndex(of: sender), index < item.actions.count else { return }
        item.actions[index].action { [weak self] in
            self?.onClick?()
        }
    }
}
