//
//  WebRetryView.swift
//  LarkWebViewController
//
//  Created by 新竹路车神 on 2020/12/24.
//

import UIKit
import SnapKit

/// 网页崩溃使用的重试试图
public final class WebRetryView: UIView {

    private lazy var midView = UIView()

    private lazy var icon: UIImageView = {
        let image = UIImageView(image: BundleResources.LarkLive.webFailed)
        image.contentMode = .scaleAspectFit
        image.isUserInteractionEnabled = false
        return image
    }()

    private lazy var bigTips: UILabel = {
        let label = UILabel()
        label.text = "Lark_OpenPlatform_CantOpenTtl"
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var reloadTips: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.primaryContentDefault
        label.text = "Lark_OpenPlatform_ClickRefreshLink"
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var rebotTips: UILabel = {
        let label = UILabel()
        label.text = "Lark_OpenPlatform_RestartDesc"
        label.textColor = UIColor.ud.textCaption
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.numberOfLines = 0
        return label
    }()

    private let block: os_block_t

    public init(block: @escaping os_block_t) {
        self.block = block
        super.init(frame: .zero)
        midView.isUserInteractionEnabled = false
        setupViews()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapFunction)))
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(midView)
        midView.addSubview(icon)
        midView.addSubview(bigTips)
        midView.addSubview(reloadTips)
        midView.addSubview(rebotTips)
        midView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
        }
        icon.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }
        bigTips.snp.makeConstraints { (make) in
            make.top.equalTo(icon.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        reloadTips.snp.makeConstraints { (make) in
            make.top.equalTo(bigTips.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        rebotTips.snp.makeConstraints { (make) in
            make.top.equalTo(reloadTips.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    @objc
    private func tapFunction() {
        block()
    }
}
