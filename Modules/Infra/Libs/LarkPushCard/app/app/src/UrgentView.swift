//
//  CustomView.swift
//  LarkPushCardDev
//
//  Created by 白镜吾 on 2022/10/9.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class UrgencyCustomView: UIView {
    var height: CGFloat
    private var avatarView: UIImageView = UIImageView()
    private var containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.spacing = 11
        containerStackView.alignment = .top
        containerStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        containerStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return containerStackView
    }()

    private var contentStackView: UIStackView = {
        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 7
        contentStackView.alignment = .leading
        contentStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        contentStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return contentStackView
    }()

    private var titleStackView: UIStackView = {
        let titleStackView = UIStackView()
        titleStackView.axis = .horizontal
        titleStackView.spacing = 8
        titleStackView.alignment = .leading
        return titleStackView
    }()

    init(id: String) {
        self.height = max(Self.heightOfContent("urgency.message") + 28, Self.Layout.avatarBorderSize)
        super.init(frame: .zero)
        self.addSubview(containerStackView)
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.layoutAvatarView()
        self.layoutContentView()
    }

    private func layoutAvatarView() {
        avatarView.image = UDIcon.getIconByKey(.activityColorful)
        self.containerStackView.addArrangedSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            var offset = (Self.Layout.avatarBorderSize - Self.Layout.avatarSize) / 2
//            make.left.equalToSuperview().offset(offset).priority(.required)
//            make.top.equalToSuperview().offset(offset + 1).priority(.required)
            make.width.height.equalTo(Self.Layout.avatarSize)
        }
    }

    private func layoutContentView() {
        self.containerStackView.addArrangedSubview(contentStackView)
        self.contentStackView.addArrangedSubview(titleStackView)
        let nameLabel = UILabel()
        nameLabel.font = Self.Layout.titleFont
        nameLabel.textColor = UIColor.ud.textCaption
        nameLabel.text = "urgency.userName"
        self.titleStackView.addArrangedSubview(nameLabel)

        let timeLabel = UILabel()
        timeLabel.font = Self.Layout.titleFont
        timeLabel.textColor = UIColor.ud.textCaption
        timeLabel.text = "12:24"
        self.titleStackView.addArrangedSubview(timeLabel)

        let contentLabel = UILabel()
        contentLabel.numberOfLines = 3
        contentLabel.attributedText = Self.attributedContent(content: "urgency.message")
        contentLabel.lineBreakMode = .byTruncatingTail
        self.contentStackView.addArrangedSubview(contentLabel)

        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(11).priority(.required)
//            make.top.equalToSuperview().offset(1).priority(.required)
            make.height.equalTo(18)
        }

        timeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.right).offset(8).priority(.required)
            make.top.equalTo(nameLabel.snp.top).priority(.required)
            make.height.equalTo(18)
        }

        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.left).priority(.required)
            make.top.equalTo(nameLabel.snp.bottom).offset(7).priority(.required)
            make.right.equalToSuperview().priority(.required)
        }
    }

    private static func defaultContentAttribute() -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        attributes[.foregroundColor] = UIColor.ud.textTitle
        attributes[.font] = Self.Layout.defaultContentFont
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Self.Layout.lineSpacing
        attributes[.paragraphStyle] = paragraphStyle
        return attributes
    }

    static func attributedContent(content: String) -> NSAttributedString {
        return NSAttributedString(string: content, attributes: Self.defaultContentAttribute())
    }

    static func heightOfContent(_ content: String) -> CGFloat {
        var width = UIScreen.main.bounds.size.width
        if width > 500 {
            // LarkAlertView 特化的逻辑，当屏幕过宽时
            // 限制宽度为320
            // 见 UrgencyController.swift: layoutUrgentView
            width = 320
        }
        return Self.heightOfContent(content, width: width)
    }

    static func heightOfContent(_ content: String, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(
            width: width - (Self.Layout.padding + Self.Layout.margin) * 2 - 54,
            height: .greatestFiniteMagnitude
        )
        let bounurgencyBox = content.boundingRect(with: constraintRect,
                                               options: .usesLineFragmentOrigin,
                                               attributes: Self.defaultContentAttribute(),
                                               context: nil)
        return min(bounurgencyBox.height + 3, Self.Layout.defaultMaxContentHeight)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UrgencyCustomView {
    final class Layout {
        //根据UI设计图而来
        static let defaultContentFont: UIFont = UIFont.systemFont(ofSize: 16.0)
        static let titleFont: UIFont = UIFont.systemFont(ofSize: 12.0)

        static let lineSpacing: CGFloat = 4

        static let margin: CGFloat = 16
        static let padding: CGFloat = 12

        static let avatarSize: CGFloat = 40.0
        static let avatarBorderSize: CGFloat = 46.0
        //three lines
        static let defaultMaxContentHeight: CGFloat = 70
    }
}
