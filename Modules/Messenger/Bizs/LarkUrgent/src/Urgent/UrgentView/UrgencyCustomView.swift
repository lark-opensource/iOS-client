//
//  UrgencyCustomView.swift
//  LarkUrgent
//
//  Created by Aslan on 2021/9/23.
//

import UIKit
import Foundation
import LarkBizAvatar

final class UrgencyCustomView: UIView {
    private var avatarView: BizAvatar = BizAvatar()
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

    init(urgency: UrgentMessageModel) {
        super.init(frame: .zero)
        self.addSubview(containerStackView)
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.layoutAvatarView(urgency: urgency)
        self.layoutContentView(urgency: urgency)
    }

    private func layoutAvatarView(urgency: UrgentMessageModel) {
        avatarView.topBadge.isZoomable = true
        avatarView.setAvatarByIdentifier(urgency.messageModel.fromChatter?.id ?? "",
                                         avatarKey: urgency.iconUrl,
                                         avatarViewParams: .init(sizeType: .size(Self.Layout.avatarSize)))
        avatarView.updateBadge(.icon(Resources.urgency), style: .weak)
        avatarView.updateBorderSize(CGSize.square(Self.Layout.avatarBorderSize))
        avatarView.updateBorderImage(Resources.avatarBorder)
        self.containerStackView.addArrangedSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            let offset = (Self.Layout.avatarBorderSize - Self.Layout.avatarSize) / 2
            make.left.equalToSuperview().offset(offset).priority(.required)
            make.top.equalToSuperview().offset(offset + 1).priority(.required)
            make.width.height.equalTo(Self.Layout.avatarSize)
        }
    }

    private func layoutContentView(urgency: UrgentMessageModel) {
        self.containerStackView.addArrangedSubview(contentStackView)
        self.contentStackView.addArrangedSubview(titleStackView)
        let nameLabel = UILabel()
        nameLabel.font = Self.Layout.titleFont
        nameLabel.textColor = UIColor.ud.textCaption
        nameLabel.text = urgency.userName
        self.titleStackView.addArrangedSubview(nameLabel)

        let timeLabel = UILabel()
        timeLabel.font = Self.Layout.titleFont
        timeLabel.textColor = UIColor.ud.textCaption
        timeLabel.text = Date.lf.getNiceDateString(urgency.sendTime)
        self.titleStackView.addArrangedSubview(timeLabel)

        let contentLabel = UILabel()
        contentLabel.numberOfLines = 3
        contentLabel.attributedText = Self.attributedContent(content: urgency.message)
        contentLabel.lineBreakMode = .byTruncatingTail
        self.contentStackView.addArrangedSubview(contentLabel)

        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(11).priority(.required)
            make.top.equalToSuperview().offset(1).priority(.required)
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

    private static func attributedContent(content: String) -> NSAttributedString {
        return NSAttributedString(string: content, attributes: Self.defaultContentAttribute())
    }

    /// UrgencyFailView也使用此方法算高度
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
