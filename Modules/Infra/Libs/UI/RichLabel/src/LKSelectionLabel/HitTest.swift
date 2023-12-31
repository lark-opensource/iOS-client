//
//  HitTest.swift
//  RichLabel
//
//  Created by qihongye on 2019/2/19.
//

import UIKit
import Foundation

private var _selectionLabelHitTestViewKey = "_SelectionLabelHitTestViewKey"

struct Weak<T> where T: AnyObject {
    private(set) weak var value: T?

    init(_ value: T) {
        self.value = value
    }
}

/// 用于提高CursorHitTest区域优先级的中间层view
final class LKSelectionLabelHitTestView: UIView {
    var _selectionLabels: [Weak<UIView>] = []
    var selectionLabels: [UIView] {
        get {
            return _selectionLabels.compactMap({ $0.value })
        }
        set {
            _selectionLabels = newValue.map({ Weak($0) })
        }
    }
    weak var delegateView: UIView?

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return true
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let delegateView = delegateView else {
            return nil
        }
        if let v = delegateView.hitTest(self.convert(point, to: delegateView), with: event) {
            return v
        }
        for view in selectionLabels.reversed() {
            if let v = view.hitTest(self.convert(point, to: view), with: event) {
                return v
            }
        }
        return nil
    }
}

extension UIWindow {
    var selectionLabels: [UIView] {
        get {
            return selectLabelHitTestView?.selectionLabels ?? []
        }
        set {
            if newValue.isEmpty {
                selectLabelHitTestView = nil
            } else {
                let view = LKSelectionLabelHitTestView()
                view.selectionLabels = newValue
                selectLabelHitTestView = view
            }
        }
    }

    var selectLabelHitTestView: LKSelectionLabelHitTestView? {
        get {
            return objc_getAssociatedObject(self, &_selectionLabelHitTestViewKey) as? LKSelectionLabelHitTestView
        }
        set {
            if newValue == nil {
                selectLabelHitTestView?.removeFromSuperview()
            }
            objc_setAssociatedObject(self, &_selectionLabelHitTestViewKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
