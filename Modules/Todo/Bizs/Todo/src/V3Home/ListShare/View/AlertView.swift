//
//  AlertView.swift
//  Todo
//
//  Created by GCW on 2022/12/8.
//

import Foundation
import UniverseDesignIcon
import LarkBizAvatar
import UniverseDesignFont

class AlertView: UIView {
    weak var delegate: AlertActionDelegate?
    let checkoutImage = UDIcon.getIconByKey(.doneOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.blue)
    private lazy var memberView: UIView = {
        let memberView = UIView()
        memberView.backgroundColor = UIColor.ud.bgBody
        memberView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        memberView.layer.cornerRadius = 16
        memberView.clipsToBounds = true
        return memberView
    }()
    private lazy var topLineView = UIView()

    private let avatarView = BizAvatar()
    private let headerImageView = UIImageView()
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UDFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        return titleLabel
    }()

    init(frame: CGRect, delegate: AlertActionDelegate) {
        self.delegate = delegate
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AlertView {
    func setUpHeaderView() {
        self.addSubview(memberView)
        memberView.backgroundColor = UIColor.ud.bgBody
        memberView.addSubview(avatarView)
        memberView.addSubview(headerImageView)
        memberView.addSubview(titleLabel)
        memberView.addSubview(topLineView)
        memberView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(67)
        }
        headerImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(13)
            make.width.height.equalTo(40)
        }
        avatarView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(13)
            make.width.height.equalTo(40)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(16)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        topLineView.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
        topLineView.backgroundColor = UIColor.ud.lineBorderCard
    }

    func setMember(avatar: TaskMemberCellData.IconType, name: String) {
        switch avatar {
        case .avatar(let avatar):
            avatarView.isHidden = false
            headerImageView.isHidden = true
            avatarView.setAvatarByIdentifier(avatar.avatarId, avatarKey: avatar.avatarKey)
        case .icon(let image):
            avatarView.isHidden = true
            headerImageView.isHidden = false
            headerImageView.image = image
        }
        titleLabel.text = name
    }

    func setAlertView(_ width: CGFloat) {
        subviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
        self.backgroundColor = UIColor.ud.bgBody
        var offsetY: CGFloat = 67
        guard let delegate = delegate else { return }
        for (index, alertAction) in delegate.getAlertAction().enumerated() {
            let itemHeight = delegate.getItemHeightFor(alertAction)
            let itemBtn = UIButton()
            itemBtn.frame = CGRect(x: CGFloat(0), y: offsetY,
                                   width: width,
                                   height: itemHeight)
            offsetY += itemHeight
            itemBtn.setTitle(alertAction.title, for: .normal)
            itemBtn.titleLabel?.font = UDFont.systemFont(ofSize: 16)
            itemBtn.contentHorizontalAlignment = .left
            itemBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

            switch alertAction.style.selectStyle {
            case .option:
                if let canBeSelected = alertAction.canBeSelected, !canBeSelected {
                    itemBtn.setTitleColor(UIColor.ud.N300, for: .normal)
                } else {
                    itemBtn.setTitleColor(UIColor.ud.textTitle, for: .normal)
                    itemBtn.setTitleColor(UIColor.ud.textTitle.withAlphaComponent(0.5), for: .highlighted)
                    itemBtn.tag = index
                    itemBtn.addTarget(self, action: #selector(alertViewAction(sender:)), for: .touchUpInside)
                }
            case .destructive:
                if let canBeSelected = alertAction.canBeSelected, !canBeSelected {
                    itemBtn.setTitleColor(UIColor.ud.N300, for: .normal)
                } else {
                    itemBtn.setTitleColor(UIColor.ud.colorfulRed, for: .normal)
                    itemBtn.tag = index
                    itemBtn.addTarget(self, action: #selector(alertViewAction(sender:)), for: .touchUpInside)
                }
            }

            if let isSelected = alertAction.isSelected {
                let checkIcon = UIImageView()
                checkIcon.image = checkoutImage
                checkIcon.isHidden = !isSelected
                let checkSize = CGSize(width: 24, height: 24)
                checkIcon.frame = CGRect(x: itemBtn.frame.size.width - checkSize.width - 30,
                                         y: (itemBtn.frame.size.height - checkSize.height) / 2,
                                         width: checkSize.width,
                                         height: checkSize.height)
                itemBtn.addSubview(checkIcon)
            }
            if alertAction.needSeparateLine {
                let dividingLine = UIView()
                dividingLine.backgroundColor = UIColor.ud.lineBorderCard
                itemBtn.addSubview(dividingLine)
                dividingLine.snp.makeConstraints { (make) in
                    make.bottom.equalTo(itemBtn)
                    make.left.equalTo(itemBtn).offset(19)
                    make.right.equalTo(itemBtn).offset(-19)
                    make.height.equalTo(0.5)
                }
            }
            self.addSubview(itemBtn)
        }
    }

    @objc
    func alertViewAction(sender: UIButton) {
        if let delegate = delegate,
            let handler = delegate.getAlertAction()[sender.tag].handler {
            delegate.alertDismiss()
            handler()
        }
    }
}
