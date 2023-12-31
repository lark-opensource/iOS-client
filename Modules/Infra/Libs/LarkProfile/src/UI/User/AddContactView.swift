//
//  AddContactView.swift
//  LarkProfile
//
//  Created by Hayden Wang on 2021/7/16.
//

import Foundation
import UIKit
import UniverseDesignButton
import SnapKit
import LarkUIKit

/// 接受、已申请、添加好友视图
public final class AddContactView: UIView {

    public var tapHandler: ((ProfileRelationship) -> Void)?

    public var hideAddConnectButton: Bool = false // 是否显示添加按钮

    public var userDescription: String? {
        didSet {
            updateState()
        }
    }

    private var currentButtonState: ProfileRelationship = .none
    public var state: ProfileRelationship = .none {
        didSet {
            self.currentButtonState = state
            updateState()
        }
    }

    public var isBlocked: Bool = false {
        didSet {
            updateState()
        }
    }

    private var stackView: UIStackView = UIStackView()

    private lazy var blockLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = BundleI18n.LarkProfile.Lark_Server_SystemContent_BlockedTipInChat
        return label
    }()

    private lazy var applyButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .big
        let applyButton = UDButton(config)
        applyButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        applyButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .disabled)
        applyButton.addTarget(self, action: #selector(didTapAddContactButton), for: .touchUpInside)
        return applyButton
    }()

    private lazy var feishuLogoView: FeishuLogoView = {
        return FeishuLogoView()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        render()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        self.backgroundColor = Display.pad ? UIColor.ud.bgFloatBase : UIColor.ud.bgBase
        stackView.axis = .vertical
        stackView.spacing = Display.iPhoneXSeries ? 12 : 0
        stackView.distribution = .equalSpacing
        addSubview(stackView)

        if !Display.iPhoneXSeries {
            feishuLogoView.snp.makeConstraints {
                $0.height.equalTo(42)
            }
        }

        stackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(10)
            $0.top.equalToSuperview().offset(10)
        }
    }

    private func hideViewIfNeeded() {
        self.isHidden = blockLabel.isHidden && applyButton.isHidden && feishuLogoView.isHidden
    }

    fileprivate func updateBlockLabel() {
        blockLabel.isHidden = !isBlocked
    }

    fileprivate func updateApplyButton() {
        var title: String
        switch currentButtonState {
        case .none, .accepted:
            applyButton.isHidden = true
        case .accept:
            applyButton.isHidden = false
            applyButton.isUserInteractionEnabled = true
            title = BundleI18n.LarkProfile.Lark_NewContacts_AcceptContactRequestButton
            self.resetApplyButtonStatus()
            applyButton.setTitle(title, for: .normal)
        case .apply:
            if hideAddConnectButton {
                applyButton.isHidden = true
            } else {
                applyButton.isHidden = false
                applyButton.isUserInteractionEnabled = true
                title = BundleI18n.LarkProfile.Lark_Legacy_AddContactNow
                self.resetApplyButtonStatus()
                applyButton.setTitle(title, for: .normal)
            }
        case .applying:
            applyButton.isHidden = false
            title = BundleI18n.LarkProfile.Lark_NewContact_ContactRequestSentButton
            applyButton.setTitle(title, for: .disabled)
            applyButton.isUserInteractionEnabled = false
            applyButton.isEnabled = false
        }
    }

    fileprivate func updateFeishuLogoView() {
        if let desc = self.userDescription, !desc.isEmpty {
            feishuLogoView.isHidden = false
            feishuLogoView.text = desc
        } else {
            feishuLogoView.isHidden = true
        }

    }

    private func updateState() {
        updateApplyButton()
        updateBlockLabel()
        if self.isBlocked {
            applyButton.isHidden = true
        }
        updateFeishuLogoView()
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
            stackView.removeArrangedSubview($0)
        }
        if !feishuLogoView.isHidden {
            stackView.addArrangedSubview(feishuLogoView)
        }
        if !applyButton.isHidden {
            stackView.addArrangedSubview(applyButton)
        }
        if !blockLabel.isHidden {
            stackView.addArrangedSubview(blockLabel)
        }
        hideViewIfNeeded()
    }

    /// 防止按钮从verify 变化其他状态 不能点击的问题
    private func resetApplyButtonStatus() {
        applyButton.isUserInteractionEnabled = true
        applyButton.isEnabled = true
        applyButton.alpha = 1.0
    }

    @objc
    func didTapAddContactButton() {
        self.tapHandler?(self.state)
    }
}

public final class FeishuLogoView: UIView {

    private let label = UILabel()

    private let stackView = UIStackView()

    public var text: String? {
        didSet {
            self.label.text = text
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        render()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        render()
    }

    private func render() {
        stackView.distribution = .equalSpacing
        stackView.spacing = 2
        stackView.axis = .horizontal
        stackView.alignment = .center
        addSubview(stackView)

        stackView.addArrangedSubview(generateLine())
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(generateLine())
        label.textAlignment = .center
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)

        stackView.snp.makeConstraints {
            $0.top.bottom.centerX.equalToSuperview()
        }
    }

    private func generateLine() -> UIView {
        let view = UIView()
        view.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 6, height: 1))
        }
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }
}
