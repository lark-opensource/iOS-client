//
//  DriveMainViewController+FullScreen.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/7/16.
//

import UIKit
import SKCommon
import SKUIKit
import UniverseDesignColor

final class DriveTapEnterFullModeHandler: NSObject, UIGestureRecognizerDelegate {
    private var tapHandler: (() -> Void)?
    var shouldReceiveTouch: ((UITouch) -> Bool)?
    var tapGesture: UITapGestureRecognizer?
    func addTapGestureRecognizer(targetView: UIView, handler: @escaping (() -> Void)) {
        if let tap = tapGesture {
            targetView.removeGestureRecognizer(tap)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.enterFullModeTapClick))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.delegate = self
        targetView.addGestureRecognizer(tap)
        self.tapHandler = handler
        self.tapGesture = tap
    }

    @objc
    func enterFullModeTapClick() {
        tapHandler?()
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    // MARK: - 此处选择性实现
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer,
            otherGestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        return gestureRecognizer.shouldRequireFailure(of: otherGestureRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return shouldReceiveTouch?(touch) ?? true
    }
    
}

final class DriveDraggingEnterFullModeHandler {
    private var lastPosition: CGFloat = 0.0
    private var tapHandler: (() -> Void)?
    /// 上下滑动事件的标志位，捏合手势放大缩小页面会触发坐标变化，与滑动事件冲突导致状态栏频繁闪烁
    public var scrollHappen: Bool = false
    
    func draggingStatusSwitch(targetView: UIScrollView, handler: @escaping ((Bool) -> Void)) {
        guard self.scrollHappen else { return }
        let actualPosition = targetView.panGestureRecognizer.translation(in: targetView.superview)
        if actualPosition.y > 0 {
            handler(false)
        } else if actualPosition.y < 0 {
            handler(true)
        }
        self.scrollHappen = false
    }
}
