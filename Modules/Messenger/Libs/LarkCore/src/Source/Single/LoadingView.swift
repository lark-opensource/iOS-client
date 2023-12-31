//
//  LoadingView.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/25.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

public final class CoreLoadingView: UIView {

    fileprivate var indicator: UIActivityIndicatorView!

    public init() {
        super.init(frame: CGRect.zero)

        // 容器
        let loadingWrapper = UIView()
        self.addSubview(loadingWrapper)
        loadingWrapper.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        })

        // indicator
        let indicator = UIActivityIndicatorView()
        indicator.style = .white
        indicator.color = UIColor.ud.iconN3
        loadingWrapper.addSubview(indicator)
        indicator.snp.makeConstraints({ make in
            make.left.equalToSuperview()
            make.top.bottom.equalTo(6)
        })
        self.indicator = indicator

        // label
        let infoLabel = UILabel()
        infoLabel.text = BundleI18n.LarkCore.Lark_Legacy_InLoading
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.textColor = UIColor.ud.textTitle
        loadingWrapper.addSubview(infoLabel)
        infoLabel.snp.makeConstraints({ make in
            make.left.equalTo(indicator.snp.right).offset(4)
            make.right.equalToSuperview()
            make.centerY.equalTo(indicator)
        })
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func show() {
        self.isHidden = false
        self.indicator.startAnimating()
    }

    public func hide() {
        self.indicator.stopAnimating()
        self.isHidden = true
    }
}
