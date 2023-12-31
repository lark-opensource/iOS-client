//
//  BackgroundView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/28.
//

import UIKit
import UniverseDesignColor

class BackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static let layer0Colors: [UIColor] = [
        UIColor.dynamic(light: UIColor.ud.rgb(0xDCE4EC), dark: UIColor.ud.rgb(0x31373E)),
        UIColor.dynamic(light: UIColor.ud.rgb(0xDCE4EC), dark: UIColor.ud.rgb(0x31373E)),
        UIColor.ud.bgBody,
        UIColor.ud.bgBody
    ]
    
    private static let layer1Colors: [UIColor] = [
        UIColor.ud.bgBody.withAlphaComponent(0.54),
        UIColor.ud.bgBody.withAlphaComponent(0)
    ]
    
    private static let layer2Colors: [UIColor] = [
        UIColor.ud.bgBody.withAlphaComponent(0.54),
        UIColor.ud.bgBody.withAlphaComponent(0)
    ]
    
    private lazy var layer0: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0, 0.1, 0.72, 1]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 0, y: 1)
        return layer
    }()
    
    
    /// 生成一个径向渐变的 Layer
    /// - Parameters:
    ///   - colors: 渐变色，从圆心到圆周
    ///   - centerPercent: 圆心的比例位置 x=center.x/layer.width y=center.y/layer.height
    ///   - radiusPercent: 半径的比例 x=radius.x/layer.width y=radius.y/layer.height
    /// - Returns: CAGradientLayer
    private static func gernaerateGradientLayer(centerPercent: CGPoint, radiusPercent: CGPoint) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.type = .radial
        layer.locations = [0.0, 1.0]
        layer.startPoint = CGPoint(x: centerPercent.x, y: centerPercent.y)
        layer.endPoint = CGPoint(x: centerPercent.x + radiusPercent.x , y: centerPercent.y + radiusPercent.y)
        return layer
    }
    
    private lazy var layer1: CAGradientLayer = {
        return BackgroundView.gernaerateGradientLayer(centerPercent: CGPoint(x: 0.7, y: 0.0), radiusPercent: CGPointMake(0.75, 0.35))
    }()
    
    private lazy var layer2: CAGradientLayer = {
        return BackgroundView.gernaerateGradientLayer(centerPercent: CGPoint(x: 0.0, y: 0.45), radiusPercent: CGPointMake(0.8, 0.35))
    }()
    
    private func setup() {
        self.layer.addSublayer(layer0)
        self.layer.addSublayer(layer1)
        self.layer.addSublayer(layer2)
        
        updateDarkMode()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer0.frame = self.bounds
        layer1.frame = self.bounds
        layer2.frame = self.bounds
    }
    
    @objc
    func updateDarkMode() {
        layer0.ud.setColors(Self.layer0Colors)
        layer1.ud.setColors(Self.layer1Colors)
        layer2.ud.setColors(Self.layer2Colors)
    }
}
