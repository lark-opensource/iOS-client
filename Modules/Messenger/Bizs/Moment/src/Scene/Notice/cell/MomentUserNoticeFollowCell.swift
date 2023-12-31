//
//  MomentUserNoticeFollowCell.swift
//  Moment
//
//  Created by bytedance on 2021/2/22.
//

import Foundation
import UIKit
import LarkInteraction

final class MomentUserNoticeFollowCell: MomentUserNotieBaseCell {

    let icon = UIImageView()
    let label = UILabel()
    let centerView = UIView()
    let bgBtn: UIButton = UIButton()
    var followerBtnWidth: CGFloat = 71

    override func configRightView() -> UIView {
        /// 背景按钮样式
        bgBtn.layer.cornerRadius = 8
        bgBtn.layer.borderWidth = 1
        bgBtn.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)

        centerView.isUserInteractionEnabled = false
        bgBtn.addSubview(centerView)
        centerView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        centerView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.height.equalTo(12)
            make.centerY.equalToSuperview()
        }
        icon.tintColor = .ud.primaryContentDefault
        icon.image = nil
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
        bgBtn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        bgBtn.addPointer(.lift)
        bgBtn.isHidden = viewModel?.momentsAccountService?.getCurrentUserIsOfficialUser() ?? false
        return bgBtn
    }

    override func layoutRightView(_ view: UIView) {
        view.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(28)
            make.width.equalTo(self.followerBtnWidth)
        }
    }

    override class func getCellReuseIdentifier() -> String {
        return "MomentUserNoticeFollowCell"
    }

    override func updateRightViewWithVM(_ vm: MomentsNoticeBaseCellViewModel) {
        if let vm = viewModel as? MomentsNoticefollowCellViewModel {
            bgBtn.isHidden = !vm.followable
            if !vm.followable {
                return
            }
        }
        if userIsFollowed() {
            showFollwedUI()
        } else {
            showUnFollwedUI()
        }
        self.updateBgViewWidth()
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
        updateBgViewWidth()
        self.bgBtn.layoutIfNeeded()
        if self.userIsFollowed() {
            label.textColor = UIColor.ud.textPlaceholder
        } else {
            label.textColor = UIColor.ud.primaryContentDefault
        }
        if let vm = viewModel as? MomentsNoticefollowCellViewModel {
            vm.followUserWith(finish: { [weak self] (isFollowed) in
                guard let self = self else { return }
                self.icon.lu.removeRotateAnimation()
                if isFollowed {
                    self.showFollwedUI()
                } else {
                    self.showUnFollwedUI()
                }
                self.updateBgViewWidth()
            })
        }
    }
    private func userIsFollowed() -> Bool {
        if let entity = self.viewModel?.noticeEntity.noticeType.getBinderData() as? RawData.NoticeFollowerEntity {
            return entity.hadFollow
        }
        return false
    }

    private func showFollwedUI() {
        self.icon.image = nil
        self.label.text = BundleI18n.Moment.Lark_Community_Followed
        self.label.textColor = UIColor.ud.textTitle
        self.bgBtn.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        self.updateConstraintsForFollwedUI()
    }

    private func showUnFollwedUI() {
        self.icon.image = Resources.postFollow.withRenderingMode(.alwaysTemplate)
        self.label.text = BundleI18n.Moment.Lark_Community_Attention
        self.label.textColor = UIColor.ud.primaryContentDefault
        self.bgBtn.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        updateConstraintsForUnFollwedUI()
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
    private func updateBgViewWidth() {
        let centerViewWidth = centerView.systemLayoutSizeFitting(self.bounds.size).width.rounded(.up)
        var width = centerViewWidth
        width = max(width + 12, 70)
        width = min(width, 110)
        bgBtn.snp.updateConstraints { (make) in
            make.width.equalTo(width)
        }
    }
}
