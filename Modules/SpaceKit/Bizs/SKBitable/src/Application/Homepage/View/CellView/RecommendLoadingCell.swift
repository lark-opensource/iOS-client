//
//  BitableRecommendCell.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/9/4.
//

import Foundation
import UIKit
import SnapKit
import SkeletonView
import UniverseDesignColor

struct RecommendLoadingCellLayoutConfig {
    static let topImageHWRate: CGFloat = 121.0/192
    static let innnerMarigin6: CGFloat = 6.0
    static let innnerMarigin12: CGFloat = 12.0
    static let innerHeight16: CGFloat = 16.0
    static let iconMarginBottom: CGFloat = 14.0
    static let nameImageWidth: CGFloat = 56.0
}

class RecommendLoadingCell: UICollectionViewCell {
    private lazy var topImageView: UIImageView = {
        let topImageView = UIImageView()
        topImageView.isSkeletonable = true
        topImageView.clipsToBounds = true
        return topImageView
    }()
    
    private lazy var titleImageView: UIImageView = {
        let titleImageView = UIImageView()
        titleImageView.isSkeletonable = true
        titleImageView.layer.cornerRadius = 4
        titleImageView.clipsToBounds = true
        return titleImageView
    }()
    
    private lazy var shortTitleImageView: UIImageView = {
        let shortTitleImageView = UIImageView()
        shortTitleImageView.isSkeletonable = true
        shortTitleImageView.layer.cornerRadius = 4
        shortTitleImageView.clipsToBounds = true
        return shortTitleImageView
    }()
    
    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.isSkeletonable = true
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        return iconImageView
    }()
    
    private lazy var nameImageView: UIImageView = {
        let nameImageView = UIImageView()
        nameImageView.isSkeletonable = true
        nameImageView.layer.cornerRadius = 4
        nameImageView.clipsToBounds = true
        return nameImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = UDColor.bgFloat
        
        self.isSkeletonable = true
        contentView.layer.cornerRadius = 8
        contentView.layer.shadowOffset = CGSize(width: 4, height: 8)
        contentView.clipsToBounds = true
        
        contentView.addSubview(topImageView)
        contentView.addSubview(titleImageView)
        contentView.addSubview(shortTitleImageView)
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameImageView)

        topImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(contentView.snp.width).multipliedBy(RecommendLoadingCellLayoutConfig.topImageHWRate)
        }
        
        titleImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(RecommendLoadingCellLayoutConfig.innnerMarigin12)
            make.top.equalTo(topImageView.snp.bottom).offset(RecommendLoadingCellLayoutConfig.innnerMarigin12)
            make.right.equalToSuperview().offset(-RecommendLoadingCellLayoutConfig.innnerMarigin12)
            make.height.equalTo(RecommendLoadingCellLayoutConfig.innerHeight16)
        }
        
        shortTitleImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(RecommendLoadingCellLayoutConfig.innnerMarigin12)
            make.top.equalTo(titleImageView.snp.bottom).offset(RecommendLoadingCellLayoutConfig.innnerMarigin12)
            make.width.equalTo(RecommendLoadingCellLayoutConfig.nameImageWidth)
            make.height.equalTo(RecommendLoadingCellLayoutConfig.innerHeight16)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(RecommendLoadingCellLayoutConfig.innnerMarigin12)
            make.size.equalTo(RecommendLoadingCellLayoutConfig.innerHeight16)
            make.top.equalTo(shortTitleImageView.snp.bottom).offset(RecommendLoadingCellLayoutConfig.innnerMarigin12)
        }
        
        nameImageView.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(RecommendLoadingCellLayoutConfig.innnerMarigin6)
            make.width.equalTo(RecommendLoadingCellLayoutConfig.nameImageWidth)
            make.centerY.equalTo(iconImageView)
            make.height.equalTo(RecommendLoadingCellLayoutConfig.innerHeight16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func cellWithReuseIdentifier() -> String {
        return "LoadingCellIdentifier"
    }
}
