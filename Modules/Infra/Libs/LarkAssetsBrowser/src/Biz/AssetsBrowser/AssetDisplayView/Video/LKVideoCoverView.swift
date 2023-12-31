//
//  LKVideoCoverView.swift
//  LarkUIKit
//
//  Created by Yuguo on 2018/8/16.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor

protocol LKVideoCoverViewDelegate: AnyObject {
    func retryFetchVideo()
}

final class LKVideoCoverView: UIImageView {
    weak var delegate: LKVideoCoverViewDelegate?
    private let backView = UIView()
    private let tipImageView = UIImageView(image: Resources.asset_video_invalid)
    private let tipLabel = UILabel.lu.labelWith(fontSize: 12, textColor: UIColor.white)
    private lazy var retryFetchTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(retryFetchTapHandler))
        tap.isEnabled = false
        return tap
    }()

    init() {
        super.init(image: nil)
        self.contentMode = .scaleAspectFit

        self.isUserInteractionEnabled = true

        backView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.43)
        self.addSubview(backView)
        self.backView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        self.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.lessThanOrEqualTo(self).offset(20)
            make.right.lessThanOrEqualTo(self).offset(-20)
        }

        containerView.addSubview(tipImageView)
        tipImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        tipLabel.numberOfLines = 0
        tipLabel.textAlignment = .center
        containerView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(tipImageView.snp.bottom).offset(16)
            make.left.right.bottom.equalToSuperview()
        }

        self.setVideo(isValid: true)
        self.backView.addGestureRecognizer(retryFetchTap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func retryFetchTapHandler() {
        self.backView.isHidden = true
        self.tipImageView.isHidden = true
        self.tipLabel.isHidden = true
        retryFetchTap.isEnabled = false
        self.delegate?.retryFetchVideo()
    }

    func setVideo(isValid: Bool, tip: String? = nil) {
        self.backView.isHidden = isValid
        self.tipImageView.isHidden = isValid
        self.tipLabel.isHidden = isValid
        // "视频已被撤回或失效"
        self.tipLabel.text = tip ?? BundleI18n.LarkAssetsBrowser.Lark_Legacy_AssetVideoInvalid
        retryFetchTap.isEnabled = false
    }

    func setVideoFetchFail() {
        self.backView.isHidden = false
        self.tipImageView.isHidden = false
        self.tipLabel.isHidden = false
        // "视频无法获取，请点击重试"
        self.tipLabel.text = BundleI18n.LarkAssetsBrowser.Lark_Chat_VideoUrlErrorMessageMobile
        retryFetchTap.isEnabled = true
    }
}
