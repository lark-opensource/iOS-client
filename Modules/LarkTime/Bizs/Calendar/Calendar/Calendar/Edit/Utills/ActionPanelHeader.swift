//
//  ActionPanelHeader.swift
//  Calendar
//
//  Created by Hongbin Liang on 8/18/23.
//

import Foundation
import LarkUIKit
import UniverseDesignIcon

/// phone: [ X ------ title -------]
/// pad:   [ title ----------------]
class ActionPanelHeader: UIView {

    var closeCallback: (() -> Void)?

    private let headerLabel: UILabel

    private let closeButton: UIButton

    init(title: String) {
        headerLabel = UILabel.cd.titleLabel(fontSize: 17)
        closeButton = UIButton(type: .custom)
        super.init(frame: .zero)

        headerLabel.text = title

        let closeIcon = UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1)
        closeButton.setImage(closeIcon, for: .normal)
        closeButton.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)

        if Display.pad {
            headerLabel.textAlignment = .left
            addSubview(headerLabel)
            headerLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(16)
            }
        } else {
            addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().inset(16)
                make.size.equalTo(CGSize(width: 24, height: 24))
            }

            headerLabel.textAlignment = .center
            addSubview(headerLabel)
            headerLabel.snp.makeConstraints { make in
                make.centerY.centerX.equalToSuperview()
                make.leading.lessThanOrEqualTo(closeButton.snp.trailing).offset(12)
                make.trailing.lessThanOrEqualToSuperview().inset(52)
            }
        }
    }

    @objc
    private func closeBtnTapped() {
        closeCallback?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
