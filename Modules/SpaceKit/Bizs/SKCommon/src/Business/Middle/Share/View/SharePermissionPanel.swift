//
//  SharePermissionPanel.swift
//  SpaceKit
//
//  Created by 杨子曦 on 2020/2/24.
//  


import UIKit
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

protocol SharePermissionDelegate: AnyObject {
    func didOpenPermission(panel: SharePermissionPanel)
}

class SharePermissionPanel: UIControl {
    weak var delegate: SharePermissionDelegate?

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UDIcon.settingOutlined.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UDColor.iconN1
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let n = UILabel()
        n.textColor = UDColor.textTitle
        n.font = UIFont.systemFont(ofSize: 16)
        n.text = BundleI18n.SKResource.LarkCCM_Docs_PermissionSettings_Menu_Mob
        return n
    }()

    lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)
        view.tintColor = UDColor.textPlaceholder
        return view
    }()
    
    private lazy var spLine: UIView = {
        let vi = UIView()
        vi.backgroundColor = UDColor.lineDividerDefault
        vi.isUserInteractionEnabled = false
        return vi
    }()
    
    func showBottomSeperatorLine(_ show: Bool) {
        spLine.isHidden = !show
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UDColor.fillPressed
            } else {
                backgroundColor = UDColor.bgFloat
            }
        }
    }

    var isSettingsEnabled: Bool = false {
        didSet {
            if isSettingsEnabled {
                titleLabel.textColor = UDColor.textTitle
                iconImageView.tintColor = UDColor.iconN1
                arrowImageView.tintColor = UDColor.textPlaceholder
            } else {
                titleLabel.textColor = UDColor.textDisabled
                iconImageView.tintColor = UDColor.iconDisabled
                arrowImageView.tintColor = UDColor.iconDisabled
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTapGesture()
        _setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addTapGesture()
        _setupUI()
    }

    private func _setupUI() {
        backgroundColor = UDColor.bgFloat

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(arrowImageView)

        iconImageView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview().inset(16)
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(arrowImageView.snp.left).offset(-12)
        }

        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(12)
            make.height.width.equalTo(20)
        }
        
        if UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance {
            addSubview(spLine)
            spLine.isHidden = true
            spLine.snp.makeConstraints { make in
                make.bottom.right.equalToSuperview()
                make.height.equalTo(0.5)
                make.left.equalToSuperview().inset(16)
            }
        }
    }

    private func addTapGesture() {
        addTarget(self, action: #selector(didReceiveTap), for: .touchUpInside)
    }

    @objc
    private func didReceiveTap() {
        delegate?.didOpenPermission(panel: self)
    }
}
