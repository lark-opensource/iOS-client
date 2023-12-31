//
//  QuickLaunchHeaders.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/7/9.
//

import UIKit
import UniverseDesignColor

// 最近使用上面带有标题的头部控件
final class TabHeaderTitleView: UICollectionReusableView {
    static var identifier: String = "TabTitleHeaderView"

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.ud.title3(.fixed)
        label.textColor = UIColor.ud.textTitle
        //label.textColor = UIColor.ud.primaryPri500
        label.text = BundleI18n.AnimatedTabBar.Lark_SuperApp_More_Recents_Title
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

// 快捷导航上面带有编辑按钮的头部控件
final class TabHeaderEditView: UICollectionReusableView {
    static var identifier: String = "TabEditHeaderView"
    
    var editHandler: (() -> Void)?

    private lazy var editButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.AnimatedTabBar.Lark_Core_More_EditApp_Button, for: .normal)
        button.titleLabel?.font = UIFont.ud.body0
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.backgroundColor = UIColor.clear
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.ud.title2
        label.textColor = UIColor.ud.textTitle
        //label.textColor = UIColor.ud.primaryPri500
        label.text = BundleI18n.AnimatedTabBar.Lark_Legacy_NavigationMore
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
        self.addSubview(editButton)
        editButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-22)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        editButton.addTarget(self, action: #selector(didTapEditButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapEditButton() {
        editHandler?()
    }
}

