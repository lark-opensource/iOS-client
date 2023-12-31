//
//  WhiteboardShape+Data.swift
//  ByteView
//
//  Created by 阮明哲 on 2022/3/25.
//

import Foundation
import CoreGraphics
import UIKit
import WbLib

// MARK: - foundation
extension CGPoint {
    init(x: Float, y: Float) {
        self.init(x: CGFloat(x),
                  y: CGFloat(y))
    }
}

extension CGPoint {
    init(data: (Float, Float)) {
        self.init(x: CGFloat(data.0), y: CGFloat(data.1))
    }

    init(pointer: UnsafePointer<Float>) {
        self.init(x: CGFloat(pointer.pointee), y: CGFloat(pointer.advanced(by: 1).pointee))
    }

    var wbPoint: Point {
        return Point(Float(self.x), Float(self.y))
    }
}

extension CGRect {
    init(x: Float, y: Float, width: Float, height: Float) {
        self.init(x: CGFloat(x),
                  y: CGFloat(y),
                  width: CGFloat(width),
                  height: CGFloat(height))
    }
}

// disable-lint: magic number
extension Int {
    var rgbaColor: UIColor {
        let a: CGFloat = CGFloat(self >> 24 & 0xFF) / 255
        let r: CGFloat = CGFloat(self >> 16 & 0xFF) / 255
        let g: CGFloat = CGFloat(self >> 8 & 0xFF) / 255
        let b: CGFloat = CGFloat(self >> 0 & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
// enable-lint: magic number

extension VectorShape {
    init(id: ShapeID, wbGraphic: WbGraphic) {
        var transform: CGAffineTransform?
        if let transformData = wbGraphic.transform {
            transform = CGAffineTransform(a: CGFloat(transformData.a), b: CGFloat(transformData.b), c: CGFloat(transformData.c), d: CGFloat(transformData.d), tx: CGFloat(transformData.e), ty: CGFloat(transformData.f))
        }
        var lineWidth: CGFloat?
        if let width = wbGraphic.stroke?.width {
            lineWidth = CGFloat(width)
        }
        var path = CGMutablePath(rect: .zero, transform: nil)
        if case .Path(let wbPath) = wbGraphic.primitive {
            path = wbPath.makeCGPath(id)
        }
        self.init(id: id,
                  path: path,
                  strokeColor: wbGraphic.stroke?.color.rgbaColor,
                  lineWidth: lineWidth,
                  fillColor: wbGraphic.fill?.color.rgbaColor,
                  transform: transform)
    }

    init(id: ShapeID, vectorShape: VectorShape, path: Path) {
        let newPath = path.makeCGPath(vectorShape.id)
        self.init(id: id, path: newPath, strokeColor: vectorShape.strokeColor, lineWidth: vectorShape.lineWidth, fillColor: vectorShape.fillColor, transform: vectorShape.transform)
    }

    init(id: ShapeID, vectorShape: VectorShape, stroke: Stroke) {
        self.init(id: id, path: vectorShape.path, strokeColor: stroke.color.rgbaColor, lineWidth: CGFloat(stroke.width), fillColor: vectorShape.fillColor, transform: vectorShape.transform)
    }

    init(id: ShapeID, vectorShape: VectorShape, fill: Fill) {
        self.init(id: id, path: vectorShape.path, strokeColor: vectorShape.strokeColor, lineWidth: vectorShape.lineWidth, fillColor: fill.color.rgbaColor, transform: vectorShape.transform)
    }

    init(id: ShapeID, vectorShape: VectorShape, transformData: Transform) {
        let transform = CGAffineTransform(a: CGFloat(transformData.a), b: CGFloat(transformData.b), c: CGFloat(transformData.c), d: CGFloat(transformData.d), tx: CGFloat(transformData.e), ty: CGFloat(transformData.f))
        self.init(id: id, path: vectorShape.path, strokeColor: vectorShape.strokeColor, lineWidth: vectorShape.lineWidth, fillColor: vectorShape.fillColor, transform: transform)
    }
}

extension TextDrawable {
    init(id: ShapeID, wbGraphic: WbGraphic) {
        var transform: CGAffineTransform?
        if let transformData = wbGraphic.transform {
            transform = CGAffineTransform(a: CGFloat(transformData.a), b: CGFloat(transformData.b), c: CGFloat(transformData.c), d: CGFloat(transformData.d), tx: CGFloat(transformData.e), ty: CGFloat(transformData.f))
        }
        var lineWidth: CGFloat?
        if let width = wbGraphic.stroke?.width {
            lineWidth = CGFloat(width)
        }
        if case .Text(let text) = wbGraphic.primitive {
            self.init(id: id, text: text.text, fontSize: text.fontSize, fontWeight: text.fontWeight, strokeColor: wbGraphic.stroke?.color.rgbaColor, fillColor: wbGraphic.fill?.color.rgbaColor,
                      lineWidth: lineWidth, transform: transform)
        } else {
            self.init(id: id, text: "", fontSize: 0, fontWeight: 0)
        }
    }

    init(id: ShapeID, textShape: TextDrawable, stroke: Stroke) {
        self.init(id: id, text: textShape.text, fontSize: textShape.fontSize, fontWeight: textShape.fontWeight, strokeColor: stroke.color.rgbaColor, fillColor: textShape.fillColor, lineWidth: CGFloat(stroke.width), transform: textShape.transform)
    }

    init(id: ShapeID, textShape: TextDrawable, fill: Fill) {
        self.init(id: id, text: textShape.text, fontSize: textShape.fontSize, fontWeight: textShape.fontWeight, strokeColor: textShape.strokeColor, fillColor: fill.color.rgbaColor, lineWidth: textShape.lineWidth, transform: textShape.transform)
    }

    init(id: ShapeID, textShape: TextDrawable, transformData: Transform) {
        let transform = CGAffineTransform(a: CGFloat(transformData.a), b: CGFloat(transformData.b), c: CGFloat(transformData.c), d: CGFloat(transformData.d), tx: CGFloat(transformData.e), ty: CGFloat(transformData.f))
        self.init(id: id, text: textShape.text, fontSize: textShape.fontSize, fontWeight: textShape.fontWeight, strokeColor: textShape.strokeColor, fillColor: textShape.fillColor, lineWidth: textShape.lineWidth, transform: transform)
    }
}
