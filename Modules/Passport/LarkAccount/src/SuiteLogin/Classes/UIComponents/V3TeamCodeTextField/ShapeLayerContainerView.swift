//
//  ShapeLayerContainerView.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/5.
//

import Foundation
import LKCommonsLogging

class ShapeLayerContainerView: UIView {

    private static let logger = Logger.plog(ShapeLayerContainerView.self, category: "SuiteLogin.ShapeLayerContainerView")

    var shapeLayer: CAShapeLayer? {
        return layer as? CAShapeLayer
    }

    public override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        guard let shapeLayer = layer as? CAShapeLayer else {
            return
        }
        shapeLayer.contentsScale = UIScreen.main.scale
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
