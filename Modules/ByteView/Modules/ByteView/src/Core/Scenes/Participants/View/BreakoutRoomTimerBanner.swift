//
//  BreakoutRoomTimerBanner.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/3/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import UniverseDesignIcon

class BreakoutRoomTimerBanner: UIView {
    private var timeIcon: UIImageView = .init(image: nil)
    private var descLabel: UILabel = .init()
    private var askForHelpButton: UIButton!

    var askForHelpHandler: (() -> Void)?
    var askForHelpEnabled: Bool = false {
        didSet {
            if askForHelpEnabled {
                askForHelpButton.isHidden = false
                trailingToButton?.activate()
                trailingToEdge?.deactivate()
            } else {
                askForHelpButton.isHidden = true
                trailingToButton?.deactivate()
                trailingToEdge?.activate()
            }
        }
    }

    private var trailingToButton: Constraint?
    private var trailingToEdge: Constraint?

    private enum Layout {
        static let ContainerEdges: CGFloat = 16
        static let ContainerSpace: CGFloat = 8

        static let IconSize = CGSize(width: 16, height: 16)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        backgroundColor = UIColor.ud.functionSuccessFillSolid02

        let image = UDIcon.getIconByKey(.timeFilled, iconColor: .ud.functionSuccessContentDefault, size: Layout.IconSize)
        timeIcon = UIImageView(image: image)
        timeIcon.layer.masksToBounds = true
        timeIcon.layer.cornerRadius = Layout.IconSize.width / 2
        addSubview(timeIcon)
        timeIcon.snp.makeConstraints { (make) in
            make.top.equalTo(14)
            make.left.equalTo(Layout.ContainerEdges)
            make.size.equalTo(Layout.IconSize)
        }

        descLabel = UILabel()
        descLabel.attributedText = NSAttributedString(string: " ", config: .bodyAssist)
        descLabel.textColor = UIColor.ud.textTitle
        descLabel.numberOfLines = 0
        descLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        descLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addSubview(descLabel)

        askForHelpButton = UIButton(type: .custom)
        askForHelpButton.setTitle(I18n.View_G_AskForHelp, for: .normal)
        askForHelpButton.titleLabel?.font = .systemFont(ofSize: 14)
        askForHelpButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        askForHelpButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(askForHelpButton)
        askForHelpButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(Layout.ContainerEdges)
            make.centerY.equalToSuperview()
        }

        descLabel.snp.makeConstraints { (make) in
            make.left.equalTo(timeIcon.snp.right).offset(Layout.ContainerSpace)
            make.top.bottom.equalToSuperview().inset(12)

            trailingToButton = make.right.lessThanOrEqualTo(askForHelpButton.snp.left).offset(-Layout.ContainerSpace).constraint
            trailingToEdge = make.right.equalToSuperview().inset(Layout.ContainerEdges).constraint
        }

        trailingToButton?.activate()
        trailingToEdge?.deactivate()
    }

    func update(for state: State) {
        backgroundColor = state.backgroundColor
        let color = state.iconColor ?? .ud.primaryOnPrimaryFill
        timeIcon.image = UDIcon.getIconByKey(.timeFilled, iconColor: state.iconColor ?? .ud.primaryOnPrimaryFill, size: Layout.IconSize)
        if !state.showAskForHelp {
            askForHelpEnabled = false
        }
        switch state {
        case .joined(let duration):
            let labelText = "\(I18n.View_G_Duration) \(formatTime(duration: duration))"
            descLabel.attributedText = .init(string: labelText, config: .bodyAssist)
        case .countdown(let remainingTime):
            let timeStr = remainingTime > 0 ? formatTime(duration: remainingTime) : "00:00"
            descLabel.attributedText = .init(string: I18n.View_G_TimeRemaining_ShowTime(timeStr), config: .bodyAssist)
        case .leaving(_, let desc):
            descLabel.attributedText = NSAttributedString(string: desc, config: .bodyAssist)
        }
    }

    enum State {
        case joined(TimeInterval)
        case leaving(TimeInterval, String)
        case countdown(TimeInterval)

        var backgroundColor: UIColor? {
            switch self {
            case .joined, .countdown: return UIColor.ud.functionSuccessFillSolid02
            case .leaving: return UIColor.ud.functionWarningFillSolid02
            }
        }

        var iconColor: UIColor? {
            switch self {
            case .joined, .countdown: return UIColor.ud.functionSuccessContentDefault
            case .leaving: return UIColor.ud.functionWarningContentDefault
            }
        }

        var showAskForHelp: Bool {
            switch self {
            case .joined, .countdown: return true
            case .leaving: return false
            }
        }
    }

    private func formatTime(duration: TimeInterval) -> String {
        DateUtil.formatDuration(duration, concise: true)
    }

    @objc private func handleTap() {
        askForHelpHandler?()
    }
}
