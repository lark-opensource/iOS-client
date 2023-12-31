//
//  LKAttachment.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation

public enum LKAttachmentAlignment: Int32 {
    case top, middle, bottom
}

public protocol LKAttachmentProtocol: AnyObject {
    var view: UIView { get set }
    var fontAscent: CGFloat { get set }
    var fontDescent: CGFloat { get set }
    var verticalAlignment: LKAttachmentAlignment { get set }
    var margin: UIEdgeInsets { get set }
    var size: CGSize { get set }
}

/// 因为12.3中对OC环境的Array、Dic、String、AttrString、Data相关会调用_axRecursivelyPropertyListCoercedRepresentationWithError
/// swift变量是没有这个的，NSObject中默认空实现了这个方法。下面会提交到AttrString的Dict里面，因此需要实现此方法
public final class LKAttachment: NSObject, LKAttachmentProtocol {
    public var view: UIView
    public var fontAscent: CGFloat = 0
    public var fontDescent: CGFloat = 0
    public var verticalAlignment: LKAttachmentAlignment = .middle
    public var margin: UIEdgeInsets = .zero
    public var size: CGSize {
        get {
            return self.view.frame.size
        }
        set {
            self.view.frame.size = newValue
        }
    }

    public init(view: UIView, verticalAlign: LKAttachmentAlignment = .middle) {
        self.view = view
        self.verticalAlignment = verticalAlign
    }
}

public final class LKAsyncAttachment: NSObject, LKAttachmentProtocol {
    var _view: UIView?
    public var view: UIView {
        get {
            if let ui = self._view {
                return ui
            }
            self._view = self.viewProvider()
            self._view?.frame.size = self.size
            return self._view!
        }
        set {
            self._view = newValue
        }
    }
    var viewProvider: () -> UIView
    public var fontAscent: CGFloat = 0
    public var fontDescent: CGFloat = 0
    public var verticalAlignment: LKAttachmentAlignment = .middle
    public var margin: UIEdgeInsets = .zero
    public var size: CGSize = .zero

    public init(viewProvider: @escaping () -> UIView, size: CGSize, verticalAlign: LKAttachmentAlignment = .middle) {
        self.viewProvider = viewProvider
        self.verticalAlignment = verticalAlign
        self.size = size
    }
}
