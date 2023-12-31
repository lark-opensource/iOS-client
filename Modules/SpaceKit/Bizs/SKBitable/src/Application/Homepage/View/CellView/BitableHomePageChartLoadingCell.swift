//
//  BitableRecommendCell.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/11/21.
//

import Foundation
import UIKit
import SnapKit
import SkeletonView

class BitableHomePageChartLoadingCell: UICollectionViewCell {
    private lazy var titleImageView: UIImageView = {
        let titleImageView = UIImageView()
        titleImageView.isSkeletonable = true
        titleImageView.layer.cornerRadius = 4
        titleImageView.clipsToBounds = true
        return titleImageView
    }()
    
    private lazy var contentImageView: UIImageView = {
        let contentImageView = UIImageView()
        contentImageView.isSkeletonable = true
        contentImageView.layer.cornerRadius = 4
        contentImageView.clipsToBounds = true
        return contentImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 需要设置圆角以实现整个section为一个卡片的效果
        layer.cornerRadius = 20
        layer.masksToBounds = true
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
        
        contentView.backgroundColor = BitableHomeChartCellLayoutConfig.chartCellBackgroundColor
        
        self.isSkeletonable = true
        
        contentView.addSubview(titleImageView)
        contentView.addSubview(contentImageView)
        
        titleImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.width.equalToSuperview().multipliedBy(0.4)
            make.height.equalTo(14)
        }
        
        contentImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(titleImageView).offset(20)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        titleImageView.setNeedsLayout()
        titleImageView.layoutIfNeeded()
        
        contentImageView.setNeedsLayout()
        contentImageView.layoutIfNeeded()
        
        titleImageView.showUDSkeleton()
        contentImageView.showUDSkeleton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func cellWithReuseIdentifier() -> String {
        return "BitableHomePageChartLoadingCellIdentifier"
    }
}
