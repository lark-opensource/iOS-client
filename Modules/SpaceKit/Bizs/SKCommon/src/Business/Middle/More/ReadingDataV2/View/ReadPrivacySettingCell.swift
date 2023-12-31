//
//  ReadPrivacySettingCell.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/27.
//  


import UIKit
import SKResource
import UniverseDesignColor

class ReadPrivacySettingCell: UITableViewCell {
    
    enum Event {
        case `switch`(Bool)
        case more
    }
    
    static let reuseIdentifier = "ReadPrivacySettingCell"
    public var eventHandler: ((Event) -> Void)?

    private lazy var switchContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.LarkCCM_Docs_ViewHistory_Menu_Mob
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var switchButton: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = UIColor.ud.colorfulBlue
        sw.addTarget(self, action: #selector(didSwitchChanged(sender:)), for: .valueChanged)
        return sw
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.CreationMobile_Stats_Visits_DisableDesc
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .left
        label.textColor = UDColor.textCaption
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var moreButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.SKResource.CreationDoc_Stats_Visits_desc_more, for: .normal)
        btn.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        return btn
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubview(switchContainer)
        contentView.addSubview(tipLabel)
        switchContainer.addSubview(switchLabel)
        switchContainer.addSubview(switchButton)
        contentView.addSubview(moreButton)
        
        moreButton.addTarget(self, action: #selector(moreAction), for: .touchUpInside)
    }
    
    private func setupConstraints() {

        switchContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.height.equalTo(44)
        }

        tipLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(29)
            make.trailing.equalToSuperview().offset(-29)
            make.top.equalTo(switchContainer.snp.bottom).offset(8)
        }
        
        moreButton.snp.makeConstraints { make in
            make.leading.equalTo(tipLabel.snp.leading)
            make.top.equalTo(tipLabel.snp.bottom).offset(4)
            make.height.equalTo(24)
            make.bottom.equalToSuperview().offset(-10)
        }

        switchLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(switchButton.snp.leading).offset(-5)
        }

        switchButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-1)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(28)
            make.width.equalTo(48)
        }
    }

    @objc
    private func didSwitchChanged(sender: UISwitch) {
        eventHandler?(.switch(sender.isOn))
    }
    
    @objc
    private func moreAction() {
        eventHandler?(.more)
    }

    public func updateState(title: String, detail: String, isOn: Bool) {
        switchLabel.text = title
        tipLabel.text = detail
        if switchButton.isOn != isOn {
            switchButton.isOn = isOn
        }
    }
}
