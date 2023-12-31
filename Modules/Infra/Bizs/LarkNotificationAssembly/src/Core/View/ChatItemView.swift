//
//  ChatItemView.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/12/14.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit

final class ChatItemView: UIView {
    
    public lazy var avatarView: UIImageView = {
        var imageView = UIImageView()
        imageView.layer.cornerRadius = Layout.avatarSize/2
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var chatInfoView: UIStackView = {
       var stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.spacing
        return stackView
    }()
    
    public lazy var nameLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: Layout.nameFontSize)
        label.textColor = UDColor.textPlaceholder
        return label
    }()
    
    private lazy var bubbleView: UIView = {
       var view = UIView()
        view.layer.cornerRadius = Layout.bubbleRadius
        view.backgroundColor = UDColor.rgb(0xF3F4F5) & UDColor.rgb(0x262626)
        view.clipsToBounds = true
        return view
    }()

    public lazy var contentLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: Layout.contentFontSize)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 0
        return label
    }()
    
    public lazy var urgentView: TriangleView = {
        var view = TriangleView(frame: CGRect(x: 0, y: 0, width: Layout.urgentSize, height: Layout.urgentSize))
        view.triangleColor = UDColor.R500
        view.backgroundColor = .clear
       return view
    }()

    private lazy var urgentIconView: UIImageView = {
        let size = CGSize(width: Layout.urgentIconSize, height: Layout.urgentIconSize)
        let icon = UDIcon.getIconByKey(.buzzFilled, size: size)
            .ud.withTintColor(UDColor.staticWhite)
        var iconView = UIImageView()
        iconView.image = icon
        return iconView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.avatarView)
        self.addSubview(self.chatInfoView)
        self.chatInfoView.addArrangedSubview(self.nameLabel)
        self.chatInfoView.addArrangedSubview(self.bubbleView)
        self.bubbleView.addSubview(self.contentLabel)
        self.bubbleView.addSubview(self.urgentView)
        self.urgentView.addSubview(self.urgentIconView)

        self.avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.avatarSize)
            make.left.equalToSuperview().offset(Layout.padding)
            make.top.equalToSuperview()
        }

        self.chatInfoView.snp.makeConstraints { make in
            make.left.equalTo(self.avatarView.snp.right).offset(Layout.chatInfoPadding)
            make.top.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-Layout.chatInfoPadding)
            make.bottom.equalToSuperview()
        }

        self.contentLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(Layout.contentPadding)
            make.bottom.right.equalToSuperview().offset(-Layout.contentPadding)
        }

        self.urgentView.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.height.width.equalTo(Layout.urgentSize)
        }
        
        self.urgentIconView.snp.makeConstraints { make in
            make.top.equalTo(2)
            make.left.equalTo(3)
            make.size.equalTo(Layout.urgentIconSize)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Layout {
        static let nameFontSize: CGFloat = 12
        static let spacing: CGFloat = 4
        static let bubbleRadius: CGFloat = 8
        static let contentFontSize: CGFloat = 17
        static let padding: CGFloat = 14
        static let avatarSize: CGFloat = 30
        static let chatInfoPadding: CGFloat = 8
        static let contentPadding: CGFloat = 12
        static let urgentSize: CGFloat = 24
        static let urgentIconSize: CGFloat = 10
    }
}
