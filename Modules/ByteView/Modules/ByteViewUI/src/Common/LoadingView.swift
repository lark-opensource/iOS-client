//
//  LoadingView.swift
//  ByteView
//
//  Created by kiri on 2020/11/6.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Lottie
import UniverseDesignTheme

public final class LoadingView: UIView {
    private let animationView: LOTAnimationView
    public convenience init(style: Style) {
        self.init(frame: .zero, style: style)
    }

    public init(frame: CGRect, style: Style) {
        switch style {
        case .white:
            animationView = LOTAnimationView(name: "small_loading", bundle: .localResources)
        case .blue:
            if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                animationView = LOTAnimationView(name: "videochat_loading_blue_dark", bundle: .localResources)
            } else {
                animationView = LOTAnimationView(name: "videochat_loading_blue", bundle: .localResources)
            }
        case .grey:
            animationView = LOTAnimationView(name: "videochat_loading_grey", bundle: .localResources)
        }
        animationView.loopAnimation = true
        super.init(frame: frame)
        addSubview(animationView)
        animationView.snp.makeConstraints { (make ) in
            make.edges.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func play() {
        animationView.playIfNeeded()
    }

    public func stop() {
        animationView.stopIfNeeded()
    }

    public enum Style {
        case white
        case blue
        case grey
    }
}
