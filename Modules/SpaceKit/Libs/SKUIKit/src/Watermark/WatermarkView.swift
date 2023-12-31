//
//  WatermarkView.swift
//  SpaceKit
//
//  Created by Gill on 2020/4/1.
//

import UIKit

class WatermarkView: UIView {

    public init(markText: String = "") {
        super.init(frame: .zero)
        self._makeWatermarkView(text: markText)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// 参考 Lark 水印方案。https://bytedance.feishu.cn/docs/doccn8rKCOZ4sxQoxM4oND6Ikig#
    private func _makeWatermarkView(text: String,
                                    textColor: UIColor = UIColor.ud.N500,
                                    textAlpha: CGFloat = 0.1,
                                    fillColor: UIColor? = nil) {
        let rect = CGRect(x: 0, y: 0, width: SKDisplay.mainScreenBounds.width, height: SKDisplay.mainScreenBounds.height)
        self.frame = rect

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: textColor]
        let drawedText = NSAttributedString(string: text, attributes: attrs)
        let textSize = drawedText.boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            context: nil).size
        let angle: CGFloat = 15
        let padding: CGFloat = 80.0
        let height: CGFloat = 80
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = height
        var rowCount = 0

        while currentHeight < rect.height + height * 2 {
            currentWidth = 0
            while currentWidth < rect.width {
                let piAngle = angle * CGFloat.pi / 180.0
                var drawPoint = CGPoint(x: currentWidth, y: currentHeight - currentWidth * tan(piAngle))
                if rowCount % 2 == 1 {
                    drawPoint.y -= textSize.width * sin(piAngle)
                    drawPoint.x += textSize.width * cos(piAngle)
                }
                let textLayer = CATextLayer()
                textLayer.contentsScale = SKDisplay.scale
                textLayer.string = drawedText
                textLayer.anchorPoint = CGPoint.zero
                textLayer.frame = CGRect(origin: .zero, size: textSize)
                let transfrom = CGAffineTransform(rotationAngle: -angle * .pi / 180)
                .concatenating(CGAffineTransform(translationX: drawPoint.x, y: drawPoint.y - textSize.height / 2))
                textLayer.transform = CATransform3DMakeAffineTransform(transfrom)
                textLayer.opacity = Float(textAlpha)
                layer.addSublayer(textLayer)

                currentWidth += textSize.width + padding
            }
            currentHeight += height
            rowCount += 1
        }

        if let fillColor = fillColor {
            backgroundColor = fillColor
        }
    }
}
