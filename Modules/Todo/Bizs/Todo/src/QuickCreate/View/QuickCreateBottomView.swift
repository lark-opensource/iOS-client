//
//  QuickCreateBottomView.swift
//  Todo
//
//  Created by wangwanxin on 2021/3/15.
//

import CTFoundation
import UniverseDesignButton
import UniverseDesignFont

struct QuickCreateBottomIconAction {

    enum ActionType {
        /// 执行人
        case assignee
        /// 时间（提醒时间 & 截止时间）
        case time
    }

    var type: ActionType
    var icon: UIImage
    var highlightedIcon: UIImage
    var isEnabled = true
}

protocol QuickCreateBottomViewDataType {
    var iconActions: [QuickCreateBottomIconAction] { get }
    var sendAction: (title: String, isEnabled: Bool) { get }
    var descriptionText: String? { get }
}

class QuickCreateBottomView: UIView, ViewDataConvertible {

    var viewData: QuickCreateBottomViewDataType? {
        didSet { updateView() }
    }

    // icon 被点击
    var onIconTapped: ((_ type: QuickCreateBottomIconAction.ActionType) -> Void)?
    // send 被点击
    var onSendTapped: (() -> Void)?

    private var iconStackView = UIStackView()

    var descriptionLabel: UILabel = {
        let labelView = UILabel()
        labelView.font = UDFont.systemFont(ofSize: 12)
        labelView.textColor = UIColor.ud.textCaption
        return labelView
    }()
    private var sendButton: UDButton = {
        var config = UDButton.secondaryBlue.config
        config.type = .small
        config.radiusStyle = .square
        return UDButton(config)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconStackView.axis = .horizontal
        iconStackView.spacing = 24
        iconStackView.alignment = .center
        addSubview(iconStackView)
        iconStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.left.equalToSuperview()
            make.height.equalTo(24)
        }

        addSubview(sendButton)
        sendButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
        }
        sendButton.isEnabled = false
        sendButton.addTarget(self, action: #selector(handleSendButtonTapped(_:)), for: .touchUpInside)

        addSubview(descriptionLabel)
        descriptionLabel.snp.remakeConstraints { make in
            make.right.equalTo(sendButton.snp.left).offset(-12)
            make.height.equalTo(20)
            make.centerY.equalTo(sendButton.snp.centerY)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.noIntrinsicMetric, height: 48)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateView() {
        // remove old icon views
        let iconViews = iconStackView.arrangedSubviews
        for iconView in iconViews {
            iconStackView.removeArrangedSubview(iconView)
            iconView.removeFromSuperview()
        }

        // make new icon views
        let iconSize = CGSize(width: 24, height: 24)
        for (index, iconAction) in (viewData?.iconActions ?? []).enumerated() {
            let button = UIButton()
            button.snp.makeConstraints { $0.size.equalTo(iconSize) }
            let icon = iconAction.icon.ud.withTintColor(UIColor.ud.iconN3)
            button.setImage(icon, for: .normal)
            button.setImage(icon, for: .highlighted)
            button.tag = index
            button.addTarget(self, action: #selector(handleIconButtonTapped(_:)), for: .touchUpInside)
            button.isEnabled = iconAction.isEnabled
            iconStackView.addArrangedSubview(button)
        }

        // config send buton
        sendButton.isEnabled = viewData?.sendAction.isEnabled ?? false
        sendButton.setTitle(viewData?.sendAction.title, for: .normal)
        sendButton.setTitle(viewData?.sendAction.title, for: .disabled)

        if let descriptionText = viewData?.descriptionText {
            descriptionLabel.isHidden = false
            descriptionLabel.text = descriptionText
        } else {
            descriptionLabel.isHidden = true
        }
    }

    @objc
    private func handleIconButtonTapped(_ sender: UIButton) {
        guard let iconActions = viewData?.iconActions, sender.tag >= 0 && sender.tag < iconActions.count else {
            return
        }
        onIconTapped?(iconActions[sender.tag].type)
    }

    @objc
    private func handleSendButtonTapped(_ sender: UIButton) {
        onSendTapped?()
    }

}
