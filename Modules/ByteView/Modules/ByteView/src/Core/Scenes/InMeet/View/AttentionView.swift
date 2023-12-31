//
//  AttentionView.swift
//  ByteView
//
//  Created by wulv on 2020/7/7.
//

import SnapKit
import RxCocoa
import RichLabel
import ByteViewCommon
import CoreGraphics
import UniverseDesignIcon

typealias AttentionAction = AttentionButton.Action

class AttentionButton: VisualButton {

    struct Action {
        let name: String
        let handler: (() -> Void)?
    }

    var beforeActionHandler: (() -> Void)?

    var action: Action? {
        didSet {
            setTitle(action?.name, for: .normal)
            removeTarget(self, action: #selector(actionHandler), for: .touchUpInside)
            addTarget(self, action: #selector(actionHandler), for: .touchUpInside)
        }
    }

    @objc private func actionHandler() {
        beforeActionHandler?()
        action?.handler?()
    }
}

class AttentionView: UIView {

    private struct Layout {
        static let radius: CGFloat = 8.0
        static let shadowOffset = CGSize(width: 0, height: 4)
        static let shadowRadius: CGFloat = 8.0
        static let left: CGFloat = 16
        static let buttonFont: CGFloat = 16
        static let buttonInset: CGFloat = 16
    }

    private enum Axis {
        /// 水平布局
        case h
        /// 垂直布局
        case v
    }

    private lazy var titleLabel: LKLabel = {
        let label = LKLabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.boldSystemFont(ofSize: 17)
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.N800, size: CGSize(width: 16, height: 16)), for: .normal)
        button.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        return button
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private var actions: [AttentionButton.Action] = []
    private var buttonsGap: CGFloat = 12
    private var buttonHeight: CGFloat = 36
    private var closeActionHandler: (() -> Void)?
    /// 动态调整按钮布局
    private var buttonAxis: Axis = .h

    private var attributedText: NSMutableAttributedString?

    convenience init(title: String? = nil,
                     attributedTitle: NSMutableAttributedString? = nil,
                     titleLink: LKTextLink? = nil,
                     width: CGFloat? = nil,
                     actions: AttentionButton.Action...,
                     buttonsGap: CGFloat? = nil,
                     buttonHeight: CGFloat? = nil,
                     beforeClose: (() -> Void)? = nil) {
        self.init(frame: .zero)
        self.titleLabel.text = title
        self.titleLabel.attributedText = attributedTitle
        self.attributedText = attributedTitle
        titleLabel.removeLKTextLink()
        if let titleLink = titleLink {
            titleLabel.addLKTextLink(link: titleLink)
        }
        self.actions = actions
        if let gap = buttonsGap {
            self.buttonsGap = gap
        }
        if let h = buttonHeight {
            self.buttonHeight = h
        }
        self.closeActionHandler = beforeClose
        if let w = width {
            updateButtonAxis(maxWidth: w)
        }
        layoutButtons()
    }

    func update(title: String? = nil,
                attributedTitle: NSMutableAttributedString? = nil,
                titleLink: LKTextLink? = nil,
                actions: AttentionButton.Action...,
                buttonsGap: CGFloat? = nil,
                buttonHeight: CGFloat? = nil,
                beforeClose: (() -> Void)? = nil) {
        if let title = title {
            self.titleLabel.text = title
        }
        if let attr = attributedTitle {
            self.titleLabel.attributedText = attr
            self.attributedText = attr
        }
        titleLabel.removeLKTextLink()
        if let titleLink = titleLink {
            titleLabel.addLKTextLink(link: titleLink)
        }
        self.actions = actions
        if let gap = buttonsGap {
            self.buttonsGap = gap
        }
        if let h = buttonHeight {
            self.buttonHeight = h
        }
        if let h = beforeClose {
            self.closeActionHandler = h
        }
        layoutButtons()
    }

    func updateButtonAxis(maxWidth: CGFloat) {
        var w: CGFloat = Layout.left * 2
        var axis: Axis = .h
        actions.enumerated().forEach { (i, a) in
            if i != 0 {
                w += self.buttonsGap
            }
            let length = a.name.vc.boundingWidth(height: buttonHeight, font: UIFont.systemFont(ofSize: Layout.buttonFont)) + Layout.buttonInset * 2
            w += length
            if w > maxWidth {
                axis = .v
                return
            }
        }
        if axis != buttonAxis {
            buttonAxis = axis
            layoutButtons()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = Layout.radius
        layer.borderWidth = Layout.radius
        layer.vc.borderColor = UIColor.ud.lineBorderCard
        layer.borderWidth = 0.5
        layer.vc.shadowColor = UIColor.ud.shadowDefaultMd
        layer.shadowOffset = Layout.shadowOffset
        layer.shadowRadius = Layout.shadowRadius
        layer.shadowOpacity = 1

        addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.top.equalTo(6)
            make.right.equalTo(-4)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(16)
            make.left.equalTo(Layout.left)
            make.right.equalTo(closeButton.snp.left)
        }

        addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(-Layout.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.bottom.equalTo(-16)
        }
    }

    private func layoutButtons() {
        Util.runInMainThread {
            let addedCount = self.bottomView.subviews.count
            var lastButton: AttentionButton?
            for (index, action) in self.actions.enumerated() {
                var button: AttentionButton
                if index < addedCount, let attentionButton = self.bottomView.subviews[index] as? AttentionButton {
                    button = attentionButton
                } else {
                    button = self.createButton()
                    self.bottomView.addSubview(button)
                }
                button.action = action
                switch self.buttonAxis {
                case .v: self.layoutVerticalButton(button, index: index, last: &lastButton)
                case .h: self.layoutHorizontalButton(button, index: index, last: &lastButton)
                }
            }
            self.removeUnusedButtonsIfNeeded()
        }
    }

    private func layoutHorizontalButton(_ button: AttentionButton, index: Int, last: inout AttentionButton?) {
        if index == 0, index == actions.count - 1 {
            button.snp.remakeConstraints { (make) in
                make.left.top.right.bottom.equalToSuperview()
                make.height.equalTo(buttonHeight)
            }
        } else if index == 0 {
            button.snp.remakeConstraints { (make) in
                make.left.top.bottom.equalToSuperview()
                make.height.equalTo(buttonHeight)
            }
        } else if index == actions.count - 1 {
            guard let lastButton = last else { return }
            button.snp.remakeConstraints { (make) in
                make.left.equalTo(lastButton.snp.right).offset(buttonsGap)
                make.width.equalTo(lastButton.snp.width)
                make.right.top.bottom.equalToSuperview()
                make.height.equalTo(buttonHeight)
            }
        } else {
            guard let lastButton = last else { return }
            button.snp.remakeConstraints { (make) in
                make.left.equalTo(lastButton.snp.right).offset(buttonsGap)
                make.width.equalTo(lastButton.snp.width)
                make.top.bottom.equalToSuperview()
                make.height.equalTo(buttonHeight)
            }
        }
        last = button
    }

    private func layoutVerticalButton(_ button: AttentionButton, index: Int, last: inout AttentionButton?) {
        if index == 0, index == actions.count - 1 {
            button.snp.remakeConstraints { (make) in
                make.left.top.right.bottom.equalToSuperview()
                make.height.equalTo(buttonHeight)
            }
        } else if index == 0 {
            button.snp.remakeConstraints { (make) in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(buttonHeight)
            }
        } else if index == actions.count - 1 {
            guard let lastButton = last else { return }
            button.snp.remakeConstraints { (make) in
                make.left.right.height.equalTo(lastButton)
                make.top.equalTo(lastButton.snp.bottom).offset(buttonsGap)
                make.bottom.equalToSuperview()
            }
        } else {
            guard let lastButton = last else { return }
            button.snp.remakeConstraints { (make) in
                make.left.right.height.equalTo(lastButton)
                make.top.equalTo(lastButton.snp.bottom).offset(buttonsGap)
            }
        }
        last = button
    }

    private func removeUnusedButtonsIfNeeded() {
        let fromIndex = self.actions.count
        let endIndex = self.bottomView.subviews.count - 1
        if fromIndex <= endIndex {
            for subview in self.bottomView.subviews[fromIndex...endIndex] {
                subview.removeFromSuperview()
            }
        }
    }

    private func createButton() -> AttentionButton {
        let button = AttentionButton(type: .custom)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .highlighted)
        button.setBGColor(UIColor.clear, for: .normal)
        button.setBGColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .highlighted)
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.systemFont(ofSize: Layout.buttonFont)
        button.beforeActionHandler = { [weak self] in
            self?.dismiss()
        }
        return button
    }

    @objc private func closeButtonAction() {
        closeActionHandler?()
        dismiss()
    }

    func dismiss() {
        removeFromSuperview()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if titleLabel.preferredMaxLayoutWidth != titleLabel.bounds.size.width {
            titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.size.width
            titleLabel.text = titleLabel.text
            titleLabel.attributedText = attributedText
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.attributedText = attributedText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
