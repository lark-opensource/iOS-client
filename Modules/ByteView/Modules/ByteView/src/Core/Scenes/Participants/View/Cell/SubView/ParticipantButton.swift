//
//  ParticipantButton.swift
//  ByteView
//
//  Created by wulv on 2022/3/2.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon

/// 设备标识(手机/pstn/web等)
class ParticipantButton: VisualButton {

    enum Style {
        case none
        case calling
        case joined
        case waiting
        case blocked
        case moreCall
        case call
        case phoneCall
        case admit
        case remove
        case joining
        case convertPstn
        case cancel
        case join
        case leave
    }

    var style: ParticipantButton.Style = .none {
        didSet {
            if oldValue != style {
                update(style: style)
            }
        }
    }

    private enum Layout {
        static let left: CGFloat = 8
        static let right: CGFloat = 8
        static let fontSize: CGFloat = 14.0
    }

    private var minW: CGFloat = 0
    convenience init(style: ParticipantButton.Style, minWidth: CGFloat = 60, height: CGFloat = 28) {
        self.init(type: .custom)
        self.minW = minWidth
        layer.borderWidth = 1
        layer.cornerRadius = 6
        titleLabel?.font = UIFont.systemFont(ofSize: Layout.fontSize, weight: .regular)
        snp.remakeConstraints { make in
            make.width.equalTo(minWidth)
            make.height.equalTo(height)
        }
        update(style: .none)
        self.style = style
    }
}

// MARK: - Private
extension ParticipantButton {
    private func update(style: ParticipantButton.Style) {
        self.resetStyle()
        switch style {
        case .none:
            noneStyle()
        case .calling:
            callingStyle()
        case .joined:
            joinedStyle()
        case .waiting:
            waitingStyle()
        case .blocked:
            blockedStyle()
        case .moreCall:
            moreCallStyle()
        case .call:
            callStyle()
        case .phoneCall:
            phoneCallStyle()
        case .admit:
            admitStyle()
        case .remove:
            removeStyle()
        case .joining:
            joiningStyle()
        case .convertPstn:
            pstnStyle()
        case .cancel:
            cancelStyle()
        case .join:
            joinStyle()
        case .leave:
            leaveStyle()
        }
        isHidden = style == .none
    }
}

extension ParticipantButton {

    func resetStyle() {
        contentEdgeInsets = UIEdgeInsets(top: 5, left: Layout.left, bottom: 5, right: Layout.right)
        imageEdgeInsets = .zero
        titleEdgeInsets = .zero
        setImage(nil, for: .normal)
        setImage(nil, for: .highlighted)
        setImage(nil, for: .disabled)
        titleLabel?.backgroundColor = participantsBgColor
        setTitleColor(UIColor.ud.textTitle, for: .normal)
        setTitleColor(UIColor.ud.textTitle, for: .highlighted)
        setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        setBGColor(UIColor.clear, for: .normal)
        setBGColor(UIColor.clear, for: .highlighted)
        setBGColor(UIColor.clear, for: .disabled)
        setBorderColor(UIColor.clear, for: .normal)
        setBorderColor(UIColor.clear, for: .highlighted)
        setBorderColor(UIColor.clear, for: .disabled)
        isHighlighted = false
        isUserInteractionEnabled = false
    }

    private func addBorder(_ color: UIColor = .ud.lineBorderComponent) {
        setBorderColor(color, for: .normal)
        setBorderColor(color, for: .highlighted)
    }

    private func updateWidth() {
        let labelString = NSString(string: titleLabel?.text ?? "")
        let titleSize = labelString.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: Layout.fontSize)])
        let w = Layout.left + ceil(titleSize.width) + Layout.right
        if w > minW {
            snp.updateConstraints { make in
                make.width.equalTo(w)
            }
        }
    }

    /// 已加入
    func joinedStyle() {
        setTitle(I18n.View_M_JoinedButton, for: .normal)
        setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        setTitleColor(UIColor.ud.textPlaceholder, for: .highlighted)
        updateWidth()
    }

    /// 呼叫
    func callStyle() {
        setTitle(I18n.View_VM_CallButton, for: .normal)
        setBGColor(UIColor.ud.N200, for: .highlighted)
        addBorder()
        updateWidth()
        isUserInteractionEnabled = true
    }

    /// 电话呼叫
    func phoneCallStyle() {
        setTitle(I18n.View_G_PhoneCall_HoverChoice, for: .normal)
        setBGColor(UIColor.ud.N200, for: .highlighted)
        addBorder()
        updateWidth()
        isUserInteractionEnabled = true
    }

    /// 禁止呼叫
    func blockedStyle() {
        setTitle(I18n.View_VM_CallButton, for: .normal)
        setTitleColor(UIColor.ud.N400, for: .normal)
        setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        updateWidth()
        isUserInteractionEnabled = true
    }

    /// 更多呼叫
    func moreCallStyle() {
        let left: CGFloat = 12
        contentEdgeInsets = UIEdgeInsets(top: 5, left: left, bottom: 5, right: Layout.right)
        let title = I18n.View_VM_CallButton
        let labelString = NSString(string: title)
        let titleSize = labelString.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: Layout.fontSize)])
        let imageToTitle: CGFloat = 4.0
        let imageWidth: CGFloat = 8.0
        titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth - imageToTitle / 2,
            bottom: 0, right: imageWidth + imageToTitle / 2)
        setTitle(title, for: .normal)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: titleSize.width + imageToTitle / 2,
            bottom: 0, right: -titleSize.width - imageToTitle / 2)
        let image = ParticipantImageView.ExpandDownImgN1
        setImage(image, for: .normal)
        setImage(image, for: .highlighted)
        setImage(image, for: .disabled)
        addBorder()
        setBGColor(UIColor.ud.N200, for: .highlighted)
        isUserInteractionEnabled = true
        let w = left + ceil(titleSize.width) + imageToTitle + imageWidth + Layout.right
        if w > minW {
            snp.updateConstraints { make in
                make.width.equalTo(w)
            }
        }
    }

    /// 呼叫中
    func callingStyle() {
        setTitle(I18n.View_G_CallingEllipsis, for: .normal)
        setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        setTitleColor(UIColor.ud.textPlaceholder, for: .highlighted)
        updateWidth()
    }

    /// 等候中
    func waitingStyle() {
        setTitle(I18n.View_M_WaitingEllipsis, for: .normal)
        setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        setTitleColor(UIColor.ud.textPlaceholder, for: .highlighted)
        updateWidth()
    }

    /// 取消
    func cancelStyle() {
        setTitle(I18n.View_G_CancelButton, for: .normal)
        addBorder()
        setBGColor(UIColor.ud.N200, for: .highlighted)
        updateWidth()
        isUserInteractionEnabled = true
    }

    /// 转为电话呼叫
    func pstnStyle() {
        setTitle(I18n.View_G_ConvertToPhoneCall_Button, for: .normal)
        addBorder()
        setBGColor(UIColor.ud.N200, for: .highlighted)
        updateWidth()
        isUserInteractionEnabled = true
    }

    /// 移出
    func removeStyle() {
        setTitle(I18n.View_M_RemoveButton, for: .normal)
        addBorder()
        setBGColor(UIColor.ud.N200, for: .highlighted)
        updateWidth()
        isUserInteractionEnabled = true
    }

    /// 准入
    func admitStyle() {
        setTitle(I18n.View_M_AdmitButton, for: .normal)
        addBorder()
        setBGColor(UIColor.ud.N200, for: .highlighted)
        updateWidth()
        isUserInteractionEnabled = true
    }

    /// 正在加入
    func joiningStyle() {
        setTitle(I18n.View_M_JoiningEllipsis, for: .normal)
        setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        setTitleColor(UIColor.ud.textPlaceholder, for: .highlighted)
        setTitleColor(UIColor.ud.textPlaceholder, for: .disabled)
        updateWidth()
    }

    /// 加入
    func joinStyle() {
        setTitle(I18n.View_MV_JoinRightNow, for: .normal)
        setBGColor(.ud.udtokenComponentOutlinedBg, for: .normal)
        setBGColor(.ud.udtokenBtnSeBgNeutralPressed, for: .highlighted)
        addBorder()
        updateWidth()
        isUserInteractionEnabled = true
    }

    /// 离开
    func leaveStyle() {
        setTitle(I18n.View_VM_LeaveButton, for: .normal)
        setTitleColor(.ud.functionDangerContentDefault, for: .normal)
        setTitleColor(.ud.functionDangerContentDefault, for: .highlighted)
        setBGColor(.ud.udtokenComponentOutlinedBg, for: .normal)
        setBGColor(.ud.udtokenBtnSeBgDangerHover, for: .highlighted)
        addBorder(.ud.functionDangerContentDefault)
        updateWidth()
        isUserInteractionEnabled = true
    }

    /// 初始空白样式
    func noneStyle() {
        contentEdgeInsets = .zero
        setTitle(nil, for: .normal)
        titleLabel?.backgroundColor = .clear
        updateWidth()
    }

}
