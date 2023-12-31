//
//  UserFollowTableViewCell.swift
//  Moment
//
//  Created by liluobin on 2021/3/9.
//

import Foundation
import UIKit
import LarkBizAvatar
import RxSwift
import LarkContainer

final class UserFollowTableViewCell: UITableViewCell {
    let avatarWidth: CGFloat = 48
    static let identifier = "UserFollowTableViewCell"

    private var momentsAccountService: MomentsAccountService? { viewModel?.momentsAccountService }

    var viewModel: FollowCellViewModel? {
        didSet {
            updateUI()
        }
    }

    var currentUserIsOfficialUser: Bool {
        return momentsAccountService?.getCurrentUserIsOfficialUser() ?? false
    }

    public lazy var followBtn: MomentsFollowButton = {
        let btn = MomentsFollowButton(isFollowed: false) { [weak self] (_) in
            self?.updateFollowStatus()
        }
        return btn
    }()

    public lazy var avatarView: BizAvatar = {
        let view = BizAvatar()
        view.lu.addTapGestureRecognizer(action: #selector(avatarViewTapped), target: self)
        return view
    }()

    public lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgBody
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: avatarWidth, height: avatarWidth))
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(followBtn)
        followBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalTo(followBtn.snp.left).offset(-16)
        }

    }

    func updateUI() {
        let userID = viewModel?.user.userID ?? ""
        avatarView.setAvatarByIdentifier(userID,
                                         avatarKey: viewModel?.user.avatarKey ?? "",
                                         scene: .Moments,
                                         avatarViewParams: .init(sizeType: .size(avatarWidth)))
        nameLabel.text = viewModel?.user.displayName ?? ""
        followBtn.isHidden = (viewModel?.isCurrentUser ?? false)
        || currentUserIsOfficialUser //官方号禁止关注别人
        followBtn.reloadUIForIsFollowed(viewModel?.user.isCurrentUserFollowing ?? false)
    }

    @objc
    func avatarViewTapped() {
        viewModel?.avatarViewTapped()
    }

    func updateFollowStatus() {
        self.viewModel?.followUserWith(finish: { [weak self] (hadFollow) in
            self?.followBtn.reloadUIForIsFollowed(hadFollow)
        })
    }

}
