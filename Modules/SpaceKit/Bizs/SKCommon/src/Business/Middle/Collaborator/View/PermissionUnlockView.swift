//
//  PermissionUnlockView.swift
//  SKCommon
//
//  Created by CJ on 2021/3/26.
//

import Foundation
import SKResource
import UniverseDesignColor

public final class PermissionUnlockView: UIView {
    public var contentHeight: CGFloat {
        guard let text = titleLabel.text else {
            return 0
        }
        var constrainedWidth: CGFloat
        if recoverButton.isHidden {
            constrainedWidth = self.frame.size.width - 44 - 18
        } else {
            constrainedWidth = self.frame.size.width - 44 - 28 - recoverButton.frame.size.width
        }
        let constrainedSize = CGSize(width: constrainedWidth, height: CGFloat.greatestFiniteMagnitude)
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
        let options: NSStringDrawingOptions = [.usesFontLeading, .usesLineFragmentOrigin]
        let bounds = (text as NSString).boundingRect(with: constrainedSize, options: options, attributes: attributes, context: nil)
        return ceil(bounds.height) + 24
    }
    
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    public var recoverButtonHidden: Bool = true {
        didSet {
            recoverButton.isHidden = recoverButtonHidden
            recoverButton.setTitle(recoverButtonHidden ? "" : BundleI18n.SKResource.CreationMobile_Wiki_Permission_Recover_Button, for: .normal)
            recoverButton.sizeToFit()
            setupConstraints()
        }
    }
    
    public var recoverButtonCallback: (() -> Void)?
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.SKResource.Common.Collaborator.permission_icon_lock.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UDColor.functionInfoContentDefault
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        return label
    }()
    
    private lazy var recoverButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(BundleI18n.SKResource.CreationMobile_Wiki_Permission_Recover_Button, for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(clickRecoverButton(_:)), for: .touchUpInside)
        return button
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(recoverButton)
    }
    
    private func setupConstraints() {
        iconImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(18)
            make.width.height.equalTo(16)
        }
        
        if recoverButton.isHidden {
            titleLabel.snp.remakeConstraints { (make) in
                make.leading.equalTo(iconImageView.snp.trailing).offset(10)
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-12)
                make.trailing.equalToSuperview().offset(-18)
            }
        } else {
            titleLabel.snp.remakeConstraints { (make) in
                make.leading.equalTo(iconImageView.snp.trailing).offset(10)
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-12)
                make.trailing.equalTo(recoverButton.snp.leading).offset(-10)
            }
         }

        recoverButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-18)
            make.height.equalTo(30)
        }
    }

    @objc
    private func clickRecoverButton(_ sender: UIButton) {
        recoverButtonCallback?()
    }
}
