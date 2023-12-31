//
//  CustomNavigationBar.swift
//  ByteView
//
//  Created by wulv on 2022/9/12.
//

import Foundation
import UIKit

class CustomNavigationBar: UIView {

    let line = UIView()
    let leftButton = UIButton(type: .system)
    let rightButton = UIButton(type: .system)
    let titleLabel = UILabel()
    let titleContainerView = UIView()

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        backgroundColor = UIColor.ud.bgFloat

        line.isUserInteractionEnabled = false
        line.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }

        leftButton.tintColor = UIColor.ud.iconN1
        leftButton.setTitleColor(.ud.textTitle, for: .normal)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        leftButton.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .normal)
        leftButton.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .highlighted)
        leftButton.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .disabled)
        leftButton.addInteraction(type: .highlight)
        leftButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        leftButton.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(leftButton)
        leftButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(safeAreaLayoutGuide).offset(16)
            make.width.greaterThanOrEqualTo(24)
        }

        rightButton.tintColor = UIColor.ud.iconN1
        rightButton.setTitleColor(.ud.textTitle, for: .normal)
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        rightButton.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .normal)
        rightButton.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .highlighted)
        rightButton.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .disabled)
        rightButton.addInteraction(type: .highlight)
        rightButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightButton.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(rightButton)
        rightButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalTo(safeAreaLayoutGuide).inset(16)
            make.width.greaterThanOrEqualTo(24)
        }

        titleLabel.textColor = .ud.textTitle
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.backgroundColor = UIColor.ud.bgFloat
        insertSubview(titleLabel, belowSubview: leftButton)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(leftButton.snp.right)
            make.right.equalTo(rightButton.snp.left)
        }

        insertSubview(titleContainerView, aboveSubview: titleLabel)
        titleContainerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftButton.snp.right)
            make.right.lessThanOrEqualTo(rightButton.snp.left)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
