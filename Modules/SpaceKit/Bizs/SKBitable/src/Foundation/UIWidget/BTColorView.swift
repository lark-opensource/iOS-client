//
//  BTColorView.swift
//  SKBitable
//
//  Created by yinyuan on 2022/12/6.
//

import Foundation

final class BTColorView: UIView {
    
    private lazy var gradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 0)
       return layer
    }()
    
    public var progressColor: BTColor? {
        didSet {
            updateColor()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.bounds
    }
    
    private func updateColor() {
        guard let progressColor = progressColor else {
            gradientLayer.removeFromSuperlayer()
            return
        }
        
        if gradientLayer.superlayer == nil {
            self.layer.addSublayer(gradientLayer)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true) // 禁用切换动画
        switch progressColor.type {
        case .multi:
            gradientLayer.backgroundColor = nil
            var colors: [CGColor] = []
            var locations: [NSNumber] = []
            if let gradientColorList = progressColor.color {
                let colorWidth = 1.0 / CGFloat(gradientColorList.count)
                for i in 0..<gradientColorList.count {
                    let colorStr = gradientColorList[i]
                    let color = UIColor.docs.rgb(colorStr).cgColor
                    colors.append(color)
                    colors.append(color)
                    let locationBegin = CGFloat(i) * colorWidth
                    let locationEnd = CGFloat(i + 1) * colorWidth
                    locations.append(NSNumber(floatLiteral: locationBegin))
                    locations.append(NSNumber(floatLiteral: locationEnd))
                }
            }
            gradientLayer.colors = colors
            gradientLayer.locations = locations
        case .gradient:
            gradientLayer.backgroundColor = nil
            gradientLayer.locations = nil
            gradientLayer.colors = progressColor.color?.map({
                return UIColor.docs.rgb($0).cgColor
            }) ?? []
        case .none:
            gradientLayer.backgroundColor = UIColor.clear.cgColor
            gradientLayer.colors = nil
        }
        CATransaction.commit()
    }
    
}
