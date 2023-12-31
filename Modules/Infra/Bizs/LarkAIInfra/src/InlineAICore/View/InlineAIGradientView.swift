//
//  InlineAIGradientView.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/5/23.
//  


import UIKit

class InlineAIGradientView: UIView {

    enum ColorDirection {
        case horizental
        case vertical
    }
    
    var direction: ColorDirection = .vertical
    var colors: [UIColor] = []
    
    required convenience init(direction: ColorDirection, colors: [UIColor]) {
        self.init(frame: .zero)
        self.direction = direction
        self.colors = colors
        self.setupLayer()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupLayer() {
        let layer = CAGradientLayer()
        layer.position = self.center
        layer.bounds = self.bounds
        self.layer.addSublayer(layer)
        layer.ud.setColors(self.colors)
        layer.locations = [0, 1]
        if self.direction == .vertical {
            layer.startPoint = CGPoint(x: 0.5, y: 0)
            layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        } else {
            layer.startPoint = CGPoint(x: 0, y: 0.5)
            layer.endPoint = CGPoint(x: 1, y: 0.5)
        }
        layer.needsDisplayOnBoundsChange = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                layer.position = self.bounds.center
                layer.bounds = self.bounds
                CATransaction.commit()
            }
        }
    }

}
