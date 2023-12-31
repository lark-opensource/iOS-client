//
//  File.swift
//  SKCommon
//
//  Created by zhysan on 2022/7/18.
//

import UIKit
import SnapKit
import SKResource
import UniverseDesignColor
import UniverseDesignFont

class BitableAdPermEmptyCell: BitableAdPermBaseCell {
    
    static let defaultReuseID = "BitableAdPermEmptyCell"
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.sk_setText(BundleI18n.SKResource.Bitable_AdvancedPermission_PleaseSetRoleOnDesktop_Mobile)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(15)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
