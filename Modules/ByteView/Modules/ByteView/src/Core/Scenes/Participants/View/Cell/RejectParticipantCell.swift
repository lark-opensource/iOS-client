//
//  RejectParticipantCell.swift
//  ByteView
//
//  Created by wulv on 2022/5/23.
//

import Foundation
import ByteViewUI

/// 已拒绝日程的参会人列表Cell样式，数字表示间隙:
/// |-------------------------------------------------------------------|
/// |------------昵称-0-小尾巴-4-个人状态                                  ｜
/// |-16-头像-12-                     ----------------------8-呼叫按钮-16-｜
/// |------------外部标签-4-会议室地点                                      |
/// |-------------------------------------------------------------------｜
class RejectParticipantCell: BaseParticipantCell {

    // MARK: - SubViews
    /// 个人状态
    lazy var userStatusIcon = UserFocusTagView()
    /// 外部标签
    lazy var userFlagView = ParticipantUserFlagLabel(type: .none)
    /// 会议室地点
    lazy var roomLabel = ParticipantRoomLabel(isHidden: true)
    /// 按钮 - 呼叫
    lazy var callButton: ParticipantButton = {
        let b = ParticipantButton(style: .none)
        b.touchUpInsideAction = { [weak self] in
            self?.throttleCall(())
        }
        return b
    }()
    private lazy var throttleCall: Throttle<Void> = {
        throttle(interval: .seconds(1)) { [weak self] in
            self?.tapCallButton?()
        }
    }()
    /// 按钮事件 - 呼叫
    var tapCallButton: (() -> Void)?

    // MARK: - Override
    override func loadSubViews() {
        super.loadSubViews()
        selectionStyle = .none
        statusStack(add: [userStatusIcon])
        centerBotttomStatck(add: [userFlagView, roomLabel])
        rightStack(add: [callButton])
    }

    override func configure(with model: BaseParticipantCellModel) {
        super.configure(with: model)
        guard let rejectModel = model as? RejectParticipantCellModel else { return }
        userStatusIcon.setCustomStatuses(rejectModel.customStatuses)
        if let flagType = UserFlagType.fromRelationTag(rejectModel.relationTag) {
            userFlagView.type = flagType
        } else {
            userFlagView.type = model.isRelationTagEnabled ? .none : rejectModel.userFlag
        }
        roomLabel.room = rejectModel.room
        callButton.style = rejectModel.buttonStyle
        requestRelationTagIfNeeded()
    }

    func requestRelationTagIfNeeded() {
        guard let rejectModel = cellModel as? RejectParticipantCellModel else { return }
        rejectModel.getRelationTag { [weak self, weak rejectModel] flagType in
            Util.runInMainThread {
                guard let currentModel = self?.cellModel as? RejectParticipantCellModel,
                      currentModel.participant.participantId == rejectModel?.participant.participantId else { return } // 避免重用问题
                if let flagType = flagType {
                    self?.userFlagView.type = flagType
                } else {
                    let rejectModel = self?.cellModel as? RejectParticipantCellModel
                    self?.userFlagView.type = rejectModel?.userFlag ?? .none
                }
            }
        }
    }
}
