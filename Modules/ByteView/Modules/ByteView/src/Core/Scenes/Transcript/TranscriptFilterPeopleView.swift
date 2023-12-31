//
//  TranscriptFilterPeopleView.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/6/29.
//

import Foundation
import UniverseDesignIcon
import ByteViewUI
import ByteViewCommon
import ByteViewNetwork

class TranscriptFilterPeopleView: UIView {

    static let height: CGFloat = 44

    let button = FilterPeopleButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody

        addSubview(button)
        button.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(-16)
            make.top.equalTo(4)
            make.bottom.equalTo(-12)
            make.height.equalTo(28)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class FilterPeopleButton: UIButton {

    /// 头像视图
    private lazy var avatarView = AvatarView()
    /// 人名标签
    private lazy var nameLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var closeIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.udtokenTagNeutralCloseNormal, size: CGSize(width: 16, height: 16))
        return iv
    }()

    override var isHighlighted: Bool {
        didSet {
            let color: UIColor = isHighlighted ? UIColor.ud.udtokenTagNeutralClosePressed : UIColor.ud.udtokenTagNeutralCloseNormal
            closeIcon.image = UDIcon.getIconByKey(.closeOutlined, iconColor: color, size: CGSize(width: 16, height: 16))
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        vc.setBackgroundColor(.ud.udtokenTagNeutralBgNormal, for: .normal)
        vc.setBackgroundColor(.ud.udtokenTagNeutralBgNormalPressed, for: .highlighted)
        layer.cornerRadius = 14
        clipsToBounds = true

        addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalTo(4)
            make.centerY.equalToSuperview()
        }

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }

        addSubview(closeIcon)
        closeIcon.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(4)
            make.width.height.equalTo(16)
            make.right.equalTo(-8)
            make.centerY.equalToSuperview()
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with userInfo: (AvatarInfo, String, ParticipantId?)) {
        avatarView.setTinyAvatar(userInfo.0)
        nameLabel.text = userInfo.1
    }
}
