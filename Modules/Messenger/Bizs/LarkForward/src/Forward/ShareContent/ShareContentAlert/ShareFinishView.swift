//
//  ShareFinishView.swift
//  Lark
//
//  Created by zc09v on 2017/12/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation

final class ShareFinishView: UIView {
    private lazy var icon: UIImageView = UIImageView(image: Resources.shareOk)
    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkForward.Lark_Legacy_ShareSuccess
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(icon)
        self.addSubview(label)
        icon.snp.makeConstraints { (make) in
            make.top.equalTo(30)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60)
            make.left.equalTo(102.5)
            make.right.equalTo(-102.5)
        }
        label.snp.makeConstraints { (make) in
            make.top.equalTo(icon.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-28)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
