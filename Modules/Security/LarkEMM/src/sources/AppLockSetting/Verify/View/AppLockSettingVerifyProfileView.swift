//
//  AppLockSettingVerifyProfileView.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/11/9.
//

import Foundation
import LarkAccountInterface
import UniverseDesignButton
import LarkBizAvatar
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import AvatarComponent
import ByteWebImage
import LarkSecurityComplianceInfra

class AppLockSettingVerifyProfileView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Internal
    func updateUIs(avatarKey: String, 
                   userName: String,
                   userID: String,
                   info: String) {
        let defaultIcon = UDIcon.getIconByKey(.memberFilled, iconColor: UDColor.rgb(0x336DF4), size: CGSize(width: 40, height: 40))
        userAvatar.setAvatarByIdentifier(userID,
                                         avatarKey: avatarKey,
                                         placeholder: defaultIcon,
                                         options: ImageRequestOptions(arrayLiteral: .setPlaceholderUntilFailure),
                                         completion: { [weak self] imageResult in
            switch imageResult {
            case .success(_):
                break
            case .failure(let error):
                self?.userAvatar.setAvatarUIConfig(AvatarComponentUIConfig(backgroundColor: UDColor.B100.alwaysLight,
                                                                           contentMode: .center))
                SCLogger.error("app lock setting get user avatar fail", additionalData: ["error": error.localizedDescription])
            }
        })
        userNameLabel.text = userName
        infoLabel.text = info
    }
    
    func updateTextAndShakeLabel(text: String?) {
        infoLabel.text = text
        shakeInfoLabel()
    }
    
    // MARK: Private
    private lazy var userAvatar: BizAvatar = {
        let userAvatar = BizAvatar()
        userAvatar.layer.cornerRadius = 40
        return userAvatar
    }()

    private lazy var userNameLabel: UILabel = {
        let userNameLabel = UILabel()
        userNameLabel.textAlignment = .center
        userNameLabel.textColor = UIColor.ud.textTitle
        userNameLabel.lineBreakMode = .byTruncatingTail
        userNameLabel.font = UDFont.title1
        return userNameLabel
    }()

    private lazy var infoLabelContainer = UIView()

    private lazy var infoLabel: UILabel = {
        let infoLabel = UILabel()
        
        infoLabel.numberOfLines = 2
        infoLabel.lineBreakMode = .byTruncatingTail
        infoLabel.textAlignment = .center
        infoLabel.textColor = UIColor.ud.textTitle
        infoLabel.font = UDFont.title4
        return infoLabel
    }()
    
    private func setUp() {
        addSubview(userAvatar)
        addSubview(userNameLabel)
        addSubview(infoLabelContainer)
        infoLabelContainer.addSubview(infoLabel)
        userAvatar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.size.equalTo(80)
            make.centerX.equalToSuperview()
        }
        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(userAvatar.snp.bottom).offset(8)
            make.height.equalTo(32)
            make.width.equalToSuperview().offset(-32)
            make.centerX.equalToSuperview()
        }
        infoLabelContainer.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(20)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().offset(-32)
            make.centerX.equalToSuperview()
        }
        infoLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }
    
    private func shakeInfoLabel() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.repeatCount = 2
        animation.duration = 0.05
        animation.autoreverses = true
        animation.values = [10, -10]
        infoLabel.layer.add(animation, forKey: "shake")
    }
}
