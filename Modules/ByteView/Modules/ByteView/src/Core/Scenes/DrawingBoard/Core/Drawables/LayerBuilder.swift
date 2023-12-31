//
//  LayerBuilder.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/6.
//

import Foundation
import QuartzCore
import UIKit

class LayerBuilder {

    // layer设置颜色时，需要绑定一个view
    private weak var bindView: UIView?

    func setBindView(view: UIView) {
        bindView = view
    }

    func buildLayer(drawable: SketchShape) -> CAShapeLayer? {
        let layer: CAShapeLayer?
        switch drawable {
        case let oval as OvalDrawable:
            layer = build(oval: oval)
        case let rect as RectangleDrawable:
            layer = build(rectangle: rect)
        case let arrow as ArrowDrawable:
            layer = build(arrow: arrow)
        case let pencil as PencilPathDrawable:
            layer = build(pencil: pencil)
        default:
            assertionFailure("unsupported shapedrawable \(drawable)")
            layer = nil
        }
        return layer
    }

    func buildTextLayer(drawable: NicknameDrawable) -> CATextLayer? {
        return build(nickname: drawable)
    }

    private func build(oval: OvalDrawable) -> CAShapeLayer {
        let layer = CAShapeLayer()
        if let bindView = bindView {
            layer.ud.setStrokeColor(oval.style.color, bindTo: bindView)
        } else {
            layer.strokeColor = oval.style.color.cgColor
        }
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = oval.style.size

        layer.path = oval.path
        return layer
    }

    private func build(rectangle: RectangleDrawable) -> CAShapeLayer {
        let layer = CAShapeLayer()
        if let bindView = bindView {
            layer.ud.setStrokeColor(rectangle.style.color, bindTo: bindView)
        } else {
            layer.strokeColor = rectangle.style.color.cgColor
        }
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = rectangle.style.size

        layer.path = rectangle.path

        return layer
    }

    private func build(arrow: ArrowDrawable) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.strokeColor = nil
        if let bindView = bindView {
            layer.ud.setFillColor(arrow.style.color, bindTo: bindView)
        } else {
            layer.fillColor = arrow.style.color.cgColor
        }
        layer.lineWidth = 0
        layer.path = arrow.path
        return layer
    }

    func build(pencil: PencilPathDrawable) -> CAShapeLayer {
        let layer = CAShapeLayer()
        if let bindView = bindView {
            layer.ud.setStrokeColor(pencil.style.color, bindTo: bindView)
        } else {
            layer.strokeColor = pencil.style.color.cgColor
        }
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = pencil.style.size
        layer.lineCap = pencil.style.pencilType == .marker ? .butt : .round

        layer.path = pencil.path
        return layer
    }

    private func build(nickname: NicknameDrawable) -> CATextLayer {
        let layer = CATextLayer()
        let textStyle = nickname.style
        layer.font = CGFont(textStyle.font.fontName as CFString)
        layer.fontSize = textStyle.font.pointSize
        layer.string = nickname.text
        if let bindView = bindView {
            layer.ud.setForegroundColor(textStyle.textColor, bindTo: bindView)
            layer.ud.setBackgroundColor(textStyle.backgroundColor, bindTo: bindView)
            layer.contentsScale = bindView.vc.displayScale
        } else {
            layer.ud.setForegroundColor(textStyle.textColor)
            layer.ud.setBackgroundColor(textStyle.backgroundColor)
            layer.contentsScale = 1.0
        }
        layer.cornerRadius = textStyle.cornerRadius
        layer.masksToBounds = true
        layer.alignmentMode = .center
        layer.truncationMode = .end
        var size = nickname.text.size(withAttributes: [NSAttributedString.Key.font: textStyle.font])
        size.width = min(size.width + 8, 200)
        size.height += 2
        layer.frame = CGRect(origin: CGPoint(x: nickname.leftCenter.x,
                                             y: nickname.leftCenter.y - size.height / 2),
                             size: size)
        layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        return layer
    }
}
