//
//  OpenAPIAuthUserInfoTableViewCell.swift
//  LarkAccount
//
//  Created by au on 2023/6/7.
//

import UIKit
import UniverseDesignFont

class OpenAPIAuthUserInfoTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configCell(authInfo: OpenAPIAuthGetAuthInfo) {
        let headerLabel = UILabel()
        headerLabel.text = I18N.Lark_Passport_AuthorizedAppDesc
        headerLabel.textColor = UIColor.ud.textCaption
        headerLabel.font = UDFont.systemFont(ofSize: 14)
        headerLabel.textAlignment = .left
        contentView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(36)
            make.height.equalTo(20)
            make.left.right.equalToSuperview().inset(16)
        }

        let tenantBackgroudView = UIView()
        tenantBackgroudView.backgroundColor = UIColor.ud.bgBase
        tenantBackgroudView.layer.cornerRadius = Common.Layer.commonAppIconRadius
        tenantBackgroudView.clipsToBounds = true
        contentView.addSubview(tenantBackgroudView)
        tenantBackgroudView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.height.equalTo(80)
        }

        let tenantIconView = UIImageView()
        tenantIconView.layer.cornerRadius = 6.5
        tenantIconView.clipsToBounds = true
        if let urlString = authInfo.currentUser?.tenantIconURL, let url = URL(string: urlString) {
            tenantIconView.kf.setImage(with: url, placeholder: DynamicResource.default_avatar)
        } else {
            tenantIconView.image = DynamicResource.default_avatar
        }
        tenantBackgroudView.addSubview(tenantIconView)
        tenantIconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
            make.left.equalToSuperview().offset(16)
        }

        let tenantLabel = UILabel()
        tenantLabel.font = UDFont.systemFont(ofSize: 16, weight: .medium)
        tenantLabel.textColor = UIColor.ud.textTitle
        tenantLabel.text = authInfo.currentUser?.tenantName
        tenantBackgroudView.addSubview(tenantLabel)
        tenantLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(19)
            make.left.equalToSuperview().offset(76)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(22)
        }

        let nameLabel = UILabel()
        nameLabel.font = UDFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor.ud.textCaption
        nameLabel.text = authInfo.currentUser?.userName
        tenantBackgroudView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(41)
            make.left.equalToSuperview().offset(76)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(20)
        }
    }

}
