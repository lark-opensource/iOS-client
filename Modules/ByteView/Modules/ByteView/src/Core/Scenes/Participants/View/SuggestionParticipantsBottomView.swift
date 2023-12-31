//
//  SuggestionParticipantsBottomView.swift
//  ByteView
//
//  Created by wulv on 2022/5/17.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignCheckBox

/// 建议列表底部视图（多选、呼叫全部、已拒绝面板入口等）
class SuggestionParticipantsBottomView: UIView {

    /// 多选 + 呼叫全部
    private let normalToolView: UIView = {
        let v = UIView(frame: .zero)
        v.backgroundColor = UIColor.clear
        return v
    }()

    /// 多选
    let multipleButton: UIButton = {
        let b = UIButton(type: .custom)
        let img = UDIcon.getIconByKey(.multipleOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
        b.setImage(img, for: .normal)
        let dimg = UDIcon.getIconByKey(.multipleOutlined, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 20, height: 20))
        b.setImage(dimg, for: .disabled)
        b.vc.setBackgroundColor(.clear, for: .normal)
        b.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralPressed, for: .highlighted)
        b.layer.borderWidth = 1
        b.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        b.layer.cornerRadius = 10
        b.layer.masksToBounds = true
        return b
    }()

    /// 呼叫全部
    let inviteAllButton: UIButton = {
        let b = UIButton(type: .custom)
        b.vc.setBackgroundColor(.clear, for: .normal)
        b.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        b.layer.borderWidth = 1
        b.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        b.layer.cornerRadius = 10
        b.layer.masksToBounds = true
        return b
    }()

    /// `呼叫全部`内容容器视图
    let inviteAllSubStackView: UIStackView = {
       let s = UIStackView()
        s.axis = .horizontal
        s.spacing = Layout.loadingGapToTitle
        s.alignment = .center
        s.clipsToBounds = true
        s.isUserInteractionEnabled = false
        return s
    }()

    /// `呼叫全部`文字
    let inviteAllLabel: UILabel = {
        let l = UILabel()
        l.text = I18n.View_MV_CallAll_Button
        l.font = UIFont.systemFont(ofSize: 17)
        l.numberOfLines = 1
        l.clipsToBounds = true
        return l
    }()

    /// 蓝色圈圈
    let loadingView: LoadingView = {
        let l = LoadingView(frame: CGRect(x: 0, y: 0, width: Layout.loadingW, height: Layout.loadingW), style: .blue)
        l.clipsToBounds = true
        return l
    }()

    /// 全选 + 取消 + 呼叫
    private let multipleToolView: UIView = {
        let v = UIView(frame: .zero)
        v.backgroundColor = UIColor.clear
        return v
    }()

    /// 全选icon
    let selectIcon: UDCheckBox = UDCheckBox(boxType: .multiple)

    /// 全选文案
    let selectLabel: UILabel = {
        let l = UILabel(frame: .zero)
        l.backgroundColor = .clear
        l.textColor = UIColor.ud.textTitle
        l.font = UIFont.systemFont(ofSize: 17)
        l.text = I18n.View_MV_SelectAll_Button
        l.isUserInteractionEnabled = true
        return l
    }()

    /// 取消
    let cancelButton: UIButton = {
        let b = UIButton(type: .custom)
        b.vc.setBackgroundColor(.clear, for: .normal)
        b.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralPressed, for: .highlighted)
        b.layer.borderWidth = 1
        b.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        b.layer.cornerRadius = 10
        b.layer.masksToBounds = true
        b.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        b.setTitleColor(UIColor.ud.textTitle, for: .normal)
        b.setTitle(I18n.View_MV_CancelButtonTwo, for: .normal)
        return b
    }()

    /// 呼叫
    let inviteButton: UIButton = {
        let b = UIButton(type: .custom)
        b.vc.setBackgroundColor(UIColor.ud.fillDisabled, for: .disabled)
        b.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        b.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        b.layer.cornerRadius = 10
        b.layer.masksToBounds = true
        b.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        b.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        b.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        b.setTitle(I18n.View_MV_Call_AfterSelect, for: .normal)
        return b
    }()

    /// 日程会议拒绝文案 + 查看
    private let rejectView: UIView = {
        let v = UIView(frame: .zero)
        v.backgroundColor = UIColor.ud.bgFloatOverlay
        return v
    }()

    /// 拒绝文案 + 查看
    private let rejectStack: UIStackView = {
       let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 0
        return s
    }()

    /// 拒绝文案
    private let rejectLabel: UILabel = {
        let l = UILabel(frame: .zero)
        l.backgroundColor = .clear
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = UIColor.ud.textCaption
        return l
    }()

    /// 查看
    let scanButton: UIButton = {
        let b = UIButton(type: .custom)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        b.setTitle(I18n.View_MV_ViewDeclined, for: .normal)
        b.vc.setBackgroundColor(UIColor.clear, for: .normal)
        b.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgPriPressed, for: .highlighted)
        b.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        b.layer.cornerRadius = 6
        b.layer.masksToBounds = true
        return b
    }()

    private var calendarStyle: CalendarRejectStyle = .none
    private var hasRejectView: Bool = true
    private(set) var toolStyle: ToolStyle = .normal(true)

    convenience init(calendarStyle: CalendarRejectStyle = .none, hasRejectView: Bool, toolStyle: ToolStyle = .normal(true)) {
        self.init(frame: .zero)
        self.calendarStyle = calendarStyle
        self.toolStyle = toolStyle
        updateCalendarRejectStyle(calendarStyle)
        updateToolStyle(toolStyle)
        if !hasRejectView {
            self.hasRejectView = false
            rejectView.isHidden = true
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgFloat

        addSubview(normalToolView)
        normalToolView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
        }

        normalToolView.addSubview(multipleButton)
        multipleButton.snp.makeConstraints {
            $0.left.equalTo(safeAreaLayoutGuide).inset(16)
            $0.top.bottom.equalToSuperview().inset(Layout.toolVGap)
            $0.size.equalTo(CGSize(width: toolH, height: toolH))
        }

        normalToolView.addSubview(inviteAllButton)
        inviteAllButton.snp.makeConstraints {
            $0.left.equalTo(multipleButton.snp.right).offset(16)
            $0.height.equalTo(multipleButton)
            $0.centerY.equalToSuperview()
            $0.right.equalTo(safeAreaLayoutGuide).inset(16)
        }

        inviteAllButton.addSubview(inviteAllSubStackView)
        inviteAllSubStackView.snp.makeConstraints {
            $0.top.bottom.centerX.equalToSuperview()
        }

        inviteAllSubStackView.addArrangedSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 20, height: 20))
        }
        loadingView.isHiddenInStackView = true

        inviteAllSubStackView.addArrangedSubview(inviteAllLabel)

        addSubview(multipleToolView)
        multipleToolView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
        }

        multipleToolView.addSubview(selectIcon)
        selectIcon.snp.makeConstraints {
            $0.left.equalTo(safeAreaLayoutGuide).inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(CGSize(width: 20, height: 20))
        }

        multipleToolView.addSubview(selectLabel)
        selectLabel.snp.makeConstraints {
            $0.left.equalTo(selectIcon.snp.right).offset(12)
            $0.centerY.equalToSuperview()
        }

        inviteButton.isEnabled = false
        multipleToolView.addSubview(inviteButton)
        inviteButton.snp.makeConstraints {
            $0.right.equalTo(safeAreaLayoutGuide).inset(16)
            $0.top.bottom.equalToSuperview().inset(Layout.toolVGap)
            $0.height.equalTo(toolH)
            $0.width.greaterThanOrEqualTo(104)
        }

        multipleToolView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.right.equalTo(inviteButton.snp.left).offset(-10)
            $0.height.equalTo(inviteButton)
            $0.centerY.equalToSuperview()
            $0.width.greaterThanOrEqualTo(104)
        }

        rejectStack.addArrangedSubview(rejectLabel)
        rejectStack.addArrangedSubview(scanButton)

        rejectView.addSubview(rejectStack)
        rejectStack.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.height.equalTo(Layout.rejectH)
            $0.centerX.equalToSuperview()
        }

        addSubview(rejectView)
        rejectView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(Layout.toolVGap + toolH + Layout.toolVGap)
        }

        updateCalendarRejectStyle(calendarStyle, force: true)
        updateToolStyle(toolStyle, force: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SuggestionParticipantsBottomView {

    enum ToolStyle: Equatable {
        /// 多选、呼叫全部
        case normal(Bool)
        /// 全选、取消、呼叫
        case multiple
    }

    func updateToolStyle(_ style: ToolStyle, force: Bool = false) {
        if !force, style == toolStyle { return }

        toolStyle = style
        switch style {
        case .normal(let enabled):
            normalToolView.isHidden = false
            multipleToolView.isHidden = true
            updateInviteAllEnabled(enabled)
        case .multiple:
            normalToolView.isHidden = true
            multipleToolView.isHidden = false
        }
    }

    func updateInviteAllEnabled(_ enabled: Bool) {
        multipleButton.isEnabled = enabled
        inviteAllButton.isEnabled = enabled
        inviteAllLabel.textColor = enabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled
    }

    func updateInviteAllButton(loading: Bool) {
        inviteAllLabel.text = loading ? I18n.View_G_CallingEllipsis : I18n.View_MV_CallAll_Button
        loadingView.isHiddenInStackView = !loading
        if loading {
            loadingView.play()
        } else {
            loadingView.stop()
        }
    }

    func updateMultipleTool(iconType: ParticipantsViewModel.SuggestionSelectType, inviteCount: Int) {
        updateSelectIconType(iconType)

        if inviteCount > 0 {
            inviteButton.setTitle(I18n.View_MV_CallWhatNumber(inviteCount), for: .normal)
            inviteButton.isEnabled = true
        } else {
            inviteButton.setTitle(I18n.View_MV_Call_AfterSelect, for: .normal)
            inviteButton.isEnabled = false
        }
    }

    private func updateSelectIconType(_ type: ParticipantsViewModel.SuggestionSelectType) {
        switch type {
        case .none:
            selectIcon.isSelected = false
        case .part:
            selectIcon.updateUIConfig(boxType: .mixed, config: selectIcon.config)
            selectIcon.isSelected = true
        case .all:
            selectIcon.updateUIConfig(boxType: .multiple, config: selectIcon.config)
            selectIcon.isSelected = true
        }
    }
}

extension SuggestionParticipantsBottomView {

    enum CalendarRejectStyle: Equatable {
        /// 没有人拒绝日程
        case none
        /// 暂无拒绝日程人员
        case notAvailable
        /// x人拒绝了日程
        case reject(Int)
    }

    func updateCalendarRejectStyle(_ style: CalendarRejectStyle, force: Bool = false) {
        if !force, style == calendarStyle { return }

        calendarStyle = style
        switch style {
        case .none:
            rejectLabel.text = I18n.View_MV_NoDeclineWow
            scanButton.isHidden = true
        case .notAvailable:
            rejectLabel.text = I18n.View_MV_NoDeclineYet
            scanButton.isHidden = true
        case .reject(let count):
            rejectLabel.text = I18n.View_MV_SomeHadDeclined(count)
            scanButton.isHidden = false
        }
    }

    func updateLayoutWhenOrientationDidChange() {
        multipleButton.snp.updateConstraints {
            $0.size.equalTo(CGSize(width: toolH, height: toolH))
        }

        inviteButton.snp.updateConstraints {
            $0.height.equalTo(toolH)
        }

        rejectView.snp.updateConstraints {
            $0.top.equalTo(Layout.toolVGap + toolH + Layout.toolVGap)
        }
    }
}

extension SuggestionParticipantsBottomView {

    struct Layout {
        static let toolVGap: CGFloat = 8
        static let rejectH: CGFloat = 36
        static let loadingW: CGFloat = 20
        static let loadingGapToTitle: CGFloat = 4
    }

    var toolH: CGFloat { isPhoneLandscape ? 44.0 : 48.0 }

    var minHeight: CGFloat {
        if hasRejectView {
            return Layout.toolVGap * 2 + toolH + Layout.rejectH
        } else {
            return Layout.toolVGap * 2 + toolH
        }
    }
}
