//
//  AppRankBadgeSettingCell.swift
//  LarkWorkplace
//
//  Created by houjihu on 2020/12/20.
//

import Foundation
import LarkUIKit
import UIKit
import SnapKit
import UniverseDesignIcon

/// 「工作台设置」列表中显示的应用角标设置cell
final class AppRankBadgeSettingCell: UICollectionViewCell {
    /// cell 配置
    enum Config {
        /// cell height
        static let cellHeight: CGFloat = 48
        /// reuse ID
        static let reuseID: String = "AppRankBadgeSettingCellReuseID"
    }

//    /// 分割线-bottom
//    private lazy var bottomDividerLine: UIView = {
//        let deviderLine = UIView()
//        deviderLine.backgroundColor = UIColor.ud.lineDividerDefault
//        return deviderLine
//    }()
//    /// 分割线-top
//    private lazy var topDividerLine: UIView = {
//        let deviderLine = UIView()
//        deviderLine.backgroundColor = UIColor.ud.lineDividerDefault
//        return deviderLine
//    }()

    // MARK: cell 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: setup views & constraints
    func setupViews() {
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

//        contentView.addSubview(bottomDividerLine)
//        contentView.addSubview(topDividerLine)
//        bottomDividerLine.snp.makeConstraints { make in
//            make.height.equalTo(0.5)
//            make.bottom.left.right.equalToSuperview()
//        }
//        topDividerLine.snp.makeConstraints { make in
//            make.height.equalTo(0.5)
//            make.top.left.right.equalToSuperview()
//        }

        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        label.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_BadgeSettingsTtl
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-44)
            make.centerY.equalToSuperview()
        }

        let detailImageView = UIImageView()
        detailImageView.image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3)
        detailImageView.contentMode = .scaleAspectFit
        contentView.addSubview(detailImageView)
        detailImageView.snp.makeConstraints { make in
            make.size.equalTo(16)
            make.left.equalTo(label.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(label)
        }
    }
}
