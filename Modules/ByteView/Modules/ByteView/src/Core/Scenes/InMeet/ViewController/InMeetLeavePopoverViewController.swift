//
// Created by maozhixiang.lip on 2022/8/31.
//

import Foundation
import RxSwift
import UniverseDesignCheckBox

class InMeetLeaveActionPopoverViewController: VMViewController<InMeetLeaveActionPopoverViewModel> {
    struct ActionButtonConfig {
        var titleText: String
        var fgColor: UIColor
        var bgColorNormal: UIColor
        var bgColorHighlight: UIColor
        var border: (color: UIColor, width: CGFloat)?

        var attributedTitle: NSAttributedString {
            .init(
                string: self.titleText,
                config: .body,
                alignment: .center,
                lineBreakMode: .byTruncatingTail,
                textColor: self.fgColor
            )
        }
    }

    private class ActionButton: UIButton {
        private let config: ActionButtonConfig
        private let action: () -> Void

        init(config: ActionButtonConfig, action: @escaping () -> Void) {
            self.config = config
            self.action = action
            super.init(frame: .zero)
            self.applyConfig(config)
            self.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func applyConfig(_ config: ActionButtonConfig) {
            self.contentEdgeInsets = .init(top: 7, left: 16, bottom: 7, right: 16)
            self.setAttributedTitle(config.attributedTitle, for: .normal)
            self.vc.setBackgroundColor(config.bgColorNormal, for: .normal)
            self.vc.setBackgroundColor(config.bgColorHighlight, for: .highlighted)
            self.vc.setBackgroundColor(.ud.fillDisabled, for: .disabled)
            self.layer.cornerRadius = 6
            self.clipsToBounds = true
            self.adjustsImageWhenHighlighted = false
            if let border = config.border {
                self.layer.borderWidth = border.width
                self.layer.ud.setBorderColor(border.color)
            }
        }

        @objc
        private func didTapButton() {
            self.action()
        }
    }

    private class PSTNView: UIView {

        private lazy var checkbox = UDCheckBox(boxType: .multiple) { [weak self] _ in
            self?.didTap()
        }

        private var label: UIView = {
            var label = UILabel()
            label.text = I18n.View_MV_StayConnectedByPhone
            label.textColor = UIColor.ud.textTitle
            label.font = .systemFont(ofSize: 16)
            label.adjustsFontSizeToFitWidth = true
            return label
        }()

        var onIsSelectedChange: ((Bool) -> Void)?

        init() {
            super.init(frame: .zero)
            self.addSubview(checkbox)
            self.addSubview(label)
            self.setupViews()
            self.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(didTap))
            )
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupViews() {
            checkbox.snp.makeConstraints { make in
                make.size.equalTo(20)
                make.left.top.bottom.equalToSuperview().inset(1)
            }
            label.snp.makeConstraints { make in
                make.left.equalTo(checkbox.snp.right).offset(8)
                make.right.top.bottom.equalToSuperview().inset(1)
            }
        }

        @objc
        private func didTap() {
            checkbox.isSelected.toggle()
            onIsSelectedChange?(checkbox.isSelected)
        }
    }

    private lazy var container: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        view.spacing = 20
        view.addArrangedSubview(self.actionButtonContainer)
        view.addArrangedSubview(self.pstnView)
        return view
    }()

    private lazy var actionButtonContainer: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        view.spacing = 16
        return view
    }()

    private lazy var pstnView = PSTNView()

    var contentSize: CGSize {
        self.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    override func setupViews() {
        super.setupViews()
        self.view.addSubview(container)
        self.container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(24)
        }
    }

    private let disposeBag = DisposeBag()
    override func bindViewModel() {
        super.bindViewModel()
        self.pstnView.isHidden = !self.viewModel.showPSTNView
        var endButton: UIButton?
        for (actionType, actionHandler) in self.viewModel.actions {
            let actionButton = ActionButton(config: actionType.buttonConfig, action: actionHandler)
            if actionType == .endMeeting { endButton = actionButton }
            self.actionButtonContainer.addArrangedSubview(actionButton)
        }
        self.pstnView.onIsSelectedChange = { [weak self] in
            self?.viewModel.holdPSTN = $0
            endButton?.isEnabled = !$0
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }
}

extension InMeetLeaveActionPopoverViewModel.ActionType {
    var buttonConfig: InMeetLeaveActionPopoverViewController.ActionButtonConfig {
        switch self {
        // 二次弹窗逻辑: 结束彩排将解散所有参会人，是否结束？，按钮：取消、确定；
        case .webinarRehearsalLeaveMeeting:
            return .init(
                titleText: I18n.View_G_LeaveRehearsal_Button,
                fgColor: UIColor.ud.functionDangerContentDefault,
                bgColorNormal: UIColor.ud.udtokenComponentOutlinedBg,
                bgColorHighlight: UIColor.ud.R100,
                border: (UIColor.ud.colorfulRed, 1))
        case .webinarRehearsalEndMeeting:
            return .init(
                titleText: I18n.View_G_EndRehearsalAll,
                fgColor: UIColor.ud.primaryOnPrimaryFill,
                bgColorNormal: UIColor.ud.functionDangerContentDefault,
                bgColorHighlight: UIColor.ud.functionDangerContentPressed)
        case .leaveMeeting:
            return .init(
                titleText: I18n.View_M_LeaveMeetingButton,
                fgColor: UIColor.ud.functionDangerContentDefault,
                bgColorNormal: UIColor.ud.udtokenComponentOutlinedBg,
                bgColorHighlight: UIColor.ud.R100,
                border: (UIColor.ud.colorfulRed, 1))
        case .endMeeting:
            return .init(
                titleText: I18n.View_M_EndMeetingForAll,
                fgColor: UIColor.ud.primaryOnPrimaryFill,
                bgColorNormal: UIColor.ud.functionDangerContentDefault,
                bgColorHighlight: UIColor.ud.functionDangerContentPressed)
        case .leaveBreakoutRoom:
            return .init(
                titleText: I18n.View_G_BackToMainRoom,
                fgColor: UIColor.ud.primaryOnPrimaryFill,
                bgColorNormal: UIColor.ud.primaryFillDefault,
                bgColorHighlight: UIColor.ud.primaryFillPressed)
        case .leaveMeetingFromBreakoutRoom:
            return .init(
                titleText: I18n.View_M_LeaveMeetingButton,
                fgColor: UIColor.ud.textTitle,
                bgColorNormal: UIColor.ud.udtokenComponentOutlinedBg,
                bgColorHighlight: UIColor.ud.udtokenTagNeutralBgNormalPressed,
                border: (UIColor.ud.lineBorderComponent, 1))
        case .leaveWithRoom:
            return .init(titleText: I18n.View_G_MeetingRoomLeaveToo_Button,
                         fgColor: UIColor.ud.functionDangerContentDefault,
                         bgColorNormal: UIColor.ud.udtokenComponentOutlinedBg,
                         bgColorHighlight: UIColor.ud.R100,
                         border: (UIColor.ud.colorfulRed, 1))
        }
    }
}
