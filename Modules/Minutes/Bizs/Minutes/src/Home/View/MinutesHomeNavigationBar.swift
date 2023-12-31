//
//  MinutesHomeNavigationBar.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/4/11.
//

import UIKit
import UniverseDesignIcon

class MinutesHomeNavigationBar: UIView {
    lazy var backButton: UIButton = {
        let button: UIButton = UIButton(type: .custom, padding: 20)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        return button
    }()

    lazy var closeButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        return button
    }()

    lazy var splitButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.sepwindowOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        return button
    }()

    lazy var zoomButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UIImage.dynamicIcon(.iconMagnifyOutlined, dimension: 24, color: UIColor.ud.iconN1), for: .normal)
        button.setImage(UIImage.dynamicIcon(.iconMinifyOutlined, dimension: 24, color: UIColor.ud.iconN1), for: .selected)
        return button
    }()


    private lazy var leftStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubview(backButton)
        backButton.snp.makeConstraints { maker in
            maker.width.height.equalTo(44)
        }
        stackView.addArrangedSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.width.height.equalTo(44)
        }
        stackView.addArrangedSubview(zoomButton)
        zoomButton.snp.makeConstraints { maker in
            maker.width.height.equalTo(44)
        }
        stackView.addArrangedSubview(splitButton)
        splitButton.snp.makeConstraints { maker in
            maker.width.height.equalTo(44)
        }
        return stackView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var searchButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.searchOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        return button
    }()

    lazy var moreButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.isHidden = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        addSubview(leftStack)
        addSubview(titleLabel)
        addSubview(searchButton)
        addSubview(moreButton)

        leftStack.snp.makeConstraints { (maker) in
            maker.left.equalTo(6)
            maker.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.greaterThanOrEqualTo(leftStack.snp.right).offset(20)
            maker.centerX.equalToSuperview()
            maker.centerY.equalTo(leftStack)
        }
        searchButton.snp.makeConstraints { maker in
            maker.right.equalTo(moreButton.snp.left).offset(-6)
            maker.centerY.equalToSuperview()
        }
        moreButton.snp.makeConstraints { maker in
            maker.right.equalTo(-6)
            maker.width.height.equalTo(44)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
