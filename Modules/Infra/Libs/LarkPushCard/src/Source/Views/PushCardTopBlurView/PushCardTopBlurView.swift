//
//  PushCardTopBlurView.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/10/20.
//

import Foundation
import UIKit
import FigmaKit

final class PushCardTopBlurView: UIView {
    private lazy var blurView: VisualBlurView = VisualBlurView()
    private lazy var gradientMaskLayer: CAGradientLayer = {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.locations = [0, 0.6, 1]
        return gradientMaskLayer
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.isHidden = true
        self.addSubview(blurView)

        blurView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.top).offset(10)
        }

        blurView.fillColor = Colors.bgColor
        blurView.fillOpacity = 0.1
        blurView.blurRadius = 8

        let startColor = Colors.bgColor.withAlphaComponent(1)
        let midColor = Colors.bgColor.withAlphaComponent(1)
        let endColor = Colors.bgColor.withAlphaComponent(0)
        gradientMaskLayer.ud.setColors([startColor, midColor, endColor], bindTo: self)
        blurView.layer.mask = gradientMaskLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = self.superview else { return }
        self.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientMaskLayer.frame = blurView.frame
    }
}
