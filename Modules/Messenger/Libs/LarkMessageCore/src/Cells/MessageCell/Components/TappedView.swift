//
//  TappedView.swift
//  LarkMessageCore
//
//  Created by qihongye on 2019/6/3.
//

import UIKit
import Foundation
import LarkUIKit

public class TappedView: UIView {
    public var onTapped: ((TappedView) -> Void)?
    public var onLongPressed: ((TappedView) -> Void)?
    public var longPressDuration: CFTimeInterval = 0.2
    public var hitTestEdgeInsets: UIEdgeInsets = .zero

    private var tapGesture: UITapGestureRecognizer?
    private var longPressGesture: UILongPressGestureRecognizer?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// - Parameters:
    ///   - needLongPress: 是否需要长按触发手势
    ///   - cancelsTouchesInView: 处理touch事件后，是否向下传递
    public func initEvent(needLongPress: Bool = true, cancelsTouchesInView: Bool = true) {
        if tapGesture == nil {
            tapGesture = self.lu.addTapGestureRecognizer(action: #selector(tapEventHandler))
        }
        tapGesture?.cancelsTouchesInView = cancelsTouchesInView
        if needLongPress, longPressGesture == nil {
            longPressGesture = self.lu.addLongPressGestureRecognizer(action: #selector(longPressEventHandler(_:)), duration: longPressDuration)
        }
        longPressGesture?.cancelsTouchesInView = cancelsTouchesInView
    }

    public func resetTapGesture() {
        if let ges = self.tapGesture {
            self.removeGestureRecognizer(ges)
            self.addGestureRecognizer(ges)
        }
    }
    public func deinitEvent() {
        if let gesture = tapGesture {
            self.removeGestureRecognizer(gesture)
            tapGesture = nil
        }
        if let gestrue = longPressGesture {
            self.removeGestureRecognizer(gestrue)
            longPressGesture = nil
        }
    }

    @objc
    private func tapEventHandler() {
        self.onTapped?(self)
    }

    @objc
    private func longPressEventHandler(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.onLongPressed?(self)
        default:
            break
        }
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.hitTestEdgeInsets == .zero {
            return super.point(inside: point, with: event)
        }
        let relativeFrame = self.bounds
        let hitFrame = relativeFrame.inset(by: self.hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}
