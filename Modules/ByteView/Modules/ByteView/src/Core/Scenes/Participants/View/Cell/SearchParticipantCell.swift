//
//  SearchParticipantCell.swift
//  ByteView
//
//  Created by wulv on 2022/2/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI
import UIKit

/// 搜索参会人Cell样式，数字表示间隙:
/// |------------------------------------------------------------------------------------------------|
/// |----------------------昵称-0-小尾巴-4-勿扰-4-个人状态-4-pstn标识-4-设备标识-4-共享标识-4-离开状态        ｜
/// |-16-头像(红点、动画)-12-                                                             -8-操作按钮-16-｜
/// |----------------------主持人标签-4-传译员标签-4-外部/请假标签-4-焦点视频-4-申请发言-4-子标题               |
/// |-------------------------------------------------------------------------------------------------|
class SearchParticipantCell: BaseParticipantCell {

    // MARK: - SubViews
    /// 勿扰
    lazy var disturbedIcon = ParticipantDisturbedIcon(isHidden: true)
    /// 个人状态
    lazy var userStatusIcon = UserFocusTagView()
    /// pstn标识（callMe/快捷电话邀请）
    lazy var pstnIcon = ParticipantPstnIcon(isHidden: true)
    /// 设备标识(手机/web)
    lazy var deviceImageView = ParticipantImageView(frame: CGRect.zero)
    /// 共享标识
    lazy var shareIcon = ParticipantShareIcon(isHidden: true)
    /// 主持人/联席主持人标签
    lazy var roleLabel = ParticipantRoleLabel(isHidden: true)
    /// 传译标签
    lazy var interpretLabel = ParticipantInterpretLabel(isHidden: true)
    /// 外部标签 或 请假标签
    lazy var userFlagView = ParticipantUserFlagLabel(type: .none)
    /// 焦点视频
    lazy var focusLabel = ParticipantFocusLabel(isHidden: true)
    /// 申请发言
    lazy var handsUpLabel = ParticipantHandsUpLabel(isHidden: true)
    /// 子标题
    lazy var subtitleLabel = ParticipantSubtitleLabel(isHidden: true)
    /// 离开状态
    lazy var statusLeaveIcon = ParticipantLeaveIcon(isHidden: true)
    /// 头像动画
    lazy var avatarAnimateMask: UIImageView = {
        let avatarAnimateMask = UIImageView(frame: CGRect(x: 0, y: 0, width: ParticipantAvatarView.Size.width, height: ParticipantAvatarView.Size.height))
        avatarAnimateMask.contentMode = .center
        avatarAnimateMask.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
        avatarAnimateMask.layer.cornerRadius = ParticipantAvatarView.Size.height / 2
        avatarAnimateMask.clipsToBounds = true
        return avatarAnimateMask
    }()
    /// 操作按钮
    lazy var eventButton: ParticipantButton = {
        let b = ParticipantButton(style: .none)
        b.touchUpInsideAction = { [weak self] in
            self?.throttleEvent(())
        }
        return b
    }()
    private lazy var throttleEvent: Throttle<Void> = {
        throttle(interval: .seconds(1)) { [weak self] in
            self?.tapEventButton?()
        }
    }()
    /// 操作按钮事件
    var tapEventButton: (() -> Void)?

    // MARK: - Override
    override func loadSubViews() {
        super.loadSubViews()
        contentStackView.insertSubview(avatarAnimateMask, aboveSubview: avatarView)
        nameLabel.snp.remakeConstraints { (maker) in
            maker.height.equalTo(24)
        }
        statusStack(add: [disturbedIcon, userStatusIcon, pstnIcon, deviceImageView, shareIcon, statusLeaveIcon])
        centerBotttomStatck(add: [roleLabel, interpretLabel, userFlagView, focusLabel, handsUpLabel, subtitleLabel])
        rightStack(add: [eventButton])
        statusLeaveIcon.snp.remakeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
    }

    override func configure(with model: BaseParticipantCellModel) {
        super.configure(with: model)
        guard let searchModel = model as? SearchParticipantCellModel else { return }
        selectionStyle = searchModel.selectionStyle
        setAvatarMaskAnimation(searchModel.roomAnimation)
        disturbedIcon.isHidden = !searchModel.showDisturbedIcon
        userStatusIcon.setCustomStatuses(searchModel.customStatuses)
        pstnIcon.isHidden = !searchModel.showPstnIcon
        deviceImageView.key = searchModel.deviceImgKey
        deviceImageView.isHidden = searchModel.deviceImgKey == .empty
        shareIcon.isHidden = !searchModel.showShareIcon
        statusLeaveIcon.isHidden = !searchModel.showLeaveIcon
        roleLabel.config = searchModel.roleConfig
        interpretLabel.interpret = searchModel.interpret
        if let flagType = UserFlagType.fromRelationTag(searchModel.relationTag) {
            userFlagView.type = flagType
        } else {
            userFlagView.type = model.isRelationTagEnabled ? .none : searchModel.userFlag
        }
        focusLabel.isHidden = !searchModel.showFocus
        handsUpLabel.isHidden = !searchModel.showMicHandsUp && !searchModel.showCameraHandsUp && !searchModel.showLocalRecordHandsUp
        handsUpLabel.setText(isMicrophone: searchModel.showMicHandsUp, isCamera: searchModel.showCameraHandsUp, isLocalRecord: searchModel.showLocalRecordHandsUp)
        subtitleLabel.subtitle = searchModel.subtitle
        eventButton.style = searchModel.buttonStyle
        requestInterpretIfNeeded()
        requestRelationTagIfNeeded()
    }
}
    // MARK: - Private
extension SearchParticipantCell {

    private func setAvatarMaskAnimation(_ animation: MaskAnimation?) {
        if let animation = animation {
            avatarAnimateMask.animationImages = animation.images
            avatarAnimateMask.animationDuration = animation.duration
            avatarAnimateMask.animationRepeatCount = animation.repeatCount
            avatarAnimateMask.startAnimating()
            avatarAnimateMask.isHidden = false
        } else {
            avatarAnimateMask.animationImages = nil
            avatarAnimateMask.stopAnimating()
            avatarAnimateMask.isHidden = true
        }
    }

    private func requestInterpretIfNeeded() {
        guard let searchModel = cellModel as? SearchParticipantCellModel else { return }
        searchModel.getInterpretTag { [weak self] tag in
            Util.runInMainThread {
                self?.interpretLabel.interpret = tag
            }
        }
    }

    func requestRelationTagIfNeeded() {
        guard let searchModel = cellModel as? SearchParticipantCellModel else { return }
        searchModel.getRelationTag { [weak self, weak searchModel] flagType in
            Util.runInMainThread {
                guard let currentModel = self?.cellModel as? SearchParticipantCellModel,
                      currentModel.pID == searchModel?.pID else { return } // 避免重用问题
                self?.updateUserFlagView(flagType)
            }
        }
    }

    private func updateUserFlagView(_ flagType: UserFlagType?) {
        if let flagType = flagType {
            self.userFlagView.type = flagType
            return
        }
        let searchModel = cellModel as? SearchParticipantCellModel
        self.userFlagView.type = searchModel?.userFlag ?? .none
    }
}
