//
//  ZoomMeetingPhoneListNavigationBar.swift
//  Calendar
//
//  Created by pluto on 2022/11/10.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignIcon

final class ZoomMeetingPhoneListNavigationBar: UIView {

    var closeTapped: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var closeBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1), for: .normal)
        button.increaseClickableArea()
        button.addTarget(self, action: #selector(tapBtn), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        addSubview(closeBtn)

        titleLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.height.equalTo(24)
        }

        closeBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(24)
            make.centerY.equalTo(titleLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configNavigationBar(title: String, tapCallBack: (() -> Void)?) {
        titleLabel.text = title
        closeTapped = tapCallBack
    }

    @objc
    private func tapBtn() {
        closeTapped?()
    }
}
