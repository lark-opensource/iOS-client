//
//  InvitedParticipantCell.swift
//  ByteView
//
//  Created by wulv on 2022/2/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignTheme
import Lottie

/// 呼叫中Cell样式，数字表示间隙:
/// |----------------------------------------------------------------------------|
/// |-----------------昵称-0-小尾巴-4-设备标识-4-呼叫反馈                             |
/// |-16-头像(涟漪)-12-                                 -8-转为电话呼叫-8-取消呼叫-16-｜
/// |-----------------外部标签-4-拒绝回复-4-会议室地点                                ｜
/// |----------------------------------------------------------------------------｜
class InvitedParticipantCell: BaseParticipantCell {

    // MARK: - SubViews
    /// 头像涟漪
    lazy var rippleView: LOTAnimationView = {
        var ripple: String = ""
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            ripple = "rippleWhite"
        } else {
            ripple = "ripple"
        }
        let rippleView = LOTAnimationView(name: ripple, bundle: .localResources)
        rippleView.loopAnimation = true
        return rippleView
    }()
    /// 设备标识(快捷电话邀请)
    lazy var deviceImageView = ParticipantImageView(frame: CGRect.zero)
    /// 呼叫反馈
    lazy var inviteFeedbackLabel = ParticipantFeedbackLabel(isHidden: true)
    /// 拒绝回复
    lazy var refuseLabel = ParticipantRefuseReplyLabel(isHidden: true)
    /// 外部标签
    lazy var userFlagView = ParticipantUserFlagLabel(type: .none)
    /// 会议室地点
    lazy var roomLabel = ParticipantRoomLabel(isHidden: true)
    /// 按钮 - 转为电话呼叫
    lazy var convertPSTNButton: ParticipantButton = {
        let b = ParticipantButton(style: .none)
        b.touchUpInsideAction = { [weak self] in
            self?.throttleConvertPSTN(())
        }
        return b
    }()
    private lazy var throttleConvertPSTN: Throttle<Void> = {
        throttle(interval: .seconds(1)) { [weak self] in
            self?.tapConvertPSTNButton?()
        }
    }()
    /// 按钮事件 - 转为电话呼叫
    var tapConvertPSTNButton: (() -> Void)?
    /// 按钮 - 取消
    lazy var cancelButton: ParticipantButton = {
        let b = ParticipantButton(style: .none)
        b.touchUpInsideAction = { [weak self] in
            self?.throttleCancel(())
        }
        return b
    }()
    private lazy var throttleCancel: Throttle<Void> = {
        throttle(interval: .seconds(1)) { [weak self] in
            self?.tapCancelButton?()
        }
    }()
    /// 按钮事件 - 取消
    var tapCancelButton: (() -> Void)?

    // MARK: - Override
    override func loadSubViews() {
        super.loadSubViews()
        selectionStyle = .none
        leftStackView.insertSubview(rippleView, belowSubview: avatarView)
        rippleView.snp.makeConstraints { make in
            make.center.equalTo(avatarView.snp.center)
            make.width.equalTo(avatarView.snp.width).offset(12.0)
            make.height.equalTo(avatarView.snp.height).offset(12.0)
        }
        rippleView.play()
        statusStack(add: [deviceImageView, inviteFeedbackLabel])
        centerBotttomStatck(add: [userFlagView, refuseLabel, roomLabel])
        rightStack(add: [convertPSTNButton, cancelButton])
        rightStackView.spacing = 8
    }

    override func configure(with model: BaseParticipantCellModel) {
        let lastModel = cellModel
        cellModel = model
        constructUserInfo(lastModel)
        avatarView.showRedDot = model.showRedDot
        nameTailLabel.nameTail = model.nameTail
        guard let inviteModel = model as? InvitedParticipantCellModel else { return }
        if inviteModel.playRipple {
            rippleView.isHidden = false
            rippleView.play()
        } else {
            rippleView.stop()
            rippleView.isHidden = true
        }
        deviceImageView.key = inviteModel.deviceImgKey
        deviceImageView.isHidden = inviteModel.deviceImgKey == .empty
        inviteFeedbackLabel.feedback = inviteModel.inviteFeedback
        refuseLabel.refuseReply = inviteModel.refuseReply
        userFlagView.setMinWidth(inviteModel.hasRefuseReply ? 80 : nil)
        if let flagType = UserFlagType.fromRelationTag(inviteModel.relationTag) {
            userFlagView.type = flagType
        } else {
            userFlagView.type = model.isRelationTagEnabled ? .none : inviteModel.userFlag
        }
        roomLabel.room = inviteModel.room
        convertPSTNButton.style = inviteModel.convertPSTNStyle
        cancelButton.style = inviteModel.cancelStyle
        requestRelationTagIfNeeded()
    }
}

// MARK: - Private
extension InvitedParticipantCell {

    private func constructUserInfo(_ lastModel: BaseParticipantCellModel?) {
        if let inviteModel = cellModel as? InvitedParticipantCellModel {
            if let lastModel = lastModel as? InvitedParticipantCellModel,
                lastModel.participant.participantId == inviteModel.participant.participantId {
            } else {
                avatarView.avatarInfo = inviteModel.avatarInfo
                nameLabel.displayName = inviteModel.displayName
            }
        }
        requestUserInfoIfNeeded()
    }

    private func requestUserInfoIfNeeded() {
        guard let inviteModel = cellModel as? InvitedParticipantCellModel else { return }
        inviteModel.getDetailInfo { [weak self] in
            guard let currentModel = self?.cellModel as? InvitedParticipantCellModel,
                  currentModel.participant.participantId == inviteModel.participant.participantId else { return } // 避免重用问题
            self?.avatarView.avatarInfo = inviteModel.avatarInfo
            self?.nameLabel.displayName = inviteModel.displayName
            Logger.participant.debug("invite cell get detail info, larkUid = \(inviteModel.participant.participantId.larkUserId), avatarInfo = \(inviteModel.avatarInfo)")
        }
    }

    func requestRelationTagIfNeeded() {
        guard let invitedModel = cellModel as? InvitedParticipantCellModel else { return }
        invitedModel.getRelationTag { [weak self, weak invitedModel] userFlagType in
            Util.runInMainThread {
                guard let currentModel = self?.cellModel as? InvitedParticipantCellModel,
                      currentModel.participant.participantId == invitedModel?.participant.participantId else { return } // 避免重用问题
                if let userFlagType = userFlagType {
                    self?.userFlagView.type = userFlagType
                } else {
                    let inviteModel = self?.cellModel as? InvitedParticipantCellModel
                    self?.userFlagView.type = inviteModel?.userFlag ?? .none
                }
            }
        }
    }
}
