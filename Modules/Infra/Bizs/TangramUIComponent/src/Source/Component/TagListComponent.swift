//
//  TagListComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/5/17.
//

import UIKit
import Foundation
import TangramComponent

public final class TagListComponentProps: Props {
    public var tagInfos: [TagInfo] = []
    public var font: UIFont = TagListView.defaultFont
    public var numberOfLines: Int = 1 // 最多显示多少行

    public init() {}

    public func clone() -> TagListComponentProps {
        let clone = TagListComponentProps()
        clone.tagInfos = tagInfos.map({ $0.copy() })
        clone.font = font.copy() as? UIFont ?? TagListView.defaultFont
        clone.numberOfLines = numberOfLines
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? TagListComponentProps else { return false }
        return tagInfos == old.tagInfos &&
        font == old.font &&
        numberOfLines == old.numberOfLines
    }
}

public final class TagListComponent<C: Context>: RenderComponent<TagListComponentProps, TagListView, C> {
    private var rwLock: pthread_rwlock_t = pthread_rwlock_t()
    var tags: [TagListView.TagItem] = []

    public override var isSelfSizing: Bool {
        return true
    }

    public override init(layoutComponent: BaseLayoutComponent? = nil, props: TagListComponentProps, style: RenderComponentStyle = RenderComponentStyle(), context: C? = nil) {
        super.init(layoutComponent: layoutComponent, props: props, style: style, context: context)
        pthread_rwlock_init(&rwLock, nil)
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        let (tagSize, tags) = TagListView.layout(size: size, tagInfos: props.tagInfos, font: props.font, numberOfLines: props.numberOfLines)
        pthread_rwlock_wrlock(&rwLock)
        self.tags = tags
        pthread_rwlock_unlock(&rwLock)
        return tagSize
    }

    public override func create(_ rect: CGRect) -> TagListView {
        return TagListView(frame: rect, tags: self.tags, font: props.font)
    }

    public override func update(_ view: TagListView) {
        super.update(view)
        pthread_rwlock_rdlock(&rwLock)
        view.update(tags: self.tags, font: props.font)
        pthread_rwlock_unlock(&rwLock)
    }
}
