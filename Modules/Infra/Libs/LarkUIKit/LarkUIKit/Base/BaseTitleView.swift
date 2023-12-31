//
//  BaseTitleView.swift
//  Lark
//
//  Created by 吴子鸿 on 2017/8/1.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

open class BaseTitleView: UIView {
    open lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = self.titleFont
        label.textAlignment = .center
        return label
    }()

    public var titleFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium) {
        didSet {
            self.nameLabel.font = self.titleFont
        }
    }

    public init() {
        super.init(frame: .zero)
        self.addSubview(nameLabel)

        nameLabel.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setTitle(title: String) {
        nameLabel.text = title
    }

    public func setTitleColor(color: UIColor) {
        nameLabel.textColor = color
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        self.nameLabel.textColor = self.tintColor
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: UIView.layoutFittingExpandedSize.height
        )
    }
}
