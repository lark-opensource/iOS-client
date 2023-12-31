//
//  SuggestionParticipantCell.swift
//  ByteView
//
//  Created by wulv on 2022/2/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUI
import UniverseDesignCheckBox

/// 建议列表Cell样式，数字表示间隙:
/// |-------------------------------------------------------------------|
/// |------------昵称-0-小尾巴-4-个人状态 -4-呼叫反馈                        |
/// |-16-头像-12-                                          -8-呼叫按钮-16-|
/// |------------传译员标签-4-外部标签-4-拒绝回复-4-会议室地点                 |
/// |-------------------------------------------------------------------|
///
/// 建议列表多选态Cell样式，数字表示间隙:
/// |-------------------------------------------------------------------|
/// |---------------------昵称-0-小尾巴-4-个人状态-4-呼叫反馈                ｜
/// |-16-勾选框-12-头像-12-                                               ｜
/// |---------------------传译员标签-4-外部标签-4-拒绝回复-4-会议室地点         |
/// |--------------------------------------------------------------------|
class SuggestionParticipantCell: BaseParticipantCell {

    // MARK: - SubViews
    /// 勾选框
    lazy var checkBox = UDCheckBox(boxType: .multiple)
    /// 个人状态
    lazy var userStatusIcon = UserFocusTagView()
    /// 呼叫反馈
    lazy var inviteFeedbackLabel = ParticipantFeedbackLabel(isHidden: true)
    /// 传译标签
    lazy var interpretLabel = ParticipantInterpretLabel(isHidden: true)
    /// 外部标签
    lazy var userFlagView = ParticipantUserFlagLabel(type: .none)
    /// 会议室地点
    lazy var roomLabel = ParticipantRoomLabel(isHidden: true)
    /// 拒绝回复
    lazy var refuseLabel = ParticipantRefuseReplyLabel(isHidden: true)
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
    private lazy var throttleRefuse: Throttle<Void> = {
        throttle(interval: .seconds(1)) { [weak self] in
            self?.tapShowRefuseReply?()
        }
    }()
    /// 蒙层（禁用态）
    lazy var disableCover: UIView = {
       let v = UIView()
        v.backgroundColor = UIColor.ud.bgFloat
        v.alpha = 0.5
        return v
    }()
    /// 按钮事件 - 呼叫
    var tapCallButton: (() -> Void)?
    /// 拒绝回复 label 点击展示全部理由
    var tapShowRefuseReply: (() -> Void)?

    // MARK: - Override
    override func loadSubViews() {
        super.loadSubViews()
        selectionStyle = .none
        leftStackView.insertArrangedSubview(checkBox, aboveArrangedSubview: avatarView)
        statusStack(add: [userStatusIcon, inviteFeedbackLabel])
        centerBotttomStatck(add: [interpretLabel, userFlagView, refuseLabel, roomLabel])
        rightStack(add: [callButton])
        addSubview(disableCover)
        disableCover.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func configure(with model: BaseParticipantCellModel) {
        let lastModel = cellModel
        cellModel = model
        constructUserInfo(lastModel)
        avatarView.showRedDot = model.showRedDot
        nameTailLabel.nameTail = model.nameTail
        guard let suggestModel = model as? SuggestionParticipantCellModel else { return }
        selectionStyle = suggestModel.selectionStyle
        checkBox.isHidden = !suggestModel.isMultiple
        checkBox.isSelected = suggestModel.isSelected
        checkBox.isEnabled = suggestModel.isEnabled
        inviteFeedbackLabel.feedback = suggestModel.inviteFeedback
        refuseLabel.refuseReply = suggestModel.refuseReply
        userFlagView.setMinWidth(suggestModel.hasRefuseReply ? 80 : nil)
        interpretLabel.interpret = suggestModel.interpret
        roomLabel.room = suggestModel.room
        disableCover.isHidden = suggestModel.isEnabled
        requestRelationTagIfNeeded()
        bindRefuseTapAction()
        SuggestionAnchorToast.shared.dismiss()
    }
}

// MARK: - Private
extension SuggestionParticipantCell {

    private func constructUserInfo(_ lastModel: BaseParticipantCellModel?) {
        if let suggestModel = cellModel as? SuggestionParticipantCellModel {
            if let lastModel = lastModel as? SuggestionParticipantCellModel,
                lastModel.participant.participantId == suggestModel.participant.participantId {
            } else {
                avatarView.avatarInfo = suggestModel.avatarInfo
                nameLabel.displayName = suggestModel.displayName
                userStatusIcon.setCustomStatuses(suggestModel.customStatuses)
                callButton.style = suggestModel.buttonStyle
            }
        }
        requestUserInfoIfNeeded()
    }

    private func requestUserInfoIfNeeded() {
        guard let suggestModel = cellModel as? SuggestionParticipantCellModel else { return }
        suggestModel.getDetailInfo { [weak self] in
            guard let currentModel = self?.cellModel as? SuggestionParticipantCellModel,
                  currentModel.participant.participantId == suggestModel.participant.participantId else { return } // 避免重用问题
            self?.avatarView.avatarInfo = suggestModel.avatarInfo
            self?.nameLabel.displayName = suggestModel.displayName
            self?.userStatusIcon.setCustomStatuses(suggestModel.customStatuses)
            self?.userFlagView.type = suggestModel.userFlag
            self?.callButton.style = suggestModel.buttonStyle
            self?.requestRelationTagIfNeeded()
            Logger.participant.debug("suggest cell get detail info, larkUid = \(suggestModel.participant.participantId.larkUserId), avatarInfo = \(suggestModel.avatarInfo)")
        }
    }

    func requestRelationTagIfNeeded() {
        guard let suggestModel = cellModel as? SuggestionParticipantCellModel else { return }
        if let flagType = UserFlagType.fromRelationTag(suggestModel.relationTag) {
            userFlagView.type = flagType
        } else {
            userFlagView.type = .none
        }
        suggestModel.getRelationTag { [weak self, weak suggestModel] userFlagType in
            Util.runInMainThread {
                guard let currentModel = self?.cellModel as? SuggestionParticipantCellModel,
                      currentModel.participant.participantId == suggestModel?.participant.participantId else { return } // 避免重用问题
                if let userFlagType = userFlagType {
                    self?.userFlagView.type = userFlagType
                } else {
                    self?.userFlagView.type = suggestModel?.userFlag ?? .none
                }
            }
        }
    }
}

extension SuggestionParticipantCell {
    private func bindRefuseTapAction() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleRefuseAction))
        refuseLabel.isUserInteractionEnabled = true
        refuseLabel.addGestureRecognizer(gesture)
    }

    @objc func handleRefuseAction() {
        throttleRefuse(())
    }

    func showFullRefuseReplyToast(_ at: UIView) {
        guard let suggestModel = cellModel as? SuggestionParticipantCellModel else { return }
        guard refuseLabel.partialDisplay, let refuseReply = suggestModel.refuseReply else {
            return
        }
        SuggestionAnchorToast.shared.show(refuseReply, bounds: contentView.bounds, of: refuseLabel, at: at)
    }
}

final class SuggestionAnchorToast {
    final class ToastContentView: UIView {
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            SuggestionAnchorToast.shared.dismiss()
        }
    }

    static let shared = SuggestionAnchorToast()
    private(set) var currentToast: AnchorToastView?
    private(set) var isShowing: Bool = false
    private(set) var contentView: ToastContentView?

    init() {}

    func show(_ content: String, bounds: CGRect, of referenceView: UIView, at: UIView) {
        contentView?.removeFromSuperview()
        currentToast?.removeFromSuperview()
        var currentContentView: ToastContentView
        if let contentView = contentView {
            currentContentView = contentView
            currentContentView.frame = at.bounds
        } else {
            currentContentView = ToastContentView(frame: at.bounds)
            contentView = currentContentView
        }
        currentContentView.isUserInteractionEnabled = true
        currentContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let toast = AnchorToastView(frame: bounds)
        toast.autoReverseVertical = true
        at.addSubview(toast)
        at.addSubview(currentContentView)
        toast.setStyle(content, on: .top, of: referenceView, distance: 0.0)
        currentToast = toast
        isShowing = true
    }

    func dismiss() {
        currentToast?.removeFromSuperview()
        contentView?.removeFromSuperview()
        isShowing = false
    }
}
