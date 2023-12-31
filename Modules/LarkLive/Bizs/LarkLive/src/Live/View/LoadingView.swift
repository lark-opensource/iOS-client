//
//  LoadingView.swift
//  ByteView
//
//  Created by kiri on 2020/11/6.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Lottie
import LarkUIKit

class LoadingView: UIView {
    enum Style {
        case white
        case blue
    }

    private let animationView: LOTAnimationView
    convenience init(style: Style) {
        self.init(frame: .zero, style: style)
    }

    init(frame: CGRect, style: Style) {
        switch style {
        case .white:
            animationView = SmallLoadingView(frame: frame).animationView
        case .blue:
            animationView = LOTAnimationView(name: "videochat_loading_colorfulBlue", bundle: .localResources)
        }
        animationView.loopAnimation = true
        super.init(frame: frame)
        addSubview(animationView)
        animationView.snp.makeConstraints { (make ) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play() {
        animationView.play()
    }

    func stop() {
        animationView.stop()
    }
}
