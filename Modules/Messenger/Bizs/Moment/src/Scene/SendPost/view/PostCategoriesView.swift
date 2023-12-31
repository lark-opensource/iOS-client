//
//  PostCategoriesView.swift
//  Moment
//
//  Created by bytedance on 2021/8/16.
//

import Foundation
import UIKit
import UniverseDesignColor

final class PostCategoriesView: UIControl {
    var onTapped: (() -> Void)?

    private let backgroundColorNormal: UIColor = UDColor.N50 & UDColor.N300
    private let backgroundColorPress: UIColor = UDColor.N200 & UDColor.N400
    private var categoryId: String?
    private let iconSize: CGFloat = 36

    //尚未选择板块
    private lazy var categorySelectView: UIView = {
        let view = UIView()
        let image = UIImageView()
        image.tintColor = .ud.iconN1
        image.image = Resources.categoriesOutlined.withRenderingMode(.alwaysTemplate)
        view.addSubview(image)
        image.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .ud.textTitle
        label.text = BundleI18n.Moment.Lark_Moments_SelectACategory
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(image.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        view.isUserInteractionEnabled = false
        return view
    }()

    //选择了板块
    private lazy var categoryView: FromCategoryBar = {
        let view = FromCategoryBar(frame: .zero, iconWidth: iconSize, backgroundColorNormal: .clear, backgroundColorPress: .clear)
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 8
        clipsToBounds = true
        self.backgroundColor = backgroundColorNormal
        setupView()
        self.addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(categorySelectView)
        categorySelectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addSubview(categoryView)
    }

    func update(title: String, iconKey: String, id: String) {
        let titleFont: UIFont = .systemFont(ofSize: 14, weight: .medium)
        categoryView.update(title: title, iconKey: iconKey, titleFont: titleFont, enable: true)
        categoryId = id
        categorySelectView.isHidden = true
        categoryView.isHidden = false
        categorySelectView.snp.removeConstraints()
        categoryView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(FromCategoryBar.sizeToFit(iconWidth: iconSize, title: title, titleFont: titleFont, iconKey: iconKey, enable: true).width)
        }
    }

    func getCategoryId() -> String? {
        return categoryId
    }

    @objc
    private func selfTapped() {
        self.onTapped?()
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? backgroundColorPress : backgroundColorNormal
        }
    }
}
