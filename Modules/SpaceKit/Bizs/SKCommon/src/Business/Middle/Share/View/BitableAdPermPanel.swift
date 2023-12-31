//
//  BitableAdPermPanel.swift
//  SKCommon
//
//  Created by zhysan on 2023/10/8.
//

import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont
import SKResource

class BitableAdPermPanel: UIControl {
    // MARK: - public
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                arrowView.isHidden = false
            } else {
                arrowView.isHidden = true
            }
        }
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
    
    // MARK: - private
    
    private let iconView: UIImageView = {
        let image = UDIcon.bitableAuthorizationOutlined.ud.withTintColor(UDColor.iconN1)
        let vi = UIImageView(image: image)
        return vi
    }()
    
    private let titleLabel: UILabel = {
        let vi = UILabel()
        vi.font = UDFont.body0
        vi.textColor = UDColor.textTitle
        vi.numberOfLines = 0
        vi.lineBreakMode = .byWordWrapping
        vi.text = BundleI18n.SKResource.Bitable_AdvancedPermissions_Mobile_TurnedOnAdvanced_Desc
        vi.setContentHuggingPriority(.required, for: .vertical)
        return vi
    }()
    
    private let detailLabel: UILabel = {
        let vi = UILabel()
        vi.font = UDFont.body2
        vi.textColor = UDColor.textCaption
        vi.numberOfLines = 0
        vi.lineBreakMode = .byWordWrapping
        vi.text = BundleI18n.SKResource.Bitable_AdvancedPermissions_Mobile_PermissionsSet_SubDesc
        vi.setContentHuggingPriority(.required, for: .vertical)
        return vi
    }()
    
    private let arrowView: UIImageView = {
        let image = UDIcon.rightOutlined.ud.withTintColor(UDColor.textPlaceholder)
        let vi = UIImageView(image: image)
        return vi
    }()
    
    private func subviewsInit() {
        backgroundColor = UDColor.bgFloat
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(arrowView)
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.top.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(22)
        }
        detailLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.height.greaterThanOrEqualTo(18)
            make.bottom.equalToSuperview().inset(12)
        }
        arrowView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.left.equalTo(titleLabel.snp.right).offset(12)
        }
    }
}
