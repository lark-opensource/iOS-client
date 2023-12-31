//
//  StripBackgroundView.swift
//  Calendar
//
//  Created by pluto on 2023/1/31.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignCardHeader

final class StripBackgroundView: UIView {

    private let backgroundLayer = CAReplicatorLayer()
    private let scripLayer = CALayer()
    private let cardBgView = UDCardHeader(colorHue: .green)

    init(rect: CGRect) {
        super.init(frame: rect)
        backgroundColor = UIColor.ud.bgBody
        backgroundLayer.frame = rect
        backgroundLayer.instanceCount = Int(self.bounds.width + self.bounds.height) / 15 + 1
        
        addSubview(cardBgView)
        cardBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        layoutStrip(replicatorLayer: backgroundLayer, instanceLayer: scripLayer)
        drawStrip(backgroundColor:  .ud.LightBgGreen, scripColor: .ud.StripeGreen)
        self.clipsToBounds = true
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutStrip(replicatorLayer: CAReplicatorLayer, instanceLayer: CALayer) {
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(15, 0, 0)
        self.layer.addSublayer(replicatorLayer)

        instanceLayer.anchorPoint = CGPoint(x: 1, y: 0)
        instanceLayer.frame = CGRect(x: 1, y: 0, width: 5, height: self.frame.height * 1.5)
        let transform = CGAffineTransform(rotationAngle: .pi / 4)
        instanceLayer.setAffineTransform(transform)
        backgroundLayer.addSublayer(instanceLayer)
    }

    private func drawStrip(backgroundColor: UIColor, scripColor: UIColor) {
        backgroundLayer.ud.setBackgroundColor(backgroundColor, bindTo: self)
        scripLayer.ud.setBackgroundColor(scripColor, bindTo: self)
    }
}
