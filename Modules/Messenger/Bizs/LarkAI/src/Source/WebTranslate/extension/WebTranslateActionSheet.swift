//
//  WebTranslateActionSheet.swift
//  LarkWeb
//
//  Created by JackZhao on 2020/8/24.
//

import UIKit
import Foundation
import EENavigator
import LarkMessengerInterface

final class WebTranslateActionSheetItem: UIView {
    var icon: UIImageView = {
        let icon = UIImageView()
        icon.isHidden = true
        icon.image = Resources.web_icon_done
        return icon
    }()

    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        return label
    }()

    var isSelected: Bool

    init(frame: CGRect,
         text: String,
         font: UIFont,
         isSelected: Bool = false) {

        self.isSelected = isSelected
        super.init(frame: frame)
        self.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.top.equalTo(20)
            make.width.height.equalTo(24)
            make.right.equalTo(-30)
            make.centerY.equalToSuperview()
        }
        icon.isHidden = !isSelected

        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        label.text = text
        label.font = font
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
