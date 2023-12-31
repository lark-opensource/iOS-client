//
//  InMeetParticipantCell.swift
//  ByteView
//
//  Created by wulv on 2022/2/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import UIKit

/// 会中参会人Cell样式，数字表示间隙:
/// |---------------------------------------------------------------------------------------------------|
/// |-----------------昵称-0-小尾巴-4-pstn标识-4-设备标识-4-共享标识-4-离开状态                                ｜
/// |-16-头像(红点)-12-                                                  -8-举手状态-16-麦克风-16-摄像头-16-｜
/// |-----------------主持人标签-4-传译员标签-4-外部标签-4-焦点视频-4-申请发言                                  |
/// |---------------------------------------------------------------------------------------------------|
class InMeetParticipantCell: BaseParticipantCell {

    // MARK: - SubViews

    /// pstn标识（callMe/快捷电话邀请）
    lazy var pstnIcon = ParticipantPstnIcon(isHidden: true)
    /// 设备标识(手机/web)
    lazy var deviceImageView = ParticipantImageView(frame: CGRect.zero)
    /// 共享标识
    lazy var shareIcon = ParticipantShareIcon(isHidden: true)
    /// 系统电话标识
    lazy var systemCallingView = ParticipantSystemCallingView(isHidden: true)
    /// 主持人/联席主持人标签
    lazy var roleLabel = ParticipantRoleLabel(isHidden: true)
    /// 传译标签
    lazy var interpretLabel = ParticipantInterpretLabel(isHidden: true)
    /// 外部标签
    lazy var userFlagView = ParticipantUserFlagLabel(type: .none)
    /// 焦点视频
    lazy var focusLabel = ParticipantFocusLabel(isHidden: true)
    /// 申请发言
    lazy var handsUpLabel = ParticipantHandsUpLabel(isHidden: true)
    /// 摄像头
    lazy var cameraImageView = ParticipantImageView(frame: CGRect.zero)
    /// 麦克风
    lazy var microphoneIcon = MicIconView(iconSize: 20, normalColor: UIColor.ud.iconN3)
    /// 举手状态
    lazy var statusHandsUpIcon = ParticipantStatusHandsUpIcon(isHidden: true)
    /// 离开状态
    lazy var statusLeaveIcon = ParticipantLeaveIcon(isHidden: true)
    /// rooms参会人人数标签
    lazy var roomCountLabel = ParticipantRoomCountLabel(isHidden: true)
    /// 本地录制
    lazy var localRecordIcon = ParticipantRecordIcon(isHidden: true)

    private weak var volumeManager: VolumeManager?

    // MARK: - Override
    override func loadSubViews() {
        super.loadSubViews()
        nameLabel.snp.remakeConstraints { make in
            make.height.equalTo(24)
        }
        avatarView.addSubview(systemCallingView)
        statusStack(add: [pstnIcon, deviceImageView, localRecordIcon, shareIcon, statusLeaveIcon])
        nameStack(add: [roomCountLabel])
        centerBotttomStatck(add: [roleLabel, interpretLabel, userFlagView, focusLabel, handsUpLabel])
        rightStack(add: [statusHandsUpIcon, microphoneIcon, cameraImageView])
        systemCallingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        statusLeaveIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        statusHandsUpIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        microphoneIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        cameraImageView.snp.makeConstraints { (make) in
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
        guard let inMeetModel = model as? InMeetParticipantCellModel else { return }
        selectionStyle = inMeetModel.selectionStyle
        pstnIcon.isHidden = !inMeetModel.showPstnIcon
        deviceImageView.key = inMeetModel.deviceImgKey
        deviceImageView.isHidden = inMeetModel.deviceImgKey == .empty
        localRecordIcon.isHidden = !inMeetModel.showLocalRecordIcon
        shareIcon.isHidden = !inMeetModel.showShareIcon
        systemCallingView.isHidden = !inMeetModel.showSystemCallingStatus
        roleLabel.config = inMeetModel.roleConfig
        interpretLabel.interpret = inMeetModel.interpret
        if let flagType = UserFlagType.fromRelationTag(inMeetModel.relationTag) {
            userFlagView.type = flagType
        } else {
            userFlagView.type = model.isRelationTagEnabled ? .none : inMeetModel.userFlag
        }
        focusLabel.isHidden = !inMeetModel.showFocus
        handsUpLabel.isHidden = !inMeetModel.showMicHandsUp && !inMeetModel.showCameraHandsUp && !inMeetModel.showLocalRecordHandsUp
        handsUpLabel.setText(isMicrophone: inMeetModel.showMicHandsUp,
                             isCamera: inMeetModel.showCameraHandsUp,
                             isLocalRecord: inMeetModel.showLocalRecordHandsUp)
        microphoneIcon.isHidden = inMeetModel.micState == .hidden
        microphoneIcon.setMicState(inMeetModel.micState)
        cameraImageView.key = inMeetModel.cameraImgKey
        cameraImageView.isHidden = inMeetModel.cameraImgKey == .empty
        statusHandsUpIcon.isHidden = !inMeetModel.showStatusHandsUp
        statusHandsUpIcon.key = .handsUp(inMeetModel.handsUpEmojiKey)
        statusLeaveIcon.isHidden = !inMeetModel.showLeaveIcon
        roomCountLabel.roomCountMessage = inMeetModel.roomCountMessage
        volumeManager = inMeetModel.volumeManager
        volumeManager?.addListener(self)
        requestInterpretIfNeeded()
        requestRelationTagIfNeeded()
    }
}

// MARK: - Private
extension InMeetParticipantCell {
    private func requestInterpretIfNeeded() {
        guard let inMeetModel = cellModel as? InMeetParticipantCellModel else { return }
        inMeetModel.getInterpretTag { [weak self] tag in
            Util.runInMainThread {
                self?.interpretLabel.interpret = tag
            }
        }
    }

    func requestRelationTagIfNeeded() {
        guard let inMeetModel = cellModel as? InMeetParticipantCellModel else { return }
        inMeetModel.getRelationTag { [weak self, weak inMeetModel] flagType in
            Util.runInMainThread {
                guard let currentModel = self?.cellModel as? InMeetParticipantCellModel,
                      currentModel.participant.participantId == inMeetModel?.participant.participantId else { return } // 避免重用问题
                if let flagType = flagType {
                    self?.userFlagView.type = flagType
                } else {
                    let inMeetModel = self?.cellModel as? InMeetParticipantCellModel
                    self?.userFlagView.type = inMeetModel?.userFlag ?? .none
                }
            }
        }
    }

    private func constructUserInfo(_ lastModel: BaseParticipantCellModel?) {
        if let inMeetModel = cellModel as? InMeetParticipantCellModel {
            if let lastModel = lastModel as? InMeetParticipantCellModel,
                lastModel.participant.participantId == inMeetModel.participant.participantId {
            } else {
                avatarView.avatarInfo = inMeetModel.avatarInfo
                nameLabel.displayName = inMeetModel.displayName
            }
        }
        requestUserInfoIfNeeded()
    }

    private func requestUserInfoIfNeeded() {
        guard let inMeetModel = cellModel as? InMeetParticipantCellModel else { return }
        inMeetModel.getDetailInfo { [weak self] in
            guard let currentModel = self?.cellModel as? InMeetParticipantCellModel,
                  currentModel.participant.participantId == inMeetModel.participant.participantId else { return } // 避免重用问题
            self?.avatarView.avatarInfo = inMeetModel.avatarInfo
            self?.nameLabel.displayName = inMeetModel.displayName
            Logger.participant.debug("inMeet cell get detail info, larkUid = \(inMeetModel.participant.participantId.larkUserId), avatarInfo = \(inMeetModel.avatarInfo)")
        }
    }
}

extension InMeetParticipantCell: VolumeManagerDelegate {
    func volumeDidChange(to volume: Int, rtcUid: RtcUID) {
        guard let inMeetModel = cellModel as? InMeetParticipantCellModel, inMeetModel.micState == .on() else {
            return
        }
        if rtcUid == inMeetModel.participant.rtcUid || (rtcUid == inMeetModel.participant.callMeInfo.rtcUID && inMeetModel.participant.callMeInfo.status == .onTheCall) {
            microphoneIcon.micOnView.updateVolume(volume)
        }
    }
}
