//
//  BTContainerHeaderUtils.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/9/18.
//

import Foundation
import SKFoundation

class BTContainerHeaderUtils {
    private static let touchPointCount = 5

    static func checkPointsValid(lastPoints: [BTShowHeaderPoint], lastPointIndex: Int) -> (isValid: Bool, yDiff: Float?) {
        let points = Self.handlePoints(lastPoints: lastPoints, lastPointIndex: lastPointIndex)
        guard let first = points.start, let last = points.end else {
            DocsLogger.btError("[BTContainer] handle lastPoints fail")
            return (false, nil)
        }

        let xDiff = (last.x ?? 0) - (first.x ?? 0)
        let yDiff = (last.y ?? 0) - (first.y ?? 0)

        guard abs(yDiff) > abs(xDiff),  abs(yDiff) > 10 else {
            DocsLogger.btInfo("[BTContainer] currentHeaderModel is invald \(xDiff), \(yDiff)")
            return (false, nil)
        }
        return (true, yDiff)
    }

    static func handlePoints(lastPoints: [BTShowHeaderPoint], lastPointIndex: Int) -> (start: BTShowHeaderPoint?, end: BTShowHeaderPoint?) {
        if lastPoints.isEmpty {
            DocsLogger.btError("[BTContainer] lastPoints is empty")
            return (nil, nil)
        }
        guard lastPointIndex >= 0, lastPointIndex < lastPoints.count else {
            DocsLogger.btError("[BTContainer] lastPointIndex is exceed lastPoints")
            return (nil, nil)
        }
        if lastPoints.count < touchPointCount {
            return (lastPoints.first, lastPoints.last)
        }
        let firstPointIndex = lastPointIndex >= (touchPointCount - 1) ? 0 : lastPointIndex + 1
        return (lastPoints[firstPointIndex], lastPoints[lastPointIndex])
    }
}
