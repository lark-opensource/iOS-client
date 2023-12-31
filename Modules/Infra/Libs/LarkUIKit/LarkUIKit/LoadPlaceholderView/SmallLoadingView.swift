//
//  SmallLoadingView.swift
//  LarkUIKitDemo
//
//  Created by K3 on 2018/10/16.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie

public final class SmallLoadingView: UIView {
    public let animationView: LOTAnimationView = {
        let jsonPath = BundleConfig.LarkUIKitBundle.path(
            forResource: "data",
            ofType: "json",
            inDirectory: "Lottie/small_loading")
        let view = jsonPath.flatMap { LOTAnimationView(filePath: $0) } ?? LOTAnimationView()
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        animationView.loopAnimation = true
        addSubview(animationView)
        animationView.snp.makeConstraints { (make ) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
