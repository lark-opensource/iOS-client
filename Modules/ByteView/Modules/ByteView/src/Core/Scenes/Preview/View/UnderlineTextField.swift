//
//  UnderlineTextField.swift
//  ByteView
//
//  Created by yizhuo on 2020/1/15.
//

import UIKit
import RxCocoa
import RxSwift

class UnderlineTextField: PreviewTextField {
    override var underlineColor: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        ctx.saveGState()
        defer {
            ctx.restoreGState()
        }

        let lineWidth = 1.0 as CGFloat

        var pos = CGPoint(x: 0, y: self.bounds.height - lineWidth)

        ctx.setStrokeColor((underlineColor ?? UIColor.ud.lineBorderComponent).cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.move(to: pos)
        pos.x += bounds.width
        ctx.addLine(to: pos)
        ctx.strokePath()
    }
}

extension Reactive where Base == UnderlineTextField {
    var underlineColor: Binder<UIColor> {
        return Binder<UIColor>(self.base) { field, value in
            field.underlineColor = value
        }
    }
}
