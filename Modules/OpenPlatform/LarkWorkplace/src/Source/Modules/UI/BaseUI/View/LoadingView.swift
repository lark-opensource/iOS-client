//
//  LoadingView.swift
//  LarkWorkplace
//
//  Created by tujinqiu on 2020/2/6.
//

import UIKit
import Lottie

// 不应该出现强解包，需要业务调整
// swiftlint:disable force_unwrapping

final class LoadingView: UIView {

    let animationView: LOTAnimationView = {
        let jsonPath = BundleConfig.LarkWorkplaceBundle.path(
            forResource: "data",
            ofType: "json",
            inDirectory: "Lottie"
        )
        let view = jsonPath.flatMap { LOTAnimationView(filePath: $0) } ?? LOTAnimationView()
        return view
    }()

    override init(frame: CGRect) {
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
// 不应该出现强解包，需要业务调整
// swiftlint:enable force_unwrapping
