//
//  BottomMaskView.swift
//  AnimatedTabBar
//
//  Created by Hayden on 2023/5/11.
//

import UIKit
import FigmaKit

/// 底部 TabBar 背后的模糊遮罩
class BottomMaskView: UIView {

    private lazy var blurView: VisualBlurView = {
        let blurView = VisualBlurView()
        blurView.fillColor = UIColor.ud.bgFloat
        blurView.fillOpacity = 0.85
        blurView.blurRadius = 40.0
        return blurView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(blurView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = bounds
    }
}
