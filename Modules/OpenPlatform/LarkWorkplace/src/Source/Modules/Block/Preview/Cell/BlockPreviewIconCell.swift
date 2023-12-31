//
//  BlockPreviewIconCell.swift
//  LarkWorkplace
//
//  Created by yinyuan on 2021/2/24.
//

import Foundation
import LarkUIKit
import LarkInteraction

/// Block 真机预览界面的 icon 图标，不同于正常的图标
final class BlockPreviewIconCell: UICollectionViewCell {

    /// icon圆形图标
    private lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.layer.cornerRadius = avatarCornerL
        iconView.clipsToBounds = true
        iconView.backgroundColor = UIColor.ud.bgFiller
        return iconView
    }()

    /// 应用名称标题
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.layer.cornerRadius = previewTitleCorner
        titleLabel.clipsToBounds = true
        titleLabel.backgroundColor = UIColor.ud.bgFiller
        return titleLabel
    }()

    // MARK: 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化视图
    private func setupViews() {
        contentView.addSubview(iconView)    // icon圆形图标
        contentView.addSubview(titleLabel)  // 应用名称标题
        setupConstraint()
    }

    /// 初始化布局约束
    private func setupConstraint() {
        iconView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(5)
            make.height.width.equalTo(avatarSideL)
            make.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(9.51)
            make.centerX.equalToSuperview()
            make.height.equalTo(14)
            make.width.equalTo(60)
        }
    }
}
