//
//  blurMaskView.swift
//  LarkChat
//
//  Created by sniper on 2018/11/20.
//

import Foundation
import UIKit

final class BlurMaskView: UIView {

    override public class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    var shapeLayer: CAShapeLayer {
        // swiftlint:disable force_cast
        return layer as! CAShapeLayer
        // swiftlint:enable force_cast
    }
}
