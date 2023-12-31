//
//  BitableAdPermSwitchHeader.swift
//  SKCommon
//
//  Created by zhysan on 2022/7/18.
//

import UIKit
import SnapKit
import SKResource
import UniverseDesignColor
import UniverseDesignSwitch
import UniverseDesignFont

class BitableAdPermSwitchHeader: UIView {
    
    let showSwitch: Bool
    
    let permSwitchTitleLabel: UILabel = {
        let vi = UILabel()
        vi.textColor = UIColor.ud.textTitle
        vi.font = UIFont.ud.headline
        vi.numberOfLines = 0
        vi.lineBreakMode = .byWordWrapping
        return vi
    }()
    
    let permSwitch: UDSwitch = {
        let vi = UDSwitch()
        vi.behaviourType = .waitCallback
        return vi
    }()
    
    private let permSwitchDetailLabel: UILabel = {
        UILabel()
    }()
    
    init(showSwitch: Bool, initialSwitchState: Bool, frame: CGRect = .zero) {
        self.showSwitch = showSwitch
        super.init(frame: frame)
        subviewsInit(initialSwitchState)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func subviewsInit(_ initialSwitchState: Bool) {
        addSubview(permSwitchTitleLabel)
        addSubview(permSwitch)
        addSubview(permSwitchDetailLabel)
        
        permSwitchTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        if showSwitch {
            permSwitchTitleLabel.text = BundleI18n.SKResource.Bitable_AdvancedPermission_RolesAndPermissionsTitle
            permSwitchDetailLabel.sk_setText(BundleI18n.SKResource.Bitable_AdvancedPermission_RolesAndPermissionsDesc)
        } else {
            permSwitchTitleLabel.text = BundleI18n.SKResource.Bitable_AdvancedPermission_CustomRoleTitleInTemplate
            permSwitchDetailLabel.sk_setText(BundleI18n.SKResource.Bitable_AdvancedPermission_TemplateDesc)
        }
        
        permSwitch.setOn(initialSwitchState, animated: false)
        
        permSwitchTitleLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
        }
        if showSwitch {
            permSwitch.isHidden = false
            permSwitch.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.left.equalTo(permSwitchTitleLabel.snp.right).offset(8)
                make.right.lessThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualTo(permSwitchTitleLabel)
            }
        } else {
            permSwitch.isHidden = true
            permSwitchTitleLabel.snp.makeConstraints { make in
                make.right.equalToSuperview()
            }
        }
        
        permSwitchDetailLabel.snp.makeConstraints { make in
            make.top.equalTo(permSwitchTitleLabel.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }
}
