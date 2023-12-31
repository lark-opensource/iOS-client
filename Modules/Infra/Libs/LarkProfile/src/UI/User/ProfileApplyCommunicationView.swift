//
//  ProfileApplyContact.swift
//  LarkProfile
//
//  Created by ByteDance on 2023/2/13.
//

import UIKit
import UniverseDesignButton
import SnapKit
import LarkUIKit

// 申请沟通权限
class ProfileApplyCommunicationView: UIView {

    public var tapHandler: ((ProfileCommunicationPermission) -> Void)?
    
    private var currentButtonState: ProfileCommunicationPermission = .unown
    public var state: ProfileCommunicationPermission = .unown {
        didSet {
            self.currentButtonState = state
            updateState()
        }
    }

    private lazy var applyButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .big
        let applyButton = UDButton(config)
        applyButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        applyButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .disabled)
        applyButton.setTitle(BundleI18n.LarkProfile.Lark_IM_SendMessageRequest_Button, for: .normal)
        applyButton.setTitle(BundleI18n.LarkProfile.Lark_IM_MessageRequestSent_Button, for: .disabled)
        applyButton.addTarget(self, action: #selector(didTapApplyCommunicationButton), for: .touchUpInside)
        return applyButton
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubView() {
        addSubview(applyButton)
        applyButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(10)
            make.top.equalToSuperview().offset(10)
        }
    }
    
    private func hideViewIfNeeded() {
        self.isHidden = applyButton.isHidden
    }

    private func updateState() {
        updateApplyButton()
        hideViewIfNeeded()
    }
    
    private func updateApplyButton() {
        switch currentButtonState {
        case .unown, .agreed, .inelligible:
            applyButton.isHidden = true
        case .apply, .applied:
            applyButton.isHidden = false
            resetApplyButtonStatus()
        case .applying:
            applyButton.isHidden = false
            applyButton.isUserInteractionEnabled = false
            applyButton.isEnabled = false
        }
    }
    
    @objc
    private func didTapApplyCommunicationButton() {
        self.tapHandler?(self.state)
    }
    
    private func resetApplyButtonStatus() {
        applyButton.isUserInteractionEnabled = true
        applyButton.isEnabled = true
        applyButton.alpha = 1.0
    }
}
