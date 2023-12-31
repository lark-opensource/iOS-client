//
//  ShareGroupView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/8/13.
//

import Foundation
import UIKit
import LarkModel
import LarkBizAvatar
import LarkTag

public protocol ShareGroupViewDelegate: AnyObject {
    func hasJoinedChat(_ role: Chat.Role?) -> Bool
    func joinButtonTapped()
    func headerTapped()
    func titleForHadJoinChat() -> String
}

final class ShareGroupHighlightButton: UIButton {
    override public var isHighlighted: Bool {
        didSet {
            if isHighlighted != oldValue {
                UIView.animate(withDuration: 0.1) {
                    self.backgroundColor = self.isHighlighted ? UIColor.ud.N600.withAlphaComponent(0.05) : nil
                }
            }
        }
    }
}

public final class ShareGroupView: UIView {

    enum Cons {
        static var avatarSize: CGFloat { 48.auto() }
        static var joinButtonFont: UIFont { UIFont.ud.body1 }
        static var joinButtonHeight: CGFloat { joinButtonFont.rowHeight + 24 }
        static var joinButtonTop: CGFloat { 12 }
        static var nameFont: UIFont { UIFont.ud.headline }
        static var descFont: UIFont { UIFont.ud.body2 }
    }

    private lazy var avatarView: BizAvatar = {
        let avatarView = BizAvatar()
        return avatarView
    }()

    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = Cons.nameFont
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.numberOfLines = 1
        return nameLabel
    }()

    private var groupTagView: UIView?

    private lazy var descLabel: UILabel = {
        let descLabel = UILabel()
        descLabel.font = Cons.descFont
        descLabel.textColor = UIColor.ud.N500
        descLabel.numberOfLines = 1
        return descLabel
    }()

    private lazy var layoutGuide = UILayoutGuide()

    private lazy var joinButton: ShareGroupHighlightButton = {
        let joinButton = ShareGroupHighlightButton()
        joinButton.titleLabel?.font = Cons.joinButtonFont
        joinButton.setTitleColor(UIColor.ud.N900, for: .normal)
        joinButton.setTitleColor(UIColor.ud.N400, for: .disabled)
        joinButton.setTitle(BundleI18n.LarkMessageCore.Lark_Legacy_ShareGroupExpired, for: .disabled)
        joinButton.layer.borderWidth = 1
        joinButton.layer.borderColor = UIColor.ud.N300.cgColor
        joinButton.layer.cornerRadius = Cons.joinButtonHeight / 2
        joinButton.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        return joinButton
    }()

    private lazy var headerControl: UIControl = {
        let control = UIControl()
        control.addTarget(self, action: #selector(headerTapped), for: .touchUpInside)
        return control
    }()

    public weak var delegate: ShareGroupViewDelegate?
    public var threadMiniIconEnableFg: Bool = false
    public var content: ShareGroupChatContent? {
        didSet {
            guard let content = content,
                let delegate = self.delegate else {
                    return
            }

            self.nameLabel.text = content.chat?.name
            self.groupTagView?.removeFromSuperview()
            if let chat = content.chat {
                if chat.isCrossWithKa {
                    self.groupTagView = TagWrapperView.titleTagView(for: Tag(type: .connect))
                } else if chat.isCrossTenant {
                    self.groupTagView = TagWrapperView.titleTagView(for: Tag(type: .external))
                }
            }
            if let groupTagView = self.groupTagView {
                self.addSubview(groupTagView)
                groupTagView.snp.makeConstraints { (make) in
                    make.centerY.equalTo(nameLabel)
                    make.leading.equalTo(nameLabel.snp.trailing).offset(7)
                    make.trailing.lessThanOrEqualToSuperview()
                }
            }
            self.descLabel.text = content.chat?.description
            let emptyDesc = self.descLabel.text?.isEmpty ?? true
            self.nameLabel.snp.remakeConstraints { (make) in
                if emptyDesc {
                    make.centerY.equalTo(layoutGuide)
                } else {
                    make.top.equalTo(layoutGuide)
                }
                make.left.right.equalTo(layoutGuide)
            }
            self.joinButton.isEnabled = !content.expired
            let isJoined = delegate.hasJoinedChat(content.chat?.role)
            let title = isJoined ? self.delegate?.titleForHadJoinChat() : BundleI18n.LarkMessageCore.Lark_Legacy_JoinGroupChat
            self.joinButton.setTitle(title, for: .normal)
            joinButton.setTitleColor(isJoined ? UIColor.ud.colorfulBlue : UIColor.ud.N900, for: .normal)
            self.avatarView.setAvatarByIdentifier(content.chat?.id ?? "",
                                                  avatarKey: content.chat?.avatarKey ?? "",
                                                  avatarViewParams: .init(sizeType: .size(Cons.avatarSize)))
            if threadMiniIconEnableFg, content.chat?.chatMode == .threadV2 {
                self.avatarView.setMiniIcon(MiniIconProps(.thread))
            } else {
                self.avatarView.setMiniIcon(nil)
            }
        }
    }

    public init() {
        super.init(frame: .zero)

        self.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.width.height.equalTo(Cons.avatarSize)
        }

        self.addLayoutGuide(self.layoutGuide)
        layoutGuide.snp.makeConstraints { (make) in
            make.centerY.equalTo(avatarView)
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.right.lessThanOrEqualToSuperview()
        }

        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.top.right.equalTo(layoutGuide)
        }

        self.addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.left.bottom.right.equalTo(layoutGuide)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }

        self.addSubview(joinButton)
        joinButton.snp.makeConstraints { (make) in
            make.left.bottom.right.equalTo(0)
            make.top.equalTo(avatarView.snp.bottom).offset(Cons.joinButtonTop)
            make.height.equalTo(Cons.joinButtonHeight)
        }

        self.addSubview(headerControl)
        headerControl.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(joinButton.snp.top)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func joinButtonTapped() {
        delegate?.joinButtonTapped()
    }

    @objc
    private func headerTapped() {
        delegate?.headerTapped()
    }
}

extension ShareGroupChatContent {
    public var expired: Bool {
        get {
            return self.expireTime < Date().timeIntervalSince1970 || self.joinToken.isEmpty
        }
        set {
            if newValue {
                self.joinToken = ""
            }
        }
    }
}
