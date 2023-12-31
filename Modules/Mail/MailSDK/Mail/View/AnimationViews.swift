//
//  AnimationView.swift
//  Common
//
//  Created by Songwen Ding on 2018/1/7.
//

import UIKit
import Lottie

enum AnimationType: Int {
    case typeLoading
    case spin
}

@objcMembers
final class AnimationViews {

    class var spinAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .spin)
    }

    class func animationViewByType(type: AnimationType) -> LOTAnimationView {
        var resourceName: String
        switch type {
        case .typeLoading:
            resourceName = "loading" // 废弃
        case .spin:
            resourceName = "spin"
        }

        guard let path = I18n.resourceBundle.path(forResource: "Lottie/\(resourceName)", ofType: "json")  else {
            return LOTAnimationView()
        }
        let view = LOTAnimationView(filePath: path)
        view.backgroundColor = UIColor.clear
        view.autoReverseAnimation = false
        view.loopAnimation = true
        return view
    }
}
