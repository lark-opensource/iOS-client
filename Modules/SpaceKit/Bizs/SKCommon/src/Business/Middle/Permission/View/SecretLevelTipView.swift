//
//  SecretLevelTipView.swift
//  SKECM
//
//  Created by guoqp on 2021/5/15.
//

import Foundation
import SKFoundation
import SKResource

/*
public protocol SecretLevelTipViewDelegate: AnyObject {
    func shouldOpenSecretSetting(_ view: SecretLevelTipView)
}

private let titleLabelFont = UIFont.docs.pfsc(14)
public class SecretLevelTipView: UIView {
    public weak var delegate: SecretLevelTipViewDelegate?
    public private(set) var type: PermissonVCBannerStyle = .hide

    private var iconView: UIImageView = {
        let v = UIImageView(frame: CGRect.zero)
        v.image = BundleResources.SKResource.Space.FileList.icon_permisson_isv_tip.withRenderingMode(.alwaysTemplate)
        return v
    }()
    public var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = titleLabelFont
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.N900
        return label
    }()
    public var linkLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = titleLabelFont
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.textAlignment = .left
        label.textColor = UIColor.ud.colorfulBlue
        label.isUserInteractionEnabled = true
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()

    var tap: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.B100
        self.addSubview(self.iconView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.linkLabel)

        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
//            make.centerY.equalToSuperview()
            make.top.equalToSuperview().offset(14)
            make.height.width.equalTo(16)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
        }

        linkLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-12)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalToSuperview().inset(-16)
        }

        linkLabel.text = BundleI18n.SKResource.CreationMobile_SecureLabel_Set_Btn
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapTitleLable(_:)))
        self.linkLabel.addGestureRecognizer(tap)
    }

    public func updateTitleLabel(title: String) {
        titleLabel.text = title
    }

    func title(name: String) -> String {
        switch self.type {
        case .setting:
            return BundleI18n.SKResource.CreationMobile_SecureLabel_Prompt
        case .update:
            return BundleI18n.SKResource.CreationMobile_SecureLabel_PermSettings_Alert(name)
        case .tips:
            return BundleI18n.SKResource.CreationMobile_SecureLabel_Restricted_ExternalUser
        case .hide:
            return ""
        }
    }

    public func updateType(type: PermissonVCBannerStyle) {
        self.type = type
        linkLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-12)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalToSuperview().inset(-16)
            if type == .hide {
                make.height.equalTo(0)
            }
        }

        switch type {
        case .setting, .update:
            linkLabel.text = BundleI18n.SKResource.CreationMobile_SecureLabel_Set_Btn
        default:
            linkLabel.text = nil
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapTitleLable(_ ges: UITapGestureRecognizer) {
        self.delegate?.shouldOpenSecretSetting(self)
    }
}
*/
