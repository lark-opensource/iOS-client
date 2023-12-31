//
//  NaviRecommandHeaders.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/11/6.
//

import UIKit
import UniverseDesignColor

// 推荐列表上面带有标题的头部控件
final class RecommandHeaderTitleView: UICollectionReusableView {
    static var identifier: String = "RecommandHeaderTitleView"

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.textCaption
        label.text = BundleI18n.AnimatedTabBar.Lark_Navbar_FrequentVisits_Mobile_Text
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-22)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
