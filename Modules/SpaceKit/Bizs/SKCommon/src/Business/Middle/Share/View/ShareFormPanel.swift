//
//  ShareFormPanel.swift
//  SKCommon
//
//  Created by guoqp on 2021/7/18.
//

import Foundation
import SKResource
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor

class ShareBitablePanel: UIView {

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.shareOutlined.withRenderingMode(.alwaysTemplate)
        view.tintColor = UDColor.iconN1
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        return UILabel(frame: .zero).construct { (it) in
            it.font = UIFont.systemFont(ofSize: 16)
            it.textColor = UDColor.textTitle
            it.text = BundleI18n.SKResource.Bitable_Form_FormCollectionIsOff
            it.textAlignment = .left
        }
    }()
    
    private lazy var subTitleLabel: UILabel = {
        let view = UILabel()
        view.textColor = UDColor.textPlaceholder
        view.font = UIFont.systemFont(ofSize: 14)
        view.numberOfLines = 0
        view.isHidden = true
        return view
    }()

    private lazy var splitBottom: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private(set) lazy var accessSwitch: SKSwitch = {
        let sw = SKSwitch()
        sw.onTintColor = UDColor.primaryContentDefault
        return sw
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgFloat
        
        let labelStackView = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        labelStackView.axis = .vertical
        labelStackView.spacing = 4
        labelStackView.alignment = .leading
        labelStackView.distribution = .fill
        labelStackView.isUserInteractionEnabled = false
        
        addSubview(iconView)
        addSubview(labelStackView)
        addSubview(accessSwitch)
        addSubview(splitBottom)

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        labelStackView.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.top.bottom.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(28)
            make.right.lessThanOrEqualTo(accessSwitch.snp.left).offset(-12)
        }

        accessSwitch.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }

        splitBottom.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.left)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

extension ShareBitablePanel {
    func updateBy(_ formMeta: FormShareMeta) {
        let flag = formMeta.flag
        titleLabel.text = flag ? BundleI18n.SKResource.Bitable_Form_FormCollectionIsOn : BundleI18n.SKResource.Bitable_Form_FormCollectionIsOff
        accessSwitch.isOn = flag
    }
    func update(subType: BitableShareSubType, switchEnable: Bool) {
        let desc = subType.shareSwitchDesc(switchEnable)
        titleLabel.text = desc.title
        subTitleLabel.isHidden = desc.desc == nil
        subTitleLabel.text = desc.desc
        accessSwitch.isOn = switchEnable
    }
}

private extension BitableShareSubType {
    func shareSwitchDesc(_ isOn: Bool) -> (title: String, desc: String?) {
        switch self {
        case .form:
            if isOn {
                return (title: BundleI18n.SKResource.Bitable_Form_FormCollectionIsOn, desc: nil)
            }
            return (title: BundleI18n.SKResource.Bitable_Form_FormCollectionIsOff, desc: nil)
        case .view:
            if isOn {
                return (title: BundleI18n.SKResource.Bitable_Share_SharingTurnedOn_Button, desc: nil)
            }
            return (title: BundleI18n.SKResource.Bitable_Share_ShareView_Button, desc: nil)
        case .record:
            if isOn {
                return (title: BundleI18n.SKResource.Bitable_Share_SharingTurnedOn_Button, desc: BundleI18n.SKResource.Bitable_Share_WillShowAllFieldInSharingRecords_Description)
            }
            return (title: BundleI18n.SKResource.Bitable_Share_ShareRecord_Button, desc: BundleI18n.SKResource.Bitable_Share_CanAccessRecordIndependently_Description)
        case .dashboard_redirect, .dashboard:
            if isOn {
                return (title: BundleI18n.SKResource.Bitable_Share_SharingTurnedOn_Button, desc: nil)
            }
            return (title: BundleI18n.SKResource.Bitable_Share_ShareDashboard_Button, desc: nil)
        case .addRecord:
            if isOn {
                return (title: BundleI18n.SKResource.Bitable_Share_SharingTurnedOn_Button, desc: BundleI18n.SKResource.Bitable_Share_WillShowAllFieldInSharingRecords_Description)
            }
            return (title: BundleI18n.SKResource.Bitable_Share_ShareRecord_Button, desc: BundleI18n.SKResource.Bitable_Share_CanAccessRecordIndependently_Description)
        }
    }
}

/// 有人提交时是否通知视图
class FormsNotifyMeView: UIView {
    
    lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.announceOutlined.withRenderingMode(.alwaysTemplate)
        view.tintColor = UDColor.iconN1
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        view.textColor = UDColor.textTitle
        view.text = BundleI18n.SKResource.Bitable_NewSurvey_Share_SendNofi_Checkbox
        view.textAlignment = .left
        view.numberOfLines = 0
        return view
    }()
    
    lazy var accessSwitch: SKSwitch = {
        let sw = SKSwitch()
        sw.onTintColor = UDColor.primaryContentDefault
        return sw
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        backgroundColor = UDColor.bgFloat
        
        layer.cornerRadius = 10
        clipsToBounds = true
        
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        addSubview(accessSwitch)
        accessSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.width.greaterThanOrEqualTo(50)
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.top.bottom.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(28)
            make.right.equalTo(accessSwitch.snp.left).offset(-12)
        }
    }
}
