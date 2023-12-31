//
//  FeedFilterHeaderView.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/8.
//

import Foundation
import UIKit
import LarkUIKit

final class FeedFilterHeaderView: UIView {
    typealias EditBlock = () -> Void
    var editBlock: EditBlock?
    let height: CGFloat = 56

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkFeed.Lark_Core_FeedFilter_Tab
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        return label
    }()

    private lazy var editButton: UIButton = {
        let button = UIButton(type: .custom)
        let image: UIImage
        if Display.pad {
            image = Resources.icon_setting_outlined_ipad
        } else {
            image = Resources.sidebar_filtertab_setting
        }
        button.setImage(image, for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.right.equalToSuperview().inset(60)
        }

        addSubview(editButton)
        editButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(19)
            make.width.height.equalTo(30)
            make.centerY.equalTo(titleLabel)
        }
        editButton.addTarget(self, action: #selector(editAction), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func editAction() {
        self.editBlock?()
    }

    func setTitleLabelFontSize(_ size: CGFloat) {
        titleLabel.font = UIFont.systemFont(ofSize: size, weight: .medium)
    }
}
