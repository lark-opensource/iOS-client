//
//  AppCenterHomeCategroyCollectionViewCell.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/10/17.
//

import LarkUIKit
import SnapKit
import UniverseDesignFont
import UIKit

private enum Const {
    static let cellCornerRadius: CGFloat = 6
    static let unselectedBackgroundColor: UIColor = UIColor.ud.udtokenTabSeBgUnselected // 灰色
    static let selectedBackgroundColor: UIColor = UIColor.ud.udtokenTabPriBg  // 蓝色
    static let unselectedTextColor: UIColor = UIColor.ud.textTitle  // 黑色
    static let selectedTextColor: UIColor = UIColor.ud.udtokenTabPriText  // 深蓝色
}

final class AppCenterHomeCategroyCollectionViewCell: UICollectionViewCell {

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.caption1
        label.textColor = Const.unselectedTextColor
        label.highlightedTextColor = Const.selectedTextColor
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(6)
            make.top.bottom.equalToSuperview().inset(2)
        }

        backgroundView = createBackgroundView()
        selectedBackgroundView = createSelectedBackgroundView()
    }

    // 创建 UICollectionViewCell.backgroundView 图层
    private func createBackgroundView() -> UIView {
        let bgView = UIView()
        bgView.clipsToBounds = true
        bgView.layer.cornerRadius = Const.cellCornerRadius
        bgView.backgroundColor = Const.unselectedBackgroundColor
        return bgView
    }

    // 创建 UICollectionViewCell.selectedBackgroundView 图层
    private func createSelectedBackgroundView() -> UIView {
        let selectedBgView = UIView()
        selectedBgView.clipsToBounds = true
        selectedBgView.layer.cornerRadius = Const.cellCornerRadius
        selectedBgView.backgroundColor = Const.selectedBackgroundColor
        return selectedBgView
    }

    /// 更新label名称
    /// - Parameter text: 分类名称
    func updateText(with text: String) {
        label.text = text
    }
}
