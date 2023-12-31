// Copyright (c) 2014 Nikolaj Schumacher
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import LarkCompatible
import UIKit

public extension CGRect {
    /// Creates a rect with unnamed arguments.

    // swiftlint:disable identifier_name file_length

    // MARK: access shortcuts

    /// Accesses origin.x + 0.5 * size.width.
    @inlinable
    var centerX: CGFloat {
        get { minX + width * 0.5 }
        set { origin.x = newValue - width * 0.5 }
    }

    /// Accesses origin.y + 0.5 * size.height.
    @inlinable
    var centerY: CGFloat {
        get { minY + height * 0.5 }
        set { origin.y = newValue - height * 0.5 }
    }

    // MARK: edges

    /// Alias for origin.x.
    @inlinable
    var left: CGFloat {
        get { origin.x }
        set { origin.x = newValue }
    }

    /// Accesses origin.x + size.width.
    @inlinable
    var right: CGFloat {
        get { minX + width }
        set { origin.x = newValue - width }
    }

    /// Alias for origin.y.
    @inlinable
    var top: CGFloat {
        get { minY }
        set { origin.y = newValue }
    }

    /// Accesses origin.y + size.height.
    @inlinable
    var bottom: CGFloat {
        get { minY + height }
        set { origin.y = newValue - height }
    }

    // MARK: points

    /// Accesses the point at the top left corner.
    @inlinable
    var topLeft: CGPoint {
        get { CGPoint(x: left, y: top) }
        set { left = newValue.x; top = newValue.y }
    }

    /// Accesses the point at the middle of the top edge.
    @inlinable
    var topCenter: CGPoint {
        get { CGPoint(x: centerX, y: top) }
        set { centerX = newValue.x; top = newValue.y }
    }

    /// Accesses the point at the top right corner.
    @inlinable
    var topRight: CGPoint {
        get { CGPoint(x: right, y: top) }
        set { right = newValue.x; top = newValue.y }
    }

    /// Accesses the point at the middle of the left edge.
    @inlinable
    var centerLeft: CGPoint {
        get { CGPoint(x: left, y: centerY) }
        set { left = newValue.x; centerY = newValue.y }
    }

    /// Accesses the point at the center.
    @inlinable
    var center: CGPoint {
        get { CGPoint(x: centerX, y: centerY) }
        set { centerX = newValue.x; centerY = newValue.y }
    }

    /// Accesses the point at the middle of the right edge.
    @inlinable
    var centerRight: CGPoint {
        get { CGPoint(x: right, y: centerY) }
        set { right = newValue.x; centerY = newValue.y }
    }

    /// Accesses the point at the bottom left corner.
    @inlinable
    var bottomLeft: CGPoint {
        get { CGPoint(x: left, y: bottom) }
        set { left = newValue.x; bottom = newValue.y }
    }

    /// Accesses the point at the middle of the bottom edge.
    @inlinable
    var bottomCenter: CGPoint {
        get { CGPoint(x: centerX, y: bottom) }
        set { centerX = newValue.x; bottom = newValue.y }
    }

    /// Accesses the point at the bottom right corner.
    @inlinable
    var bottomRight: CGPoint {
        get { CGPoint(x: right, y: bottom) }
        set { right = newValue.x; bottom = newValue.y }
    }
}

// MARK: operators

/// Returns a point by adding the coordinates of another point.
@inlinable
public func + (p1: CGPoint, p2: CGPoint) -> CGPoint {
    CGPoint(x: p1.x + p2.x, y: p1.y + p2.y)
}

/// Modifies the x and y values by adding the coordinates of another point.
@inlinable
public func += (p1: inout CGPoint, p2: CGPoint) {
    p1.x += p2.x
    p1.y += p2.y
}

/// Returns a point by subtracting the coordinates of another point.
@inlinable
public func - (p1: CGPoint, p2: CGPoint) -> CGPoint {
    CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
}

/// Modifies the x and y values by subtracting the coordinates of another points.
@inlinable
public func -= (p1: inout CGPoint, p2: CGPoint) {
    p1.x -= p2.x
    p1.y -= p2.y
}

/// Returns a point by adding a size to the coordinates.
@inlinable
public func + (point: CGPoint, size: CGSize) -> CGPoint {
    CGPoint(x: point.x + size.width, y: point.y + size.height)
}

/// Modifies the x and y values by adding a size to the coordinates.
@inlinable
public func += (point: inout CGPoint, size: CGSize) {
    point.x += size.width
    point.y += size.height
}

/// Returns a point by subtracting a size from the coordinates.
@inlinable
public func - (point: CGPoint, size: CGSize) -> CGPoint {
    return CGPoint(x: point.x - size.width, y: point.y - size.height)
}

/// Modifies the x and y values by subtracting a size from the coordinates.
@inlinable
public func -= (point: inout CGPoint, size: CGSize) {
    point.x -= size.width
    point.y -= size.height
}

/// Returns a point by adding a tuple to the coordinates.
@inlinable
public func + (point: CGPoint, tuple: (CGFloat, CGFloat)) -> CGPoint {
    return CGPoint(x: point.x + tuple.0, y: point.y + tuple.1)
}

/// Modifies the x and y values by adding a tuple to the coordinates.
@inlinable
public func += (point: inout CGPoint, tuple: (CGFloat, CGFloat)) {
    point.x += tuple.0
    point.y += tuple.1
}

/// Returns a point by subtracting a tuple from the coordinates.
@inlinable
public func - (point: CGPoint, tuple: (CGFloat, CGFloat)) -> CGPoint {
    return CGPoint(x: point.x - tuple.0, y: point.y - tuple.1)
}

/// Modifies the x and y values by subtracting a tuple from the coordinates.
@inlinable
public func -= (point: inout CGPoint, tuple: (CGFloat, CGFloat)) {
    point.x -= tuple.0
    point.y -= tuple.1
}

/// Returns a point by multiplying the coordinates with a value.
@inlinable
public func * (point: CGPoint, factor: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * factor, y: point.y * factor)
}

/// Modifies the x and y values by multiplying the coordinates with a value.
@inlinable
public func *= (point: inout CGPoint, factor: CGFloat) {
    point.x *= factor
    point.y *= factor
}

/// Returns a point by multiplying the coordinates with a tuple.
@inlinable
public func * (point: CGPoint, tuple: (CGFloat, CGFloat)) -> CGPoint {
    return CGPoint(x: point.x * tuple.0, y: point.y * tuple.1)
}

/// Modifies the x and y values by multiplying the coordinates with a tuple.
@inlinable
public func *= (point: inout CGPoint, tuple: (CGFloat, CGFloat)) {
    point.x *= tuple.0
    point.y *= tuple.1
}

/// Returns a point by dividing the coordinates by a tuple.
@inlinable
public func / (point: CGPoint, tuple: (CGFloat, CGFloat)) -> CGPoint {
    return CGPoint(x: point.x / tuple.0, y: point.y / tuple.1)
}

/// Modifies the x and y values by dividing the coordinates by a tuple.
@inlinable
public func /= (point: inout CGPoint, tuple: (CGFloat, CGFloat)) {
    point.x /= tuple.0
    point.y /= tuple.1
}

/// Returns a point by dividing the coordinates by a factor.
@inlinable
public func / (point: CGPoint, factor: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / factor, y: point.y / factor)
}

/// Modifies the x and y values by dividing the coordinates by a factor.
@inlinable
public func /= (point: inout CGPoint, factor: CGFloat) {
    point.x /= factor
    point.y /= factor
}

/// Returns a point by adding another size.
@inlinable
public func + (s1: CGSize, s2: CGSize) -> CGSize {
    return CGSize(width: s1.width + s2.width, height: s1.height + s2.height)
}

/// Modifies the width and height values by adding another size.
@inlinable
public func += (s1: inout CGSize, s2: CGSize) {
    s1.width += s2.width
    s1.height += s2.height
}

/// Returns a point by subtracting another size.
@inlinable
public func - (s1: CGSize, s2: CGSize) -> CGSize {
    return CGSize(width: s1.width - s2.width, height: s1.height - s2.height)
}

/// Modifies the width and height values by subtracting another size.
@inlinable
public func -= (s1: inout CGSize, s2: CGSize) {
    s1.width -= s2.width
    s1.height -= s2.height
}

/// Returns a point by adding a tuple.
@inlinable
public func + (size: CGSize, tuple: (CGFloat, CGFloat)) -> CGSize {
    return CGSize(width: size.width + tuple.0, height: size.height + tuple.1)
}

/// Modifies the width and height values by adding a tuple.
@inlinable
public func += (size: inout CGSize, tuple: (CGFloat, CGFloat)) {
    size.width += tuple.0
    size.height += tuple.1
}

/// Returns a point by subtracting a tuple.
@inlinable
public func - (size: CGSize, tuple: (CGFloat, CGFloat)) -> CGSize {
    return CGSize(width: size.width - tuple.0, height: size.height - tuple.1)
}

/// Modifies the width and height values by subtracting a tuple.
@inlinable
public func -= (size: inout CGSize, tuple: (CGFloat, CGFloat)) {
    size.width -= tuple.0
    size.height -= tuple.1
}

/// Returns a point by multiplying the size with a factor.
@inlinable
public func * (size: CGSize, factor: CGFloat) -> CGSize {
    return CGSize(width: size.width * factor, height: size.height * factor)
}

/// Modifies the width and height values by multiplying them with a factor.
@inlinable
public func *= (size: inout CGSize, factor: CGFloat) {
    size.width *= factor
    size.height *= factor
}

/// Returns a point by multiplying the size with a tuple.
@inlinable
public func * (size: CGSize, tuple: (CGFloat, CGFloat)) -> CGSize {
    return CGSize(width: size.width * tuple.0, height: size.height * tuple.1)
}

/// Modifies the width and height values by multiplying them with a tuple.
@inlinable
public func *= (size: inout CGSize, tuple: (CGFloat, CGFloat)) {
    size.width *= tuple.0
    size.height *= tuple.1
}

/// Returns a point by dividing the size by a factor.
@inlinable
public func / (size: CGSize, factor: CGFloat) -> CGSize {
    return CGSize(width: size.width / factor, height: size.height / factor)
}

/// Modifies the width and height values by dividing them by a factor.
@inlinable
public func /= (size: inout CGSize, factor: CGFloat) {
    size.width /= factor
    size.height /= factor
}

/// Returns a point by dividing the size by a tuple.
@inlinable
public func / (size: CGSize, tuple: (CGFloat, CGFloat)) -> CGSize {
    return CGSize(width: size.width / tuple.0, height: size.height / tuple.1)
}

/// Modifies the width and height values by dividing them by a tuple.
@inlinable
public func /= (size: inout CGSize, tuple: (CGFloat, CGFloat)) {
    size.width /= tuple.0
    size.height /= tuple.1
}

/// Returns a rect by adding the coordinates of a point to the origin.
@inlinable
public func + (rect: CGRect, point: CGPoint) -> CGRect {
    return CGRect(origin: rect.origin + point, size: rect.size)
}

/// Modifies the x and y values by adding the coordinates of a point.
@inlinable
public func += (rect: inout CGRect, point: CGPoint) {
    rect.origin += point
}

/// Returns a rect by subtracting the coordinates of a point from the origin.
@inlinable
public func - (rect: CGRect, point: CGPoint) -> CGRect {
    return CGRect(origin: rect.origin - point, size: rect.size)
}

/// Modifies the x and y values by subtracting the coordinates from a point.
@inlinable
public func -= (rect: inout CGRect, point: CGPoint) {
    rect.origin -= point
}

/// Returns a rect by adding a size to the size.
@inlinable
public func + (rect: CGRect, size: CGSize) -> CGRect {
    return CGRect(origin: rect.origin, size: rect.size + size)
}

/// Modifies the width and height values by adding a size.
@inlinable
public func += (rect: inout CGRect, size: CGSize) {
    rect.size += size
}

/// Returns a rect by subtracting a size from the size.
@inlinable
public func - (rect: CGRect, size: CGSize) -> CGRect {
    return CGRect(origin: rect.origin, size: rect.size - size)
}

/// Modifies the width and height values by subtracting a size.
@inlinable
public func -= (rect: inout CGRect, size: CGSize) {
    rect.size -= size
}

// swiftlint:enable identifier_name file_length
