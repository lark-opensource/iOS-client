//
//  MineMainCustomerServiceCell.swift
//  LarkMine
//
//  Created by 姚启灏 on 2019/2/25.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import LarkModel
import LarkBizAvatar
import LarkSDKInterface
import UniverseDesignColor

// TODO: DarkMode
protocol MineMainCustomerServiceCellDelegate: AnyObject {
    func didSelected(oncall: Oncall)
}

final class MineMainCustomerServiceCell: UIButton {
    private var avatarView: BizAvatar?
    private let avatarSize: CGFloat = 20
    private var nameLabel: UILabel?

    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? UIColor.ud.udtokenBtnSeBgNeutralHover : UIColor.ud.bgBodyOverlay
        }
    }

    private var oncall: Oncall?

    weak var delegate: MineMainCustomerServiceCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.cornerRadius = 16
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        self.adjustsImageWhenHighlighted = true
        self.addTarget(self, action: #selector(didSelect), for: .touchUpInside)

        let wrapperView = UIView()
        self.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(9)
            make.right.lessThanOrEqualToSuperview().offset(-9)
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
        }

        wrapperView.isUserInteractionEnabled = false

        let avatarView = BizAvatar()

        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor.ud.textTitle

        wrapperView.addSubview(nameLabel)
        wrapperView.addSubview(avatarView)
        self.nameLabel = nameLabel
        self.avatarView = avatarView

        avatarView.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
    }

    func set(oncall: Oncall?, name: String = "", image: UIImage? = nil) {
        if let oncall = oncall {
            self.oncall = oncall
            self.avatarView?.setAvatarByIdentifier(oncall.id, avatarKey: oncall.avatar.key,
                                                   avatarViewParams: .init(sizeType: .size(avatarSize)))
            self.nameLabel?.text = oncall.name
        } else {
            self.avatarView?.image = image
            self.nameLabel?.text = name
        }
    }

    @objc
    private func didSelect() {
        if let oncall = self.oncall {
            self.delegate?.didSelected(oncall: oncall)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
