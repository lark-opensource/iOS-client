//
//  InterpreterParticipantCell.swift
//  ByteView
//
//  Created by wulv on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 添加传译员 & 搜索传译员 cell样式，数字代表间隙：
/// |----------------------------------------------------------------------------------|
/// |-----------------昵称-0-小尾巴-4-入会状态-4-设备标识                                   |
/// |-16-头像(红点)-12-                                                             -16-｜
/// |-----------------主持人标签-4-传译员标签-4-外部标签-4-申请发言                           |
/// |----------------------------------------------------------------------------------｜
class InterpreterParticipantCell: BaseParticipantCell {

    // MARK: - SubViews
    /// 入会状态
    lazy var joinStateLabel = ParticipantJoinStateLabel(isHidden: false)
    /// 设备标识(手机/快捷电话邀请/web等)
    lazy var deviceImageView = ParticipantImageView(frame: CGRect.zero)
    /// 主持人/联席主持人标签
    lazy var roleLabel = ParticipantRoleLabel(isHidden: true)
    /// 传译标签
    lazy var interpretLabel = ParticipantInterpretLabel(isHidden: true)
    /// 外部标签
    lazy var userFlagView = ParticipantUserFlagLabel(type: .none)
    /// 申请发言
    lazy var handsUpLabel = ParticipantHandsUpLabel(isHidden: true)

    // MARK: - Override
    override func loadSubViews() {
        super.loadSubViews()
        nameLabel.snp.remakeConstraints { (maker) in
            maker.height.equalTo(24)
        }
        nameStack(add: [joinStateLabel])
        statusStack(add: [deviceImageView])
        centerBotttomStatck(add: [roleLabel, interpretLabel, userFlagView, handsUpLabel])
    }

    override func configure(with model: BaseParticipantCellModel) {
        super.configure(with: model)
        guard let interpretModel = model as? InterpreterParticipantCellModel else { return }
        joinStateLabel.state = interpretModel.joinState
        deviceImageView.key = interpretModel.deviceImgKey
        deviceImageView.isHidden = interpretModel.deviceImgKey == .empty
        roleLabel.config = interpretModel.roleConfig
        interpretLabel.interpret = interpretModel.interpret
        handsUpLabel.isHidden = !interpretModel.showMicHandsUp && !interpretModel.showCameraHandsUp && !interpretModel.showLocalRecordHandsUp
        handsUpLabel.setText(isMicrophone: interpretModel.showMicHandsUp, isCamera: interpretModel.showCameraHandsUp, isLocalRecord: interpretModel.showLocalRecordHandsUp)
        requestInterpretIfNeeded()
        if let flagType = UserFlagType.fromRelationTag(interpretModel.relationTag) {
            userFlagView.type = flagType
        } else {
            userFlagView.type = model.isRelationTagEnabled ? .none : interpretModel.userFlag
        }
        requestRelationTagIfNeeded()
    }
}

// MARK: - Private
extension InterpreterParticipantCell {

    private func requestInterpretIfNeeded() {
        guard let interpretModel = cellModel as? InterpreterParticipantCellModel else { return }
        interpretModel.getInterpretTag { [weak self] tag in
            Util.runInMainThread {
                self?.interpretLabel.interpret = tag
            }
        }
    }

    func requestRelationTagIfNeeded() {
        guard let interpretModel = cellModel as? InterpreterParticipantCellModel else { return }
        interpretModel.getRelationTag { [weak self, weak  interpretModel] flagType in
            Util.runInMainThread {
                guard let currentModel = self?.cellModel as? InterpreterParticipantCellModel,
                      currentModel.pID == interpretModel?.pID else { return } // 避免重用问题
                if let flagType = flagType {
                    self?.userFlagView.type = flagType
                } else {
                    let interpretModel = self?.cellModel as? InterpreterParticipantCellModel
                    self?.userFlagView.type = interpretModel?.userFlag ?? .none
                }
            }
        }
    }
}
