//
//  DetailUserContentView.swift
//  Todo
//
//  Created by baiyantao on 2022/9/21.
//

import Foundation
import UniverseDesignFont

/// View Data
struct DetailUserViewData {
    var avatarData: AvatarGroupViewData?
    var content: String?
    var icon: UIImage?
}
/// DetailUserContentView 基本结构如下：
///
///     +----------------------------------------+
///     | AvatarGroupView | content |  icon?     |
///     +----------------------------------------+
///     icon是可选的，如果不传就不展示
final class DetailUserContentView: UIView {

    var viewData: DetailUserViewData = .init() {
        didSet {
            updateContent(with: viewData)
            invalidateIntrinsicContentSize()
            setNeedsUpdateConstraints()
        }
    }

    var onTapContentHandler: (() -> Void)?
    var onTapIconHandler: (() -> Void)?

    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = config.backgroundCornerRadius
        view.layer.masksToBounds = true
        if config.needBackgroundColor {
            view.backgroundColor = UIColor.ud.bgBodyOverlay
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickContent))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var stackView: UIStackView = {
        var stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = config.space
        return stackView
    }()

    private lazy var avatarContainer: AvatarGroupView = {
        return AvatarGroupView(style: style)
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        return label
    }()

    private lazy var iconView: UIButton = {
        let button = UIButton()
        button.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.addTarget(self, action: #selector(clickIcon), for: .touchUpInside)
        return button
    }()

    private let style: CheckedAvatarView.Style
    private let config: DetailUserContentView.Config
    init(style: CheckedAvatarView.Style = .big, config: DetailUserContentView.Config = .init()) {
        self.style = style
        self.config = config
        super.init(frame: .zero)
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.left.centerY.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview()
            $0.height.equalTo(config.height)
        }

        containerView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(config.leftPadding)
            $0.right.equalToSuperview().offset(-config.rightPadding)
            $0.top.bottom.equalToSuperview()
        }

        stackView.addArrangedSubview(avatarContainer)
        stackView.addArrangedSubview(contentLabel)
        stackView.addArrangedSubview(iconView)
        iconView.snp.makeConstraints { $0.width.height.equalTo(14) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        // left(10) + right(10) padding = 20
        var width = avatarContainer.intrinsicContentSize.width + config.leftPadding + config.rightPadding
        if stackView.arrangedSubviews.contains(contentLabel) {
            width += contentLabel.intrinsicContentSize.width + config.space
        }
        if stackView.arrangedSubviews.contains(iconView) {
            width += iconView.intrinsicContentSize.width + config.space
        }
        return CGSize(width: width, height: config.height)
    }

    private func updateContent(with viewData: DetailUserViewData) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            // 必须调用removeFromSuperview。不然不能被销毁
            $0.removeFromSuperview()
        }

        if let avatarsData = viewData.avatarData {
            avatarContainer.viewData = avatarsData
            stackView.addArrangedSubview(avatarContainer)
        }

        if let text = viewData.content {
            contentLabel.text = text
            stackView.addArrangedSubview(contentLabel)
        }

        if let icon = viewData.icon {
            iconView.setImage(icon.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
            stackView.addArrangedSubview(iconView)
        }
    }

    @objc
    private func clickIcon() {
        onTapIconHandler?()
    }

    @objc
    private func clickContent() {
        onTapContentHandler?()
    }
}

extension DetailUserContentView {

    struct Config {
        var space: CGFloat = 8.0
        var leftPadding: CGFloat = 10.0
        var rightPadding: CGFloat = 10.0
        var needBackgroundColor = true
        var backgroundCornerRadius: CGFloat = 8
        var height: CGFloat = 36
    }

}
