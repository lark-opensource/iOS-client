//
//  MomentsFollowButton.swift
//  Moment
//
//  Created by liluobin on 2021/3/9.
//

import Foundation
import UIKit
import SnapKit
import LarkInteraction

final class MomentsFollowButton: UIButton {
    var suggestWidth: CGFloat = 71

    let icon = UIImageView()
    let label = UILabel()
    let centerView = UIView()
    var isFollowed: Bool = false
    var clickCallBack: ((Bool) -> Void)?
    init(isFollowed: Bool, clickCallBack: ((Bool ) -> Void)?) {
        self.isFollowed = isFollowed
        self.clickCallBack = clickCallBack
        super.init(frame: .zero)
        setupUI()
        self.addPointer(.lift)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = .clear
        self.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        /// 背景样式
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor

        centerView.isUserInteractionEnabled = false
        self.addSubview(centerView)
        centerView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        centerView.addSubview(icon)
        icon.image = nil
        icon.tintColor = UIColor.ud.primaryContentDefault
        icon.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.height.equalTo(12)
            make.centerY.equalToSuperview()
        }

        label.text = ""
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.primaryContentDefault
        centerView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalTo(icon.snp.right).offset(4)
            make.right.equalToSuperview()
            make.height.greaterThanOrEqualTo(12)
            make.top.bottom.equalToSuperview()
        }
        if isFollowed {
            showFollwedUI()
        } else {
            showUnFollwedUI()
        }
        self.updateCenterViewConstraints()
    }

    private func showFollwedUI() {
        self.icon.image = nil
        self.label.text = BundleI18n.Moment.Lark_Community_Followed
        self.label.textColor = UIColor.ud.N900
        self.layer.borderColor = UIColor.ud.N400.cgColor
        self.updateConstraintsForFollwedUI()
    }

    private func showUnFollwedUI() {
        self.icon.image = Resources.postFollow.withRenderingMode(.alwaysTemplate)
        self.label.text = BundleI18n.Moment.Lark_Community_Attention
        self.label.textColor = UIColor.ud.primaryContentDefault
        self.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        self.updateConstraintsForUnFollwedUI()
    }

    private func updateConstraintsForUnFollwedUI() {
        icon.snp.updateConstraints { (make) in
            make.width.equalTo(12)
        }
        label.snp.updateConstraints { (make) in
            make.left.equalTo(icon.snp.right).offset(4)
        }
    }

    private func updateConstraintsForFollwedUI() {
        icon.snp.updateConstraints { (make) in
            make.width.equalTo(0)
        }
        label.snp.updateConstraints { (make) in
            make.left.equalTo(icon.snp.right).offset(0)
        }
    }

    /// 宽度计算 UI对这一块要求严格
    private func updateCenterViewConstraints() {
        centerView.snp.removeConstraints()
        let size = centerView.systemLayoutSizeFitting(UIScreen.main.bounds.size)
        var centerViewWidth = size.width.rounded(.up)
        var width = centerViewWidth
        width = max(width + 12, 70)
        width = min(width, 110)
        suggestWidth = width

        /// 自动撑开布局
        var space = (suggestWidth - centerViewWidth) / 2.0
        if space < 0 {
            space = 0
            centerViewWidth = suggestWidth
        }
        centerView.snp.remakeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(space)
            make.right.equalToSuperview().offset(-space)
            make.width.equalTo(centerViewWidth)
            make.height.equalTo(28)
        }
    }

    @objc
    func btnClick() {
        icon.image = Resources.postFollowing.withRenderingMode(.alwaysTemplate)
        icon.lu.addRotateAnimation()
        icon.snp.updateConstraints { (make) in
            make.width.equalTo(12)
        }
        label.snp.updateConstraints { (make) in
            make.left.equalTo(icon.snp.right).offset(4)
        }
        self.layoutIfNeeded()
        updateCenterViewConstraints()
        if isFollowed {
            label.textColor = UIColor.ud.N500
        } else {
            label.textColor = UIColor.ud.B300
        }
        self.clickCallBack?(isFollowed)
    }

    func reloadUIForIsFollowed(_ followed: Bool) {
        self.icon.lu.removeRotateAnimation()
        self.isFollowed = followed
        if followed {
            self.showFollwedUI()
        } else {
            self.showUnFollwedUI()
        }
        self.updateCenterViewConstraints()
    }
}
