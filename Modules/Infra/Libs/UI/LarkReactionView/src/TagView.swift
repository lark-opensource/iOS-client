//
//  TagView.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/6/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

private func ceil_2digit(_ num: CGFloat) -> CGFloat {
    return ceil(num * 100) / 100
}

private func + (_ left: CGSize, _ right: UIEdgeInsets) -> CGSize {
    return CGSize(width: ceil_2digit(left.width + right.left + right.right), height: ceil_2digit(left.height + right.top + right.bottom))
}

private func + (_ left: CGPoint, _ right: UIEdgeInsets) -> CGPoint {
    return CGPoint(x: ceil_2digit(left.x + right.left), y: ceil_2digit(left.y + right.top))
}

public protocol TagLayoutItem {
    var margin: UIEdgeInsets { get set }
    var origin: CGPoint { get set }
    var contentSize: CGSize { get }
    func featWidth(_ width: CGFloat) -> CGSize
    func resetReactionView(_ image: UIImage)
}

protocol TagLayoutEngine {
    var padding: UIEdgeInsets { get set }
    var subviews: [TagLayoutItem] { get set }
    func layout(containerSize: CGSize) -> CGSize
}

/// 新需求，同一个group
final class TagLayoutEngineImpl: TagLayoutEngine {
    var padding: UIEdgeInsets = .zero

    var subviews: [TagLayoutItem] = []

    func layout(containerSize: CGSize) -> CGSize {
        if self.subviews.isEmpty { return .zero }
        /// fix containerSize
        var containerSize = containerSize
        containerSize.width = containerSize.width < 0 ? CGFloat.greatestFiniteMagnitude : containerSize.width

        /// 当前绘制行已占用的宽度
        var currRowWidth: CGFloat = 0
        /// 所有绘制行的总行高
        var allRowHeight: CGFloat = 0
        /// 所有绘制item中最大的高
        var maxItemHeight: CGFloat = 0
        /// 所有绘制行中最大的行宽
        var maxRowWidth: CGFloat = 0

        /// 每个item绘制的origin，实时计算
        var origin = CGPoint(x: 0, y: self.padding.top)

        for i in 0..<self.subviews.count {
            let subview = self.subviews[i]
            /// 绘制该item实际需要的size，需要+margin
            var currentItemSize = subview.contentSize + subview.margin
            /// 单个item宽度超出了宽度限制
            if currentItemSize.width > containerSize.width {
                subview.featWidth(containerSize.width - subview.margin.left - subview.margin.right)
                currentItemSize = subview.contentSize + subview.margin
            }
            origin.x = currRowWidth + self.padding.left
            currRowWidth += currentItemSize.width
            maxItemHeight = max(maxItemHeight, currentItemSize.height)
            /// 需要换行显示该item
            if currRowWidth > containerSize.width {
                currRowWidth -= currentItemSize.width
                maxRowWidth = max(maxRowWidth, currRowWidth)
                currRowWidth = currentItemSize.width
                allRowHeight += maxItemHeight
                origin.y += maxItemHeight
                origin.x = self.padding.left
            }
            /// 得到该item开始绘制的origin，去掉了margin
            self.subviews[i].origin = origin + subview.margin
        }
        allRowHeight += maxItemHeight
        maxRowWidth = max(maxRowWidth, currRowWidth)
        /// 需要处理padding，如：计算的宽高是(100, 100)，处理padding之后size为(97, 94)，此为我实际绘制所有内容需要的size
        return CGSize(
            width: maxRowWidth + self.padding.left + self.padding.right,
            height: allRowHeight + self.padding.top + self.padding.bottom
        )
    }
}

public protocol TagItem: TagLayoutItem {
    associatedtype TagItemModel
    var model: TagItemModel? { get set }
}

public final class TagView<TagItemImpl: TagItem>: UIView where TagItemImpl: UIView {
    public fileprivate(set) var tags: [TagItemImpl] = []

    var layoutEngine: TagLayoutEngine!

    public var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            if preferredMaxLayoutWidth != oldValue {
                layoutWithLayoutEngine()
            }
        }
    }

    public var padding: UIEdgeInsets {
        set {
            layoutEngine.padding = newValue
        } get {
            return layoutEngine.padding
        }
    }

    public override var intrinsicContentSize: CGSize {
        if tags.isEmpty {
            return .zero
        }

        return computeLayoutSize(with: super.intrinsicContentSize)
    }

    public override func addSubview(_ view: UIView) {
        if view is TagItemImpl {
            super.addSubview(view)
        } else {
            assertionFailure()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        for i in 0..<subviews.count {
            if let subview = subviews[i] as? TagItemImpl {
                subview.frame.origin = subview.origin
                subview.frame.size = subview.contentSize
            }
        }
    }

    private func updateTags() {
        layoutEngine.subviews = self.tags
        //            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(layoutWithLayoutEngine), object: nil)
        //            self.perform(#selector(layoutWithLayoutEngine), with: self, afterDelay: 0)
        layoutWithLayoutEngine()
    }

    private func layoutWithLayoutEngine() {
        if !computeLayoutSize(with: self.frame.size).equalTo(self.frame.size) {
            self.invalidateIntrinsicContentSize()
        }
        syncTagsToSubviews()
        setNeedsLayout()
    }

    private func computeLayoutSize(with containerSize: CGSize) -> CGSize {
        var containerSize = containerSize
        if containerSize.width < 0 {
            containerSize.width = CGFloat.greatestFiniteMagnitude
        }

        if preferredMaxLayoutWidth > 0 {
            containerSize.width = preferredMaxLayoutWidth
        }

        return layoutEngine.layout(containerSize: containerSize)
    }

    private func syncTagsToSubviews() {
        while !subviews.isEmpty {
            subviews.last?.removeFromSuperview()
        }

        for i in 0 ..< tags.count {
            addSubview(tags[i])
        }
    }

    init() {
        super.init(frame: .zero)
        self.layoutEngine = TagLayoutEngineImpl()
    }

    init(frame: CGRect = .zero, layoutEngine: TagLayoutEngine) {
        super.init(frame: frame)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutEngine = TagLayoutEngineImpl()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
//        print("reaction view deinit.")
    }

    public func setTags(_ tags: [TagItemImpl]) {
        self.tags = tags
        updateTags()
    }

    func getTag(_ remotionKey: String) -> TagItemImpl? {
        for tag in tags {
            guard let model = tag.model as? ReactionInfo else { return nil }
            if model.reactionKey == remotionKey {
                return tag
            }
        }
        return nil
    }

    func addTag(_ tag: TagItemImpl) {
        tags.append(tag)
        updateTags()
    }

    func addTag(_ tag: TagItemImpl, at index: Int) {
        tags.insert(tag, at: index)
        updateTags()
    }

    func removeTag(at index: Int) {
        tags.remove(at: index)
        updateTags()
    }

    func removeTag(_ tag: TagItemImpl) {
        guard let index = tags.firstIndex(of: tag) else {
            return
        }
        tags.remove(at: index)
        updateTags()
    }

    func removeAllTag() {
        tags.removeAll()
        updateTags()
    }
}
