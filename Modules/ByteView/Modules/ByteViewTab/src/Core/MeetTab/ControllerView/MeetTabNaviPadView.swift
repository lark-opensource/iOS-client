//
//  MeetTabNaviPadView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon

class MeetTabNaviPadView: UIView {

    lazy var contentLayoutGuide: UILayoutGuide = UILayoutGuide()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        let text = I18n.View_MV_MeetingsTab
        label.attributedText = .init(string: text, config: .h1, textColor: UIColor.ud.textTitle)
        return label
    }()

    lazy var badgeView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
        view.backgroundColor = UIColor.ud.functionDangerContentDefault.dynamicColor
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        return view
    }()

    lazy var searchButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.searchOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        return button
    }()

    lazy var rightBarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.settingOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        button.addInteraction(type: .highlight)
        button.addSubview(badgeView)
        badgeView.snp.makeConstraints {
            $0.centerX.equalTo(button.snp.right)
            $0.centerY.equalTo(button.snp.top)
            $0.size.equalTo(6)
        }
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addLayoutGuide(contentLayoutGuide)
        addSubview(titleLabel)
        addSubview(searchButton)
        addSubview(rightBarButton)
        contentLayoutGuide.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16.0).priority(999)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(60.0)
        }
        titleLabel.snp.makeConstraints {
            $0.left.centerY.equalTo(contentLayoutGuide)
        }
        searchButton.snp.makeConstraints {
            $0.size.equalTo(24)
            $0.right.equalTo(rightBarButton.snp.left).offset(-16)
            $0.centerY.equalTo(rightBarButton)
        }
        rightBarButton.snp.makeConstraints {
            $0.size.equalTo(24)
            $0.right.equalToSuperview().inset(16)
            $0.centerY.equalTo(titleLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
