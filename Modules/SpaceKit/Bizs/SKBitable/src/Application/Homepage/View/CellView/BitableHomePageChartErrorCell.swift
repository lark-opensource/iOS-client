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

@objc protocol BitableHomePageChartErrorCellDelegate: AnyObject {
    @objc optional func triggerRetry(_ cell: BitableHomePageChartErrorCell)
}

class BitableHomePageChartErrorCell: UICollectionViewCell {
    
    weak var delegate: BitableHomePageChartErrorCellDelegate?
    
    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.isSkeletonable = true
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.image = BundleResources.SKResource.Bitable.multilist_error_bg
        return iconImageView
    }()
    
    private lazy var tipTitle: UILabel = {
        let tipTitle = UILabel(frame: .zero)
        tipTitle.font = UIFont.systemFont(ofSize: 14.0)
        tipTitle.textColor = UDColor.textCaption
        tipTitle.text = BundleI18n.SKResource.Bitable_HomeDashboard_LoadFailed_Desc
        tipTitle.sizeToFit()
        return tipTitle
    }()
    
    let refreshButton: UIButton = {
        let refreshButton = UIButton(frame: .zero)
        refreshButton.setImage(UDIcon.getIconByKey(.refreshOutlined, iconColor: UDColor.staticWhite,size: CGSize(width: 14, height: 14)), for: .normal)
        refreshButton.setImage(UDIcon.getIconByKey(.refreshOutlined, iconColor: UDColor.staticWhite,size: CGSize(width: 14, height: 14)), for: .highlighted)
        refreshButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        refreshButton.setTitle(BundleI18n.SKResource.Bitable_HomeDashboard_Reload_Button, for: .normal)
        refreshButton.backgroundColor = UDColor.B500
        refreshButton.imageEdgeInsets = UIEdgeInsets(top: 9, left: 0, bottom: 9, right: 6)
        refreshButton.contentMode = .scaleAspectFit
        refreshButton.layer.cornerRadius = 8
        return refreshButton
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = BitableHomeChartCellLayoutConfig.chartCellBackgroundColor
        
        contentView.layer.cornerRadius = 20
        contentView.layer.shadowOffset = CGSize(width: 4, height: 8)
        contentView.clipsToBounds = true
        contentView.addSubview(iconImageView)
        contentView.addSubview(tipTitle)
        refreshButton.addTarget(self, action: #selector(retryButtonClicked), for: .touchUpInside)
        contentView.addSubview(refreshButton)
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
        }
        
        tipTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(5)
        }
        
        refreshButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(tipTitle.snp.bottom).offset(12)
            make.size.equalTo(CGSize(width: 100, height: 32))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func cellWithReuseIdentifier() -> String {
        return "BitableHomePageChartErrorCellIdentifier"
    }
    
    @objc func retryButtonClicked() {
        delegate?.triggerRetry?(self)
    }
}
