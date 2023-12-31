//
//  LobbyParticipantCell.swift
//  ByteView
//
//  Created by wulv on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// 等候室Cell样式，数字表示间隙:
/// |-----------------------------------------------------------------------------|
/// |------------昵称-0-小尾巴-4-设备标识                                            ｜
/// |-16-头像-12-                      ----------------------8-移除按钮-8-允许按钮-16-｜
/// |------------外部标签-4-会议室地点                                                |
/// |-----------------------------------------------------------------------------｜
class LobbyParticipantCell: BaseParticipantCell {

    // MARK: - SubViews
    /// 设备标识(快捷电话邀请)
    lazy var deviceImageView = ParticipantImageView(frame: CGRect.zero)
    /// 外部标签
    lazy var userFlagView = ParticipantUserFlagLabel(type: .none)
    /// 会议室地点
    lazy var roomLabel = ParticipantRoomLabel(isHidden: true)
    /// 按钮 - 移出等候室
    lazy var removeButton: ParticipantButton = {
       let b = ParticipantButton(style: .none)
        b.touchUpInsideAction = { [weak self] in
            self?.throttleRemove(())
        }
        return b
    }()
    private lazy var throttleRemove: Throttle<Void> = {
        throttle(interval: .seconds(1)) { [weak self] in
            self?.tapRemoveButton?()
        }
    }()
    /// 按钮事件 - 移出等候室
    var tapRemoveButton: (() -> Void)?
    /// 按钮 - 允许入会
    lazy var admitButton: ParticipantButton = {
        let b = ParticipantButton(style: .none)
        b.touchUpInsideAction = { [weak self] in
            self?.throttleAdmit(())
        }
        return b
    }()
    private lazy var throttleAdmit: Throttle<Void> = {
        throttle(interval: .seconds(1)) { [weak self] in
            self?.tapAdmitButton?()
        }
    }()
    /// 按钮事件 - 允许入会
    var tapAdmitButton: (() -> Void)?

    // MARK: - Override
    override func loadSubViews() {
        super.loadSubViews()
        selectionStyle = .none
        statusStack(add: [deviceImageView])
        centerBotttomStatck(add: [userFlagView, roomLabel])
        rightStack(add: [removeButton, admitButton])
        rightStackView.spacing = 8
    }

    override func configure(with model: BaseParticipantCellModel) {
        let lastModel = cellModel
        cellModel = model
        constructUserInfo(lastModel)
        avatarView.showRedDot = model.showRedDot
        nameTailLabel.nameTail = model.nameTail
        guard let lobbyModel = model as? LobbyParticipantCellModel else { return }
        deviceImageView.key = lobbyModel.deviceImgKey
        deviceImageView.isHidden = lobbyModel.deviceImgKey == .none
        if let flagType = UserFlagType.fromRelationTag(lobbyModel.relationTag) {
            userFlagView.type = flagType
        } else {
            userFlagView.type = .none
        }
        roomLabel.room = lobbyModel.room
        removeButton.style = lobbyModel.removeButtonStyle
        admitButton.style = lobbyModel.admitButtonStyle
        requestRelationTagIfNeeded()
    }
}

// MARK: - Private
extension LobbyParticipantCell {

    private func constructUserInfo(_ lastModel: BaseParticipantCellModel?) {
        if let lobbyModel = cellModel as? LobbyParticipantCellModel {
            if let lastModel = lastModel as? LobbyParticipantCellModel,
                lastModel.lobbyParticipant.participantId == lobbyModel.lobbyParticipant.participantId {
            } else {
                avatarView.avatarInfo = lobbyModel.avatarInfo
                nameLabel.displayName = lobbyModel.displayName
            }
        }
        requestUserInfoIfNeeded()
    }

    private func requestUserInfoIfNeeded() {
        guard let lobbyModel = cellModel as? LobbyParticipantCellModel else { return }
        lobbyModel.getDetailInfo { [weak self] in
            guard let currentModel = self?.cellModel as? LobbyParticipantCellModel,
                  currentModel.lobbyParticipant.participantId == lobbyModel.lobbyParticipant.participantId else { return } // 避免重用问题
            self?.avatarView.avatarInfo = lobbyModel.avatarInfo
            self?.nameLabel.displayName = lobbyModel.displayName
            Logger.participant.debug("lobby cell get detail info, larkUid = \(lobbyModel.lobbyParticipant.participantId.larkUserId), avatarInfo = \(lobbyModel.avatarInfo)")

        }
    }

    func requestRelationTagIfNeeded() {
        guard let lobbyModel = cellModel as? LobbyParticipantCellModel else { return }
        lobbyModel.getRelationTag { [weak self, weak lobbyModel] userFlagType in
            Util.runInMainThread {
                guard let currentModel = self?.cellModel as? LobbyParticipantCellModel,
                      currentModel.lobbyParticipant.participantId == lobbyModel?.lobbyParticipant.participantId else { return } // 避免重用问题
                if let userFlagType = userFlagType {
                    self?.userFlagView.type = userFlagType
                } else {
                    let lobbyModel = self?.cellModel as? LobbyParticipantCellModel
                    self?.userFlagView.type = lobbyModel?.userFlag ?? .none
                }
            }
        }
    }
}
