//
//  AttendeeParticipantCell.swift
//  ByteView
//
//  Created by wulv on 2022/9/26.
//

import Foundation
import ByteViewUI

/// 观众列表Cell样式，数字表示间隙：
/// |-------------------------------------------------------------------|
/// |------------昵称-4-pstn标识-4-设备标识-4-离开状态                       |
/// |-16-头像(红点)-12-                           -12-举手状态-16-麦克风-16-|
/// |------------传译员标签-4-外部标签-4-申请发言                            |
/// |-------------------------------------------------------------------|
class AttendeeParticipantCell: BaseParticipantCell {
    // MARK: - SubViews

    /// pstn标识（callMe/快捷电话邀请）
    lazy var pstnIcon = ParticipantPstnIcon(isHidden: true)
    /// 设备标识(手机/web)
    lazy var deviceImageView = ParticipantImageView(frame: CGRect.zero)
    /// 传译标签
    lazy var interpretLabel = ParticipantInterpretLabel(isHidden: true)
    /// 外部标签
    lazy var userFlagView = ParticipantUserFlagLabel(type: .none)
    /// 申请发言
    lazy var handsUpLabel = ParticipantHandsUpLabel(isHidden: true)
    /// 麦克风
    lazy var microphoneIcon = MicIconView(iconSize: 20, normalColor: UIColor.ud.iconN3)
    /// 举手状态
    lazy var statusHandsUpIcon = ParticipantStatusHandsUpIcon(isHidden: true)
    /// 离开状态
    lazy var statusLeaveIcon = ParticipantLeaveIcon(isHidden: true)

    private weak var volumeManager: VolumeManager?

    // MARK: - Override
    override func loadSubViews() {
        super.loadSubViews()
        statusStack(add: [pstnIcon, deviceImageView, statusLeaveIcon])
        centerBotttomStatck(add: [interpretLabel, userFlagView, handsUpLabel])
        rightStack(add: [statusHandsUpIcon, microphoneIcon])

        statusLeaveIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        statusHandsUpIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        microphoneIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        volumeManager?.removeListener(self)
    }

    override func configure(with model: BaseParticipantCellModel) {
        let lastModel = cellModel
        cellModel = model
        constructUserInfo(lastModel)
        avatarView.showRedDot = model.showRedDot
        nameTailLabel.nameTail = model.nameTail
        guard let attendeeModel = model as? AttendeeParticipantCellModel else { return }
        selectionStyle = attendeeModel.selectionStyle
        pstnIcon.isHidden = !attendeeModel.showPstnIcon
        deviceImageView.key = attendeeModel.deviceImgKey
        deviceImageView.isHidden = attendeeModel.deviceImgKey == .empty
        interpretLabel.interpret = attendeeModel.interpret
        if let flagType = UserFlagType.fromRelationTag(attendeeModel.relationTag) {
            userFlagView.type = flagType
        } else {
            userFlagView.type = model.isRelationTagEnabled ? .none : attendeeModel.userFlag
        }
        handsUpLabel.isHidden = !attendeeModel.showHandsUp
        handsUpLabel.setText(isMicrophone: attendeeModel.showHandsUp)
        statusHandsUpIcon.isHidden = !attendeeModel.showStatusHandsUp
        statusHandsUpIcon.key = .handsUp(attendeeModel.handsUpEmojiKey)
        statusLeaveIcon.isHidden = !attendeeModel.showLeaveIcon
        microphoneIcon.isHidden = attendeeModel.micState == .hidden
        microphoneIcon.setMicState(attendeeModel.micState)
        volumeManager = attendeeModel.volumeManager
        volumeManager?.addListener(self)
        requestInterpretIfNeeded()
        requestRelationTagIfNeeded()
    }
}

// MARK: - Private
extension AttendeeParticipantCell {

    private func constructUserInfo(_ lastModel: BaseParticipantCellModel?) {
        if let attendeeModel = cellModel as? AttendeeParticipantCellModel {
            if let lastModel = lastModel as? AttendeeParticipantCellModel,
                lastModel.participant.participantId == attendeeModel.participant.participantId {
            } else {
                avatarView.avatarInfo = attendeeModel.avatarInfo
                nameLabel.displayName = attendeeModel.displayName
            }
        }
        requestUserInfoIfNeeded()
    }

    private func requestInterpretIfNeeded() {
        guard let attendeeModel = cellModel as? AttendeeParticipantCellModel else { return }
        attendeeModel.getInterpretTag { [weak self, weak attendeeModel] tag in
            Util.runInMainThread {
                guard let currentModel = self?.cellModel as? AttendeeParticipantCellModel,
                      currentModel.participant.participantId == attendeeModel?.participant.participantId else { return } // 避免重用问题
                self?.interpretLabel.interpret = tag
            }
        }
    }

    private func requestUserInfoIfNeeded() {
        guard let attendeeModel = cellModel as? AttendeeParticipantCellModel else { return }
        attendeeModel.getDetailInfo { [weak self] in
            guard let currentModel = self?.cellModel as? AttendeeParticipantCellModel,
                  currentModel.participant.participantId == attendeeModel.participant.participantId else { return } // 避免重用问题
            self?.avatarView.avatarInfo = attendeeModel.avatarInfo
            self?.nameLabel.displayName = attendeeModel.displayName
            Logger.participant.debug("attendee cell get detail info, larkUid = \(attendeeModel.participant.participantId.larkUserId), avatarInfo = \(attendeeModel.avatarInfo)")
        }
    }
}

// MARK: - VolumeManagerDelegate
extension AttendeeParticipantCell: VolumeManagerDelegate {
    func volumeDidChange(to volume: Int, rtcUid: RtcUID) {
        guard let attendeeModel = cellModel as? AttendeeParticipantCellModel, attendeeModel.micState == .on() else {
            return
        }
        if rtcUid == attendeeModel.participant.rtcUid || (rtcUid == attendeeModel.participant.callMeInfo.rtcUID && attendeeModel.participant.callMeInfo.status == .onTheCall) {
            microphoneIcon.micOnView.updateVolume(volume)
        }
    }
}

extension AttendeeParticipantCell {
    func requestRelationTagIfNeeded() {
        guard let attendeeModel = cellModel as? AttendeeParticipantCellModel else { return }
        attendeeModel.getRelationTag { [weak self] flagType in
            Util.runInMainThread {
                self?.updateUserFlagView(flagType)
            }
        }
    }

    private func updateUserFlagView(_ flagType: UserFlagType?) {
        if let flagType = flagType {
            self.userFlagView.type = flagType
            return
        }
        let attendeeModel = cellModel as? AttendeeParticipantCellModel
        self.userFlagView.type = attendeeModel?.userFlag ?? .none
    }
}
