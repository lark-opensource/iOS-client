//
//  CategoryLabelHeaderView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/12/20.
//

import LarkUIKit

/// 分组筛选页面的haderView
final class CategoryLabelHeaderView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AppCategory
        label.textAlignment = .left
        return label
    }()

    // MARK: view initial
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refresh(isPopupMode: Bool, isNewCategory: Bool) {
        titleLabel.font = .systemFont(ofSize: isPopupMode ? 16 : 20, weight: .medium)
        let allCategoriesTtl = BundleI18n.LarkWorkplace.OpenPlatform_Workplace_AllCategoriesTtl
        let appCategory = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AppCategory
        titleLabel.text = isNewCategory ? allCategoriesTtl : appCategory
        titleLabel.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
                .inset(isPopupMode ? popCategoryPageViewInset : normalCategoryPageViewInset)
            make.height.equalTo(isPopupMode ? 24 : 28)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    private func setupView() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(normalCategoryPageViewInset)
            make.height.equalTo(28)
            make.bottom.equalToSuperview().inset(16)
        }
    }
}
