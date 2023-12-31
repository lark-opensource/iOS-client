//
//  LayerBuilder.swift
//  ByteView
//
//  Created by 阮明哲 on 2022/3/25.
//

import Foundation
import QuartzCore
import UIKit

class NoActionShapeLayer: CAShapeLayer, CALayerDelegate {
    override func action(forKey event: String) -> CAAction? {
        return nil
    }
}

class NoActionTextLayer: CATextLayer, CALayerDelegate {
    override func action(forKey event: String) -> CAAction? {
        return nil
    }
}

class NoActionRootLayer: CALayer, CALayerDelegate {
    override func action(forKey event: String) -> CAAction? {
        return nil
    }
}

class LayerBuilder {
    func buildLayer(drawable: WhiteboardShape) -> NoActionShapeLayer? {
        let layer: NoActionShapeLayer?
        switch drawable {
        case let vector as VectorShape:
            layer = build(vector: vector)
        default:
            assertionFailure("unsupported shapedrawable \(drawable)")
            layer = nil
        }
        return layer
    }

    func buildRecognizeTextLayer(drawable: WhiteboardShape) -> NoActionTextLayer? {
        let layer: NoActionTextLayer?
        switch drawable {
        case let recognizeText as TextDrawable:
            layer = build(recognizeText: recognizeText)
        default:
            assertionFailure("unsupported shapedrawable \(drawable)")
            layer = nil
        }
        return layer
    }

    func buildNicknameTextLayer(drawable: NicknameDrawable) -> NoActionTextLayer? {
        return build(nickname: drawable)
    }

    private func build(recognizeText: TextDrawable) -> NoActionTextLayer {
        let layer = NoActionTextLayer()
        layer.string = recognizeText.text
        layer.fontSize = CGFloat(recognizeText.fontSize)
        layer.font = CTFontCreateWithName(LayerBuilder.getFontName(recognizeText.fontWeight) as CFString, CGFloat(recognizeText.fontSize), nil)
        layer.truncationMode = .end
        layer.allowsFontSubpixelQuantization = false
        layer.contentsScale = WhiteboardView.displayScale
        // 默认原点在(0,0), 位置变换通过transform进行
        layer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: layer.preferredFrameSize())
        if let fillColor = recognizeText.fillColor {
            layer.foregroundColor = fillColor.cgColor
        }
        if let transform = recognizeText.transform {
            layer.transform = CATransform3DMakeAffineTransform(transform)
        }
        return layer
    }

    private func build(vector: VectorShape) -> NoActionShapeLayer {
        let layer = NoActionShapeLayer()
        if let strokeColor = vector.strokeColor {
            layer.strokeColor = strokeColor.cgColor
        }
        if let lineWidth = vector.lineWidth {
            layer.lineWidth = lineWidth
        }
        if let fillColor = vector.fillColor {
            layer.fillColor = fillColor.cgColor
        } else {
            layer.fillColor = UIColor.clear.cgColor
        }
        if let transform = vector.transform {
            layer.transform = CATransform3DMakeAffineTransform(transform)
        }
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.path = vector.path
        layer.contentsScale = WhiteboardView.displayScale
        return layer
    }

    private func build(nickname: NicknameDrawable) -> NoActionTextLayer {
        let layer = NoActionTextLayer()
        let textStyle = nickname.style
        layer.font = CGFont(textStyle.font.fontName as CFString)
        layer.fontSize = textStyle.font.pointSize
        layer.string = nickname.text
        layer.foregroundColor = textStyle.textColor.cgColor
        layer.backgroundColor = textStyle.backgroundColor.cgColor
        layer.contentsScale = WhiteboardView.displayScale
        layer.cornerRadius = textStyle.cornerRadius
        layer.masksToBounds = true
        layer.alignmentMode = .center
        layer.truncationMode = .end
        var size = nickname.text.size(withAttributes: [NSAttributedString.Key.font: textStyle.font])
        size.width = min(size.width + 8, 200)
        size.height += 2
        layer.frame = CGRect(origin: CGPoint(x: nickname.position.x,
                                             y: nickname.position.y),
                             size: size)
        layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        layer.contentsScale = WhiteboardView.displayScale
        return layer
    }
}

extension LayerBuilder {
    static func getFontName(_ weight: Int) -> String {
        let defaultWeight: Int = 400
        if weight < defaultWeight {
            return "Helvetica-Light"
        } else if weight == defaultWeight {
            return "Helvetica"
        } else {
            return "Helvetica-Bold"
        }
    }
}
