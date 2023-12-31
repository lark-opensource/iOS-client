//
//  BitableRecommendCell.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/11/21.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import SKResource

@objc protocol BitableHomePageChartEmptyCellDelegate: AnyObject {
    @objc optional func addChart(_ cell: BitableHomePageChartEmptyCell)
}

class BitableHomePageChartEmptyCell: UICollectionViewCell {
    
    weak var delegate: BitableHomePageChartEmptyCellDelegate?
    
    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.isSkeletonable = true
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.image = BundleResources.SKResource.Bitable.base_homepage_dashboard_empty
        return iconImageView
    }()
    
    private lazy var tipTitle: UILabel = {
        let tipTitle = UILabel(frame: .zero)
        tipTitle.font = UIFont.systemFont(ofSize: 14.0)
        tipTitle.textColor = UDColor.textCaption
        tipTitle.text = BundleI18n.SKResource.Bitable_HomeDashboard_AddChartHere_Desc
        tipTitle.sizeToFit()
        return tipTitle
    }()
    
    let addChatrtButton: UIButton = {
        let addChatrtButton = UIButton(frame: .zero)
        addChatrtButton.setImage(UDIcon.getIconByKey(.addOutlined, iconColor: UDColor.staticWhite,size: CGSize(width: 12, height: 12)), for: .normal)
        addChatrtButton.setImage(UDIcon.getIconByKey(.addOutlined, iconColor: UDColor.staticWhite,size: CGSize(width: 12, height: 12)), for: .highlighted)
        addChatrtButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        addChatrtButton.setTitle(BundleI18n.SKResource.Bitable_HomeDashboard_AddChart_Button, for: .normal)
        addChatrtButton.backgroundColor = UDColor.B500
        addChatrtButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        addChatrtButton.contentMode = .scaleAspectFit
        addChatrtButton.layer.cornerRadius = 8
        return addChatrtButton
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = BitableHomeChartCellLayoutConfig.chartCellBackgroundColor
        
        contentView.layer.cornerRadius = 20
        contentView.layer.shadowOffset = CGSize(width: 4, height: 8)
        contentView.clipsToBounds = true
        contentView.addSubview(iconImageView)
        contentView.addSubview(tipTitle)
        addChatrtButton.addTarget(self, action: #selector(addChartButtonClicked), for: .touchUpInside)
        contentView.addSubview(addChatrtButton)
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
        }
        
        tipTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(5)
        }
        
        addChatrtButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(tipTitle.snp.bottom).offset(12)
            make.size.equalTo(CGSize(width: 86, height: 32))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func cellWithReuseIdentifier() -> String {
        return "BitableHomePageChartEmptyCellIdentifier"
    }
    
    @objc func addChartButtonClicked() {
        delegate?.addChart?(self)
    }
}
