//
//  WhiteboardGestRecognizer.swift
//  Whiteboard
//
//  Created by helijian on 2022/2/28.
//

import UIKit
import ByteViewCommon
import RxRelay

public protocol WhiteboardTouchDelegate: AnyObject {
    func whiteboardTouchLocation(touch: UITouch) -> CGPoint
    func whiteboardTouchesBegan(location: CGPoint)
    func whiteboardTouchesMoved(locations: [CGPoint])
    func whiteboardTouchesEnded(location: CGPoint)
    func whiteboardTouchesCancelled()
}

public class WhiteboardGestRecognizer: UIGestureRecognizer {

    public weak var touchDelegate: WhiteboardTouchDelegate?
    public let isTracking = BehaviorRelay<Bool>(value: false)
    public var isWhiteboardScene: Bool = true
    var trackedTouch: UITouch?
    var startPos: CGPoint = .zero
    var pendingPoints: [CGPoint] = []
    var moveDetected: Bool = false
    var shouldReceiveEvent: Bool = true
    static let moveSlope: CGFloat = 10.0
    static let buttonMoveSlope: CGFloat = 90.0

    public override func shouldBeRequiredToFail(by otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let otherView = otherGestureRecognizer.view else {
            return false
        }
        return otherView is UIScrollView
    }

    public override func shouldRequireFailure(of otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let otherView = otherGestureRecognizer.view else {
            return false
        }
        return !(otherView is UIScrollView)
    }

    // 该方法在ios12上无效，即便写死返回false依旧会触发手势
    public override func shouldReceive(_ event: UIEvent) -> Bool {
        return shouldReceiveEvent
    }

    // MARK: - touches
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard trackedTouch == nil else {
            if moveDetected {
                let pos = touchDelegate?.whiteboardTouchLocation(touch: trackedTouch!) ?? .zero
                self.touchDelegate?.whiteboardTouchesEnded(location: pos)
            }
            trackedTouch = nil
            self.state = .failed
            return
        }
        if touches.count != 1 {
            trackedTouch = nil
            self.state = .failed
            return
        }
        if Display.pad, isWhiteboardScene {
            // 防止滑动ipad 多白板的时候，触发笔画
            if touches.first?.view is UICollectionView || touches.first?.view?.frame.size == CGSize(width: 172, height: 97) {
                trackedTouch = nil
                self.state = .failed
                return
            }
        }
        trackedTouch = touches.first
        startPos = trackedTouch?.location(in: nil) ?? .zero
        if let pos = self.touchDelegate?.whiteboardTouchLocation(touch: trackedTouch!) {
            self.pendingPoints.append(pos)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let trackedTouch = trackedTouch else {
            return
        }
        let points: [CGPoint]
        if let touchDelegate = touchDelegate,
            let touches = event.coalescedTouches(for: trackedTouch) {
            points = touches.map(touchDelegate.whiteboardTouchLocation(touch:))
        } else {
            points = [touchDelegate?.whiteboardTouchLocation(touch: trackedTouch) ?? CGPoint.zero]
        }
        if moveDetected {
            touchDelegate?.whiteboardTouchesMoved(locations: points)
        } else {
            pendingPoints.append(contentsOf: points)
            let curPos: CGPoint = touches.first?.location(in: nil) ?? .zero
            let dist2 = (curPos.x - startPos.x) * (curPos.x - startPos.x)
                + (curPos.y - startPos.y) * (curPos.y - startPos.y)
            let slope: CGFloat
            if trackedTouch.view is UIButton {
                slope = Self.buttonMoveSlope
            } else {
                slope = Self.moveSlope
            }
            if dist2 > slope {
                moveDetected = true
                isTracking.accept(true)
                touchDelegate?.whiteboardTouchesBegan(location: pendingPoints.first ?? .zero)
                touchDelegate?.whiteboardTouchesMoved(locations: Array(pendingPoints.dropFirst()))
            }
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        trackedTouch = nil
        self.state = .failed
        if moveDetected {
            touchDelegate?.whiteboardTouchesCancelled()
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if moveDetected {
            let location: CGPoint
            if let trackedTouch = trackedTouch,
                let touchDelegate = touchDelegate {
                location = touchDelegate.whiteboardTouchLocation(touch: trackedTouch)
            } else {
                location = .zero
            }
            touchDelegate?.whiteboardTouchesEnded(location: location)
        }
        trackedTouch = nil
        self.state = moveDetected ? .recognized : .failed
    }

    public override func reset() {
        if self.trackedTouch != nil {
            self.trackedTouch = nil
            if self.moveDetected {
                self.moveDetected = false
                touchDelegate?.whiteboardTouchesCancelled()
            }
        }
        self.pendingPoints.removeAll()
        self.isTracking.accept(false)
        self.moveDetected = false
        super.reset()
    }
}
