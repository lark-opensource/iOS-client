//
//  LiangBarskyUtility.swift
//  Whiteboard
//
//  Created by bytedance on 2022/2/28.
//

import CoreGraphics

public extension CGRect {
    private struct Math {
        static let EPSILON: CGFloat = 1e-6
    }

    public func intersection(with startPoint: CGPoint, endPoint: CGPoint) -> (CGPoint?, CGPoint?) {
        let x1 = startPoint.x, y1 = startPoint.y
        let x2 = endPoint.x, y2 = endPoint.y
        let dx = x2 - x1, dy = y2 - y1
        var clipedStartPoint = startPoint
        var clipedEndPoint = endPoint
        var point = CGPoint(x: 0, y: 1)
        if clipT(num: self.origin.x - x1, denom: dx, point: &point),
            clipT(num: x1 - self.width, denom: -dx, point: &point),
            clipT(num: self.origin.y - y1, denom: dy, point: &point),
            clipT(num: y1 - self.height, denom: -dy, point: &point) {
            let tE = point.x, tL = point.y
            if tL < 1 {
                clipedEndPoint.x = x1 + tL * dx
                clipedEndPoint.y = y1 + tL * dy
            }
            if tE > 0 {
                clipedStartPoint.x += tE * dx
                clipedStartPoint.y += tE * dy
            }
        }
        switch (clipedStartPoint == startPoint, clipedEndPoint == endPoint) {
        case (true, true):
            return (nil, nil)
        case (true, false):
            return (nil, clipedEndPoint)
        case (false, true):
            return (clipedStartPoint, nil)
        case (false, false):
            return (clipedStartPoint, clipedEndPoint)
        }
    }

    private func clipT(num: CGFloat, denom: CGFloat, point: inout CGPoint) -> Bool {
        let tE = point.x, tL = point.y
        if abs(denom) < Math.EPSILON {
            return num < 0
        }
        let t = num / denom

        if denom > 0 {
            if t > tL {
                return false
            }
            if t > tE {
                point.x = t
            }
        } else {
            if t < tE {
                return false
            }
            if t < tL {
                point.y = t
            }
        }
        return true
    }
}
