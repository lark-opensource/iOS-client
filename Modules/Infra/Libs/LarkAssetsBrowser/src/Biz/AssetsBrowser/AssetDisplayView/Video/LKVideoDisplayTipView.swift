//
//  LKVideoDisplayTipView.swift
//  LarkUIKit
//
//  Created by Yuguo on 2018/8/16.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor

public final class LKVideoDisplayTipView: UIView {
    public let tipLabel: UILabel
    public var continueBtnClickCallback: (() -> Void)?

    public init(videoSize: Float?) {
        tipLabel = UILabel.lu.labelWith(fontSize: 12, textColor: UIColor.white)
        super.init(frame: .zero)

        let backBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.addSubview(backBlurView)
        backBlurView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 0
        if let videoSize = videoSize {
            let formatSize = String(format: "%.2fM", videoSize)
            tipLabel.text = String(format: BundleI18n.LarkAssetsBrowser.Lark_Legacy_AssetVideoPlayNoWifiVideoSizeTip, formatSize)
        } else {
            tipLabel.text = BundleI18n.LarkAssetsBrowser.Lark_Legacy_AssetVideoPlayNoWifiTip
        }
        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.snp.centerY).offset(-15)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }

        let cancelButton = UIButton(type: .custom)
        cancelButton.layer.cornerRadius = 4
        cancelButton.layer.masksToBounds = true
        cancelButton.layer.borderColor = UIColor.white.cgColor
        cancelButton.layer.borderWidth = 1
        cancelButton.setTitle(BundleI18n.LarkAssetsBrowser.Lark_Legacy_Cancel, for: .normal)
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked), for: .touchUpInside)
        self.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.centerY).offset(15)
            make.right.equalTo(self.snp.centerX).offset(-15)
            make.size.equalTo(CGSize(width: 64, height: 28))
        }

        let continueButton = UIButton(type: .custom)
        continueButton.backgroundColor = UIColor.ud.colorfulBlue
        continueButton.layer.cornerRadius = 4
        continueButton.layer.masksToBounds = true
        continueButton.setTitle(BundleI18n.LarkAssetsBrowser.Lark_Legacy_ContinueBtn, for: .normal)
        continueButton.setTitleColor(UIColor.white, for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        continueButton.addTarget(self, action: #selector(continueButtonClicked), for: .touchUpInside)
        self.addSubview(continueButton)
        continueButton.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.centerX).offset(15)
            make.top.size.equalTo(cancelButton)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func cancelButtonClicked() {
        self.removeFromSuperview()
    }

    @objc
    private func continueButtonClicked() {
        self.removeFromSuperview()
        continueBtnClickCallback?()
    }
}
