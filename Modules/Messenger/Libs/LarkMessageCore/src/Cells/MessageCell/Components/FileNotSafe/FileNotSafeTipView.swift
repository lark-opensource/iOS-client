//
//  FileNotSafeTipView.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/16.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit

public class FileNotSafeTipView: UIView {
    lazy var label: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkMessageCore.Lark_IM_FileRiskyMightHarmDevice_Text
        label.textColor = UIColor.ud.colorfulOrange
        label.font = UIFont.ud.caption1
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()

    lazy var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.risk_file_tip
        imageView.snp.makeConstraints { make in
            make.width.equalTo(UIFont.ud.caption1.rowHeight)
            make.height.equalTo(UIFont.ud.caption1.rowHeight)
        }
        return imageView
    }()

    public init() {
        super.init(frame: .zero)
        self.addSubview(icon)
        self.addSubview(label)
        icon.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(4)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
