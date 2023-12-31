//
//  BaseParticipantCell.swift
//  ByteView
//
//  Created by wulv on 2022/1/26.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import UIKit

enum ParticipantStatusPriority: Float {
    // 压缩顺序: 子标题、译员、主持人、外部、焦点视频、申请发言
    // https://www.figma.com/file/NGWAVHQH5vpVJ6TZcm4ULH/%F0%9F%93%B1-Mob---7.0?type=design&node-id=131-11291&t=MMeiD4d6aRgJd8ZP-0
    case subtitle = 100
    case interpretation = 200
    case hostTag = 300
    case externalTag = 400
    case focusVideo = 500
    case askToSpeak = 600

    var priority: UILayoutPriority {
        UILayoutPriority(self.rawValue)
    }
}

let participantsBgColor: UIColor = .clear//.ud.bgFloat
let participantsHightlightColor: UIColor = .ud.fillHover

/// 参会人cell基类，数字表示间隙:
/// |--------------------------------------------------------------|
/// |-----------------昵称-0-小尾巴-4-StatusStackView---------------｜
/// |-16-头像(红点)-12-                              ---------------｜
/// |-----------------CenterBotttomStatckView      ----------------|
/// |--------------------------------------------------------------|
class BaseParticipantCell: StackViewCell<BaseParticipantCellModel> {

    var hitPoint: CGPoint?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 收到的point可能在cell之外
        if self.bounds.contains(point) {
            self.hitPoint = point
        }
        return super.hitTest(point, with: event)
    }

    // MARK: - Common SubViews
    /// 头像(含红点)
    lazy var avatarView = ParticipantAvatarView(isHidden: false)
    /// 头像点击事件
    var tapAvatarAction: (() -> Void)? {
        didSet {
            avatarView.tapAction = tapAvatarAction
        }
    }
    /// 昵称
    lazy var nameLabel = ParticipantNameLabel(isHidden: false)
    /// 小尾巴，展示(me、访客等)文案
    lazy var nameTailLabel = ParticipantNameTailLabel(isHidden: false)
    // MARK: - Stack View
    /// 昵称stackView - 昵称+小尾巴等
    lazy var nameStackView = HStackView(spacing: 0)
    /// 状态stackView - 设备标识+共享标识+个人状态+勿扰+焦点视频等
    lazy var statusStackView = HStackView(spacing: 4)
    /// 中上部stackView - 昵称stackView+状态stackView
    lazy var centerTopStatckView = HStackView(spacing: 4)
    /// 中下部 Stack View - 会议室地点+主持人标签+外部标签+传译语言+申请发言等
    lazy var centerBotttomStatckView = HStackView(spacing: 4)

    // MARK: - Override
    override func loadSubViews() {
        super.loadSubViews()
        contentView.backgroundColor = participantsBgColor
        backgroundColor = participantsBgColor
        setSelectedBackgroundColor(participantsHightlightColor)
        leftStack(add: [avatarView])
        nameStack(add: [nameLabel, nameTailLabel])
        centerTopStatck(add: [nameStackView, statusStackView])
        centerStack(add: [centerTopStatckView, centerBotttomStatckView])
    }

    override func configure(with model: BaseParticipantCellModel) {
        super.configure(with: model)
        avatarView.avatarInfo = model.avatarInfo
        avatarView.showRedDot = model.showRedDot
        nameLabel.displayName = model.displayName
        nameTailLabel.nameTail = model.nameTail
    }

    // MARK: - Public
    func setSelectedBackgroundColor(_ color: UIColor) {
        let selectedBackgroundView = UIView()
        let subView = UIView()
        subView.layer.cornerRadius = 6
        subView.layer.masksToBounds = true
        subView.backgroundColor = color
        selectedBackgroundView.addSubview(subView)
        subView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(6)
        }
        self.selectedBackgroundView = selectedBackgroundView
    }
}

// MARK: - Private
extension BaseParticipantCell {

    func nameStack(add subViews: [UIView]) {
        addSubviewsTo(statck: nameStackView, subViews: subViews)
    }

    func statusStack(add subViews: [UIView]) {
        addSubviewsTo(statck: statusStackView, subViews: subViews)
    }

    func centerTopStatck(add subViews: [UIView]) {
        addSubviewsTo(statck: centerTopStatckView, subViews: subViews)
    }

    func centerBotttomStatck(add subViews: [UIView]) {
        addSubviewsTo(statck: centerBotttomStatckView, subViews: subViews)
    }
}
