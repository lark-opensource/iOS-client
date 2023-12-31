//
//  SearchTextField.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/25.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import SKResource
import UniverseDesignInput
/*
class SearchTextField: UIControl {

    fileprivate(set) var input: UDTextField!

    init() {
        super.init(frame: CGRect.zero)

        self.backgroundColor = UIColor.ud.N100
        self.layer.cornerRadius = 3
        self.layer.masksToBounds = true

        let icon = UIImageView()
        icon.image = BundleResources.SKResource.Common.Search.search_ico
        self.addSubview(icon)
        icon.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: 14, height: 14))
            make.left.equalTo(6)
            make.centerY.equalToSuperview()
        })

        let input = UDTextField()
        var config = UDTextFieldUIConfig()
        config.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.medium)

        input.config = config
        input.input.clearButtonMode = .always
        input.input.returnKeyType = .search
        self.addSubview(input)
        input.snp.makeConstraints({ make in
            make.left.equalTo(icon.snp.right).offset(6).priority(.high)
            make.right.top.bottom.equalToSuperview()
        })
        self.input = input
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
*/
