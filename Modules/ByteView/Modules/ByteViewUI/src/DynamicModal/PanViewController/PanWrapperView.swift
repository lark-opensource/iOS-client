//
//  ContainerWarpView.swift
//  ByteRtcRenderDemo
//
//  Created by huangshun on 2019/10/10.
//  Copyright © 2019 huangshun. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class PanWrapperView: UIView {

    private let topCornerRadius: CGFloat = 12

    lazy var barView: UIView = {
        let barView = UIView(frame: CGRect.zero)
        barView.clipsToBounds = true
        barView.layer.cornerRadius = topCornerRadius
        return barView
    }()

    lazy var contentView: UIView = {
        let contentView = UIView(frame: CGRect.zero)
        return contentView
    }()

    lazy var foregroundMaskView: UIView = {
        let foregroundView = UIView(frame: .zero)
        foregroundView.layer.masksToBounds = true
        foregroundView.isHidden = true
        return foregroundView
    }()

    lazy var icon: UIView = {
        let icon = UIView(frame: CGRect.zero)
        icon.layer.cornerRadius = 2
        icon.clipsToBounds = true
        return icon
    }()

    lazy var bottomView: UIView = {
        let bottomView = UIView(frame: CGRect.zero)
        return bottomView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initSubView() {
        barView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 40, height: 4))
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
        }

        addSubview(barView)
        barView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(24)
        }

        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(12)
        }

        addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(80)
            make.top.equalTo(snp.bottom)
        }

        addSubview(foregroundMaskView)
        foregroundMaskView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(topCornerRadius)
        }
    }

    func configTopCorner() {
        if barView.isHidden {
            self.layer.cornerRadius = barView.layer.cornerRadius
            self.layer.masksToBounds = true
            self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            foregroundMaskView.layer.cornerRadius = 0
            contentView.snp.updateConstraints { (make) in
                make.top.equalToSuperview()
            }
        } else {
            self.layer.cornerRadius = 0
            foregroundMaskView.layer.cornerRadius = topCornerRadius
            contentView.snp.updateConstraints { (make) in
                make.top.equalToSuperview().offset(12)
            }
        }
    }
}
