//
//  AppDetailViewController+GradientView.swift
//  LarkAppCenter
//
//  Created by yuanping on 2019/5/7.
//
import UniverseDesignColor

class AppDetailGradientView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let startColor = UIColor.ud.bgBody.withAlphaComponent(0)
        let endColor = UIColor.ud.bgBody
        let locations: [CGFloat] = [0, 1]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: [startColor.cgColor, endColor.cgColor] as CFArray, locations: locations) else { return }
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: bounds.minX, y: bounds.maxY * 0.55),
                                   end: CGPoint(x: bounds.minX, y: bounds.maxY),
                                   options: .drawsAfterEndLocation)
    }
}
