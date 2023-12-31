//
//  LKSplitPanMaskView.swift
//  LarkSplitViewController
//
//  Created by 李晨 on 2021/3/30.
//

import Foundation
import LarkBlur
import UIKit
import SnapKit

final class SplitPanMaskView: UIView {
    let blurView = LarkBlurEffectView()

    let contentView = UIView()

    init() {
        super.init(frame: .zero)

        self.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.addSubview(blurView)
        blurView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(view: UIView?) {
        self.contentView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        guard let view = view else {
            return
        }
        self.contentView.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
