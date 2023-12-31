//
//  ShapeDrawable+Data.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/11/21.
//

import Foundation
import CoreGraphics
import UIKit

// disable-lint: magic number
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
}

extension CGRect {
    init(x: Float, y: Float, width: Float, height: Float) {
        self.init(x: CGFloat(x),
                  y: CGFloat(y),
                  width: CGFloat(width),
                  height: CGFloat(height))
    }
}

extension Int64 {
    var rgbaColor: UIColor {
        let r: CGFloat = CGFloat(self >> 24 & 0xFF) / 255
        let g: CGFloat = CGFloat(self >> 16 & 0xFF) / 255
        let b: CGFloat = CGFloat(self >> 8 & 0xFF) / 255
        let a: CGFloat = CGFloat(self >> 0 & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension UIColor {
    var rgbaInt64: Int64 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let uintVal = (Int64(255 * r) << 24)
            + (Int64(255 * g) << 16)
            + (Int64(255 * b) << 8)
            + Int64(255 * a)
        return uintVal
    }
}

extension CGColor {
    var rgbaInt64: Int64 {
        return UIColor(cgColor: self).rgbaInt64
    }
}

extension ShapeType {
//    PENCIL = 1,
//    RECTANGLE = 2,
//    OVAL = 3,
//    ARROW = 4,
    static var pencil = ShapeType(rawValue: 1)
    static var rectangle = ShapeType(rawValue: 2)
    static var oval = ShapeType(rawValue: 4)
    static var arrow = ShapeType(rawValue: 5)
}

extension FFIArrayFloat2 {
    var points: [CGPoint] {
        let buf = UnsafeBufferPointer<(Float, Float)>(start: ptr, count: Int(len))
        return buf.map { pointee -> CGPoint in
            return CGPoint(x: CGFloat(pointee.0),
                           y: CGFloat(pointee.1))
        }
    }
}

extension FFIArrayFloat1 {
    var values: [CGFloat] {
        let buf = UnsafeBufferPointer<Float>(start: ptr, count: Int(len))
        return buf.map { val -> CGFloat in
            return CGFloat(val)
        }
    }
}

extension Array where Element == CGPoint {

    func withFFIArray<R>(body: (_ data: FFIArrayFloat2) throws -> R) rethrows -> R {
        return try self.map({ pt -> (Float, Float) in
            return (Float(pt.x), Float(pt.y))
        })
        .withUnsafeBufferPointer({ ptr -> R in
            let ffi = FFIArrayFloat2(ptr: ptr.baseAddress, len: UInt(self.count))
            return try body(ffi)
        })

    }

    // pecker:ignore
    func withFFIArray<R>(range: Range<Int>, body: (_ data: FFIArrayFloat2) throws -> R) rethrows -> R {
        return try self[range].map({ pt -> (Float, Float) in
            return (Float(pt.x), Float(pt.y))
        })
        .withUnsafeBufferPointer({ ptr -> R in
            let ffi = FFIArrayFloat2(ptr: ptr.baseAddress, len: UInt(range.count))
            return try body(ffi)
        })

    }
}

extension Array where Element == CGFloat {
    // pecker:ignore
    func withFFIArray<R>(body: (_ data: FFIArrayFloat1) throws -> R) rethrows -> R {
        return try self.map({ return Float($0) })
            .withUnsafeBufferPointer({ ptr -> R in
                let ffi = FFIArrayFloat1(ptr: ptr.baseAddress, len: UInt(ptr.count))
                return try body(ffi)
            })
    }
}

// MARK: - drawable

extension OvalDrawable {
    init(data: OvalDrawableData) {
        let id = data.id != nil ? String.init(cString: data.id!) : ""

        let userID = data.ext_info.user_id.stringVal
        let deviceID = data.ext_info.device_id.stringVal
        let userType = data.ext_info.user_type
        let identifier = "\(userID)_\(userType)_\(deviceID)"

        self.init(id: id,
                  frame: CGRect(x: CGFloat(data.origin[0] - data.long_axis),
                                y: CGFloat(data.origin[1] - data.short_axis),
                                width: CGFloat(data.long_axis * 2),
                                height: CGFloat(data.short_axis * 2)),
                  style: OvalPaintStyle(data: data.style),
                  userIdentifier: identifier)
    }
}

extension RectangleDrawable {
    init(data: RectangleDrawableData) {
        let id = data.id != nil ? String.init(cString: data.id!) : ""

        let userID = data.ext_info.user_id.stringVal
        let deviceID = data.ext_info.device_id.stringVal
        let userType = data.ext_info.user_type
        let identifier = "\(userID)_\(userType)_\(deviceID)"

        self.init(id: id,
                  frame: CGRect(x: CGFloat(data.left_top[0]),
                                y: CGFloat(data.left_top[1]),
                                width: CGFloat(data.right_bottom[0] - data.left_top[0]),
                                height: CGFloat(data.right_bottom[1] - data.left_top[1])),
                  style: RectanglePaintStyle(data: data.style),
                  userIdentifier: identifier)
    }
}

extension PencilPathDrawable {
    init(data: PencilDrawableData) {
        let id = data.id != nil ? String.init(cString: data.id!) : ""

        let userID = data.ext_info.user_id.stringVal
        let deviceID = data.ext_info.device_id.stringVal
        let userType = data.ext_info.user_type
        let identifier = "\(userID)_\(userType)_\(deviceID)"

        self.init(id: id,
                  points: data.points.points,
                  dimension: PencilPathDrawable.Dimension(rawValue: data.dimension) ?? .linear,
                  pause: data.pause,
                  finish: data.finish,
                  style: PencilPaintStyle(data: data.style),
                  userIdentifier: identifier)
    }
}

extension ArrowDrawable {
    init(data: ArrowDrawableData) {
        let id = data.id != nil ? String.init(cString: data.id!) : ""

        let userID = data.ext_info.user_id.stringVal
        let deviceID = data.ext_info.device_id.stringVal
        let userType = data.ext_info.user_type
        let identifier = "\(userID)_\(userType)_\(deviceID)"

        self.init(id: id,
                  start: CGPoint(pointer: data.origin),
                  end: CGPoint(pointer: data.end),
                  style: ArrowPaintStyle(data: data.style),
                  userIdentifier: identifier)
    }
}

extension CometSnippetDrawable {
    init(data: CometDrawableData, minDistance: CGFloat) {
        let id = data.id != nil ? String.init(cString: data.id!) : ""
        self.init(id: id,
                  points: data.points.points,
                  radius: data.radii.values,
                  pause: data.pause,
                  exit: data.exit,
                  minDistance: minDistance,
                  cometStyle: CometPaintStyle(data: data.style),
                  userIdentifier: "")
    }
}

// MARK: - style

extension ArrowPaintStyle {
    init(data: ArrowStyle) {
        self.init(color: data.color.rgbaColor,
                  size: CGFloat(data.size))
    }

    var data: ArrowStyle {
        ArrowStyle(color: color.rgbaInt64,
                   size: Float(size))
    }
}

extension OvalPaintStyle {
    init(data: OvalStyle) {
        self.init(color: data.color.rgbaColor,
                  size: CGFloat(data.size))
    }

    var data: OvalStyle {
        OvalStyle(color: color.rgbaInt64,
                   size: Float(size))
    }
}

extension RectanglePaintStyle {
    init(data: RectangleStyle) {
        self.init(color: data.color.rgbaColor,
                  size: CGFloat(data.size))
    }

    var data: RectangleStyle {
        RectangleStyle(color: color.rgbaInt64,
                       size: Float(size))
    }
}

extension CometPaintStyle {
    init(data: CometStyle) {
        self.init(color: data.color.rgbaColor,
                  size: CGFloat(data.size),
                  opacity: CGFloat(data.opacity))
    }
    var data: CometStyle {
        CometStyle(color: color.rgbaInt64,
                   size: Float(size),
                   opacity: Float(opacity))
    }
}

extension PencilPaintStyle {
    init(data: PencilStyle) {
        self.init(color: data.color.rgbaColor,
                  size: CGFloat(data.size),
                  pencilType: data.pencil_type.rawValue)
    }

    var data: PencilStyle {
        PencilStyle(color: color.rgbaInt64,
                    size: Float(size),
                    pencil_type: PencilType(pencilType))
    }
}
