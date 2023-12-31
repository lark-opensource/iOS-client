//
//  AppDetailReviewInfoView.swift
//  LarkAppCenter
//
//  Created by dengbo on 2021/12/23.
//

import Foundation
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignIcon
import UniverseDesignFont
import UIKit
import SnapKit
import LarkOPInterface

class AppDetailReviewInfoView: UIView {
    
    struct Const {
        static let starContainerWidth: CGFloat = 84
        static let starContainerHeight: CGFloat = 15
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var starContainer: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 3.2
        return view
    }()
    
    private lazy var reviewLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.primaryContentDefault
        label.text = BundleI18n.LarkOpenPlatform.OpenPlatform_AppRating_ProfileGoToRateLink
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private lazy var moreImg: UIImageView = {
        let more = UIImageView(frame: .zero)
        more.image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3)
        more.clipsToBounds = true
        return more
    }()
    
    private lazy var reviewScoreLabel: UILabel = {
        let label = UILabel()
        label.font =  UDFont.dinBoldFont(ofSize: 24)
        label.textColor = UIColor.ud.textTitle
        return label
    }()
    
    private lazy var reviewIntroLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()
    
    private func setupViews() {
        backgroundColor = .clear
        addSubview(reviewScoreLabel)
        addSubview(starContainer)
        addSubview(reviewIntroLabel)
        addSubview(reviewLabel)
        addSubview(moreImg)
        reviewScoreLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
        }
        reviewLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        moreImg.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(4)
            make.width.height.equalTo(16)
        }
        reviewIntroLabel.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(reviewLabel.snp.leading)
        }
    }
    
    func updateViews(appReviewInfo: AppReviewInfo?) {
        let score = Int(appReviewInfo?.score ?? 0)
        let reviewed = appReviewInfo?.isReviewed ?? false
        
        starContainer.subviews.forEach { $0.removeFromSuperview() }
        for index in 1...5 {
            let color = index <= score ? UIColor.ud.colorfulYellow : UIColor.ud.N90015
            let imageView = UIImageView(image: UDIcon.collectFilled.ud.withTintColor(color))
            starContainer.addArrangedSubview(imageView)
        }
        
        reviewScoreLabel.isHidden = !reviewed
        reviewLabel.isHidden = reviewed
        moreImg.isHidden = !reviewed
        if reviewed {
            reviewScoreLabel.text = String(format: "%.1f", Float(score))
            starContainer.snp.remakeConstraints { make in
                make.leading.equalTo(reviewScoreLabel.snp.trailing).offset(5)
                make.centerY.equalTo(reviewScoreLabel)
                make.size.equalTo(CGSize(width: Const.starContainerWidth, height: Const.starContainerHeight))
            }
            reviewIntroLabel.text = BundleI18n.LarkOpenPlatform.OpenPlatform_AppRating_MyRatingTtl
        } else {
            starContainer.snp.remakeConstraints { make in
                make.leading.top.equalToSuperview()
                make.size.equalTo(CGSize(width: Const.starContainerWidth, height: Const.starContainerHeight))
            }
            reviewIntroLabel.text = BundleI18n.LarkOpenPlatform.OpenPlatform_AppRating_NotRatedYet
        }
    }
}
