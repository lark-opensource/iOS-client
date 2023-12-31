//
//  LocationHeaderView.swift
//  LarkChat
//
//  Created by Fangzhou Liu on 2019/6/6.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkButton
import LarkUIKit
import SnapKit

typealias Resources = BundleResources.LarkLocationPicker

final class LocationHeaderView: UIView {

    init(frame: CGRect, backgroundColor: UIColor) {
        super.init(frame: frame)
        self.backgroundColor = backgroundColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LocationHeaderView {
    public func addLeftNavItem(icon: UIImage?, highlighted: UIImage?, title: String? = nil) -> UIButton {
        let leftNavItem = TypeButton(type: .custom)
        if let btnImage = icon, let highlightImage = highlighted {
            leftNavItem.setImage(btnImage, for: .normal)
            leftNavItem.setImage(highlightImage, for: .highlighted)
            leftNavItem.contentMode = .scaleAspectFill
        }
        if let btnTitle = title {
            leftNavItem.setTitle(btnTitle, for: .normal)
        }
        leftNavItem.contentHorizontalAlignment = .center
        self.addSubview(leftNavItem)
        leftNavItem.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(LocationUtils.navItemMargin)
            make.size.equalTo(LocationUtils.navItemSize)
        }
        return leftNavItem
    }

    public func addRightNavItem(icon: UIImage?, highlighted: UIImage?, title: String? = nil) -> UIButton {
        let rightNavItem = TypeButton(type: .custom)
        if let btnImage = icon, let highlightImage = highlighted {
            rightNavItem.setImage(btnImage, for: .normal)
            rightNavItem.setImage(highlightImage, for: .highlighted)
            rightNavItem.contentMode = .scaleAspectFill
        }
        if let btnTitle = title {
            rightNavItem.setTitle(btnTitle, for: .normal)
        }
        rightNavItem.contentHorizontalAlignment = .center
        self.addSubview(rightNavItem)
        rightNavItem.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-LocationUtils.navItemMargin)
            make.size.equalTo(LocationUtils.navItemSize)
        }
        return rightNavItem
    }
}

final class LocationFooterView: UIView {

    public lazy var navigateButton: UIButton = {
        let button = TypeButton(type: .custom)
        button.setImage(Resources.location_navigate, for: .normal)
        button.setImage(Resources.location_navigate_clicked, for: .highlighted)
        button.contentHorizontalAlignment = .center
        return button
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private var locationInfoView = UIStackView()

    init(frame: CGRect, backgroundColor: UIColor) {
        super.init(frame: frame)
        self.backgroundColor = backgroundColor
        self.addSubview(locationInfoView)
        self.addSubview(navigateButton)

        locationInfoView.axis = .vertical
        locationInfoView.spacing = 1.5
        locationInfoView.alignment = .leading
        locationInfoView.distribution = .fill
        locationInfoView.addArrangedSubview(nameLabel)
        locationInfoView.addArrangedSubview(descriptionLabel)

        navigateButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14.5)
            make.right.equalToSuperview().offset(-LocationUtils.outsideMargin)
            make.size.equalTo(LocationUtils.buttonSize)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-14.5)
        }

        locationInfoView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(LocationUtils.outsideMargin)
            make.left.equalToSuperview().offset(LocationUtils.outsideMargin)
            make.right.equalTo(navigateButton.snp.left).offset(-LocationUtils.innerMargin)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-LocationUtils.outsideMargin)
        }
        nameLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateContent(name: String, address: String) {
        self.nameLabel.text = name
        self.descriptionLabel.isHidden = address.isEmpty
        self.descriptionLabel.text = address
    }
}
