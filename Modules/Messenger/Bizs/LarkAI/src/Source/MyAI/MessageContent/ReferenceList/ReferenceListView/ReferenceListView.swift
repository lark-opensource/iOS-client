//
//  ReferenceListView.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/4/10.
//

import UIKit
import Foundation
import LKRichView
import LarkRichTextCore

/// 这里拆为两个delegate，因为会分别指向ComponentViewModel、ComponentActionHandler
public protocol ReferenceListTagAEventDelegate: AnyObject {
    /// 点击了某个文档链接，最终会复用TextPostContentViewModel-handleTagAEvent
    func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?, listView: ReferenceListView)
}
public protocol ReferenceListShowMoreDelegate: AnyObject {
    /// 点击了showMore，把listView回调出去，是为了区分原文译文（ASComponentRenderer-getView只能做视图查找，做不到点击区分）
    func handleShowMore(listView: ReferenceListView)
}

public class ReferenceListView: UIView {
    /// 纵向间距
    public static let verticalSpacing: CGFloat = 4
    /// 点击回调
    public weak var tagAEventDelegate: ReferenceListTagAEventDelegate?
    public weak var showMoreDelegate: ReferenceListShowMoreDelegate?

    /// 提示文案
    private let tripView: LKRichView
    private let tripTouchView: UIButton
    /// 文档内容
    private let contentView: LKRichView

    public override init(frame: CGRect) {
        self.tripView = LKRichView(frame: .zero, options: ConfigOptions([.debug(false)]))
        self.tripView.isUserInteractionEnabled = false
        self.tripTouchView = UIButton(frame: .zero)
        self.contentView = LKRichView(frame: .zero, options: ConfigOptions([.debug(false)]))
        self.contentView.bindEvent(selectors: [CSSSelector(value: RichViewAdaptor.Tag.a)], isPropagation: true)
        super.init(frame: frame)
        self.addSubview(self.tripView)
        self.addSubview(self.tripTouchView)
        self.tripTouchView.addTarget(self, action: #selector(self.clickTrip(button:)), for: .touchUpInside)
        self.addSubview(self.contentView)
        self.contentView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clickTrip(button: UIButton) {
        self.showMoreDelegate?.handleShowMore(listView: self)
    }

    /// 设置内容，内部不持有ReferenceListLayout，做到单项数据流
    public func setup(layout: ReferenceListLayout) {
        // 提示文案
        self.tripView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: layout.tripStringCore.size)
        self.tripView.setRichViewCore(layout.tripStringCore)
        self.tripTouchView.frame = self.tripView.frame
        // 内容
        self.contentView.frame = CGRect(origin: CGPoint(x: 0, y: self.tripView.frame.maxY + 8), size: layout.referenceListCore.size)
        self.contentView.setRichViewCore(layout.referenceListCore)
    }
}

extension ReferenceListView: LKRichViewDelegate {
    public func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {}
    public func getTiledCache(_ view: LKRichView) -> LKTiledCache? { return nil }
    public func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {}
    public func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {}
    public func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {}
    public func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        // 点击了文档
        if element.tagName.typeID == RichViewAdaptor.Tag.a.rawValue {
            self.tagAEventDelegate?.handleTagAEvent(element: element, event: event, listView: self)
            event?.stopPropagation()
            return
        }
    }
    public func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {}
}
