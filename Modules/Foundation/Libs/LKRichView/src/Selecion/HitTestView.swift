//
//  HitTestView.swift
//  LKRichView
//
//  Created by qihongye on 2021/10/7.
//

import UIKit
import Foundation

private var _hitTestViewKey: UInt8 = 1

struct Weak<T> where T: AnyObject {
    private(set) weak var value: T?

    init(_ value: T) {
        self.value = value
    }
}

final class HitTestView: UIView {
    var _richViews: [Weak<UIView>] = []
    var richViews: [UIView] {
        get {
            return _richViews.compactMap({ $0.value })
        }
        set {
            _richViews = newValue.map({ Weak($0) })
        }
    }
    weak var delegateView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
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
        for view in richViews.reversed() {
            if let v = view.hitTest(self.convert(point, to: view), with: event) {
                return v
            }
        }
        return nil
    }
}
