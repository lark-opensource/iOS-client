//
//  ShowCollaboratorInfoFooterView.swift
//  SKCommon
//
//  Created by peilongfei on 2022/8/15.
//  


import UIKit
import UniverseDesignColor
import SKResource
import SnapKit

class ShowCollaboratorInfoFooterView: UIView {

    let contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = BundleI18n.SKResource.LarkCCM_Perm_WhoCanViewProfilePicture_OnlyForCurrentDoc_Description
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        backgroundColor = UDColor.bgBase
        addSubview(contentLabel)
        
        contentLabel.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview().inset(16)
        }
    }
}
