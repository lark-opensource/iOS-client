//
//  UrgencyFailView.swift
//  LarkUrgent
//
//  Created by JackZhao on 2021/12/20.
//

import UIKit
import LarkModel
import Foundation
import LarkBizAvatar

final class UrgencyFailView: UIView {
    private var iconView = UIImageView(image: Resources.urgent_fail_icon)
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()

    private var containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 16
        containerStackView.alignment = .top
        containerStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        containerStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return containerStackView
    }()

    private var titleStackView: UIStackView = {
        let titleStackView = UIStackView()
        titleStackView.axis = .horizontal
        titleStackView.spacing = 10
        titleStackView.alignment = .leading
        return titleStackView
    }()

    init(urgency: UrgentFailureModel) {
        super.init(frame: .zero)
        self.addSubview(containerStackView)
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.layoutContentView(urgency: urgency)
    }

    private func layoutContentView(urgency: UrgentFailureModel) {
        self.containerStackView.addArrangedSubview(titleStackView)
        self.titleStackView.addArrangedSubview(iconView)
        self.titleStackView.addArrangedSubview(titleLabel)
        self.containerStackView.addArrangedSubview(contentLabel)

        iconView.snp.makeConstraints { (make) in
            make.top.equalTo(Self.Layout.verticalPadding).priority(.required)
            make.left.equalTo(Self.Layout.horizontalPadding).priority(.required)
            make.width.height.equalTo(20)
        }

        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(10)
            make.top.equalToSuperview().offset(Self.Layout.verticalPadding)
            make.height.equalTo(Self.Layout.titleLabelHeight)
        }

        contentLabel.numberOfLines = 5
        contentLabel.font = Self.Layout.defaultContentFont
        contentLabel.textColor = UIColor.ud.textTitle
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(Self.Layout.horizontalPadding)
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.right.equalTo(-Self.Layout.horizontalPadding)
        }
    }

    func setContent(title: String, description: String) {
        titleLabel.text = title
        contentLabel.text = description
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UrgencyFailView {
    final class Layout {
        //根据UI设计图而来
        static let defaultContentFont: UIFont = UIFont.systemFont(ofSize: 16.0)

        static let titleLabelHeight: CGFloat = 18
        static let verticalPadding: CGFloat = 0
        static let horizontalPadding: CGFloat = 0
    }
}

// 加急失败模型
public final class UrgentFailureModel {
    public var messageModel: LarkModel.Message
    public let chat: Chat
    public var id: String
    public var iconImage: UIImage?
    public var iconUrl: String { "" }
    public var extra: Any? { nil }
    public var userName: String {
        ""
    }
    /// urgent actions
    public var customItem: (view: UIView, height: CGFloat)?
    public var message: String {
        ""
    }
    public var failedTip: String

    public init(urgentId: String,
                message: LarkModel.Message,
                failedTip: String,
                chat: Chat) {
        self.id = urgentId
        self.messageModel = message
        self.failedTip = failedTip
        self.chat = chat
    }
}
