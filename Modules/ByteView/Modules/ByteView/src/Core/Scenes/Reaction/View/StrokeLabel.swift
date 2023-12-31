//
//  StrokeLabel.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/11.
//

import UIKit

class StrokeLabel: UILabel {
    static let wPadding: CGFloat = 5
    static let hPadding: CGFloat = 2

    var colors: [UIColor] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect.insetBy(dx: Self.wPadding, dy: Self.hPadding))
    }

    override func drawText(in rect: CGRect) {
        let color = gradientColor(in: rect, colors: colors, start: CGPoint(x: 0, y: 0.5), end: CGPoint(x: 1, y: 0.5))
        let c = UIGraphicsGetCurrentContext()
        c?.setLineWidth(8)
        c?.setLineJoin(.round)
        c?.setLineCap(.round)
        c?.setTextDrawingMode(.stroke)
        c?.setTextDrawingMode(.fillStroke)
        textAlignment = .center
        textColor = color
        super.drawText(in: rect)

        c?.setTextDrawingMode(.fill)
        textColor = .white
        super.drawText(in: rect)
    }

    private func gradientColor(in rect: CGRect, colors: [UIColor], start: CGPoint, end: CGPoint) -> UIColor? {
        let layer = CAGradientLayer()
        layer.colors = colors.map { $0.cgColor }
        layer.startPoint = start
        layer.endPoint = end
        layer.frame = rect
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = image else { return nil }
        return UIColor(patternImage: image)
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 2 * Self.wPadding, height: size.height + 2 * Self.hPadding)
    }

    override var alignmentRectInsets: UIEdgeInsets {
        UIEdgeInsets(top: Self.hPadding, left: Self.wPadding, bottom: Self.hPadding, right: Self.wPadding)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fixedSize = CGSize(width: size.width - 2 * Self.wPadding, height: size.height - 2 * Self.hPadding)
        let res = super.sizeThatFits(fixedSize)
        return CGSize(width: res.width + 2 * Self.wPadding, height: res.height + 2 * Self.hPadding)
    }
}
