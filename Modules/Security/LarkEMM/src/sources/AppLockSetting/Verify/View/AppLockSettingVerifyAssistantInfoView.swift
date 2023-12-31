//
//  AppLockSettingVerifyAssistantInfoView.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/11/9.
//

import Foundation
import UniverseDesignButton

class AppLockSettingVerifyAssistantInfoView: UIView {
    let viewModel: AppLockSettingVerifyAssistantInfoViewModel
    
    init(viewModel: AppLockSettingVerifyAssistantInfoViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        
        // 忘记密码
        forgetPINCodeButton.isHidden = viewModel.privacyModeEnable
        // 生物识别
        // 设置页开关关闭 || 用户关闭了飞书使用Face ID/Touch ID权限
        biometricButton.setTitle(viewModel.biometricButtonText, for: .normal)
        biometricButton.isHidden = viewModel.isBiometryHidden
        if viewModel.privacyModeEnable {
            biometricButton.setTitleColor(.clear, for: .highlighted)
            biometricButton.setTitleColor(.clear, for: .normal)
            biometricButton.setTitleColor(.clear, for: .selected)
            biometricButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 40, bottom: 0, right: 0)
        }
        setUp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 扩大 biometricButton 的热区，提升用户体验 
    // https://bytedance.larkoffice.com/wiki/Jp6FwzbI8ictAakSDwbc9QzJnCh?create_from=copy_within_wiki&renamingWikiNode=true
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if viewModel.privacyModeEnable, !biometricButton.isHidden {
            let btnPoint = convert(point, to: biometricButton)
            if biometricButton.point(inside: btnPoint, with: event) {
                return true
            }
        }
        return super.point(inside: point, with: event)
    }

    // MARK: Private
    private lazy var forgetPINCodeButton: UDButton = {
        let forgetButton = UDButton(UDButtonUIConifg(normalColor: .init(borderColor: .clear,
                                                                        backgroundColor: .clear,
                                                                                      textColor: UIColor.ud.textLinkNormal),
                                                                   type: .custom(from: .custom(from: .small,
                                                                                               size: CGSize(width: 0, height: 22),
                                                                                               inset: .zero))))
        forgetButton.setTitle(BundleI18n.AppLock.Lark_Lock_Link_ForgotPassword, for: .normal)
        forgetButton.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 13)
        forgetButton.titleLabel?.lineBreakMode = .byTruncatingTail
        forgetButton.addTarget(self, action: #selector(forgetPINCodeAction), for: .touchUpInside)
        return forgetButton
    }()
    
    private lazy var biometricButton: UDButton = {
        let biometricButton = UDButton(UDButtonUIConifg(normalColor: .init(borderColor: .clear,
                                                                           backgroundColor: .clear,
                                                                           textColor: UIColor.ud.textLinkNormal),
                                                        type: .custom(from: .custom(from: .small,
                                                                                    size: CGSize(width: 0, height: 22),
                                                                                    inset: .zero))))
        
        biometricButton.contentHorizontalAlignment = .trailing
        biometricButton.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 13)
        biometricButton.addTarget(self, action: #selector(biometricAction), for: .touchUpInside)
        return biometricButton
    }()
    
    private func setUp() {
        addSubview(forgetPINCodeButton)
        addSubview(biometricButton)
        forgetPINCodeButton.snp.makeConstraints {
            if biometricButton.isHidden {
                $0.top.centerX.bottom.equalToSuperview()
                $0.width.lessThanOrEqualToSuperview()
            } else {
                $0.top.left.bottom.equalToSuperview()
                $0.right.lessThanOrEqualTo(self.snp.centerX).offset(-6)
            }
        }
        biometricButton.snp.makeConstraints {
            $0.bottom.right.equalToSuperview()
            $0.left.greaterThanOrEqualTo(self.snp.centerX).offset(6)
        }
    }

    @objc
    private func forgetPINCodeAction(sender: UDButton) {
        self.viewModel.forgetPINCodeButtonAction?(sender)
    }
    
    @objc
    private func biometricAction(sender: UDButton) {
        self.viewModel.biometricButtonAction?(sender)
    }
}

struct AppLockSettingVerifyAssistantInfoViewModel {
    let privacyModeEnable: Bool
    let deviceBiometryType: AppLockSettingBiometryAuthType
    let isBiometryEnable: Bool
    let isBiometryShouldHidden: Bool
    let forgetPINCodeButtonAction: ((UDButton) -> Void)?
    let biometricButtonAction: ((UDButton) -> Void)?
    
    var biometricButtonText: String? {
        let type = deviceBiometryType
        switch type {
        case .faceID:
            return BundleI18n.AppLock.Lark_Screen_UseFaceIdUnlock
        case .touchID:
            return BundleI18n.AppLock.Lark_Screen_UseFingerprintUnlock
        default:
            return nil
        }
    }
    
    var isBiometryHidden: Bool {
        !isBiometryEnable || isBiometryShouldHidden
    }
}
