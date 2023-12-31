//
//  LKVideoDisplayHeaderView.swift
//  LarkUIKit
//
//  Created by Yuguo on 2018/8/16.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

final class LKVideoDisplayHeaderView: UIView {
    let closeButton = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)

        let backView = GradientView()
        backView.backgroundColor = UIColor.clear
        backView.colors = [UIColor.black.withAlphaComponent(0.5), UIColor.black.withAlphaComponent(0)]
        backView.locations = [0.0, 1.0]
        backView.direction = .vertical
        self.addSubview(backView)
        backView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        closeButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        closeButton.setImage(Resources.asset_video_close, for: .normal)
        self.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(14)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func remakeConstraintsBy(safeAreaInsets: UIEdgeInsets) {
        closeButton.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview().offset(safeAreaInsets.top / 2)
            make.left.equalTo(14)
        }
    }
}
