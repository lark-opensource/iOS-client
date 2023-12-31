//
//  ReactionViewComponent.swift
//  LarkThread
//
//  Created by qihongye on 2019/2/25.
//

import UIKit
import Foundation
import LarkModel
import AsyncComponent
import LarkMessageBase

public final class ReactionViewComponent<C: ComponentContext>: ASComponent<ReactionViewComponent.Props, EmptyState, LarkMessageCore.ReactionView, C> {
    public final class Props: ASComponentProps {
        public var padding: UIEdgeInsets = .zero
        public var textColor: UIColor = UIColor.ud.textCaption
        public var reactions: [Reaction] = []
        public var getChatterDisplayName: ((Chatter) -> String)?
        public var tagBgColor: UIColor = UIColor.ud.N900.withAlphaComponent(0.06)
        public var separatorColor: UIColor = UIColor.ud.N400
        public var identifier: String = ""
        public weak var delegate: ReactionViewDelegate?
    }

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
    }

    /// 布局相关
    private var layoutEngine: ReactionLayoutEngine = ReactionLayoutEngineImpl()
    private var layoutItems: [ReactionTagLayoutItem] = []
    /// 在sizeToFit和update()中针对reactionTags的存取做防护
    private let lock = NSLock()
    /// 针对ReactionTagView定制的Factory，产生ReactionTag
    private let tagFactory = ReactionTagFactory()
    /// 用来保存完整计算后的数据，待update()使用
    private var reactionTags: [ReactionTag] = []

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        if self.layoutEngine.preferMaxLayoutWidth == 0 { self.layoutEngine.preferMaxLayoutWidth = size.width }
        let size = self.layoutEngine.layout(containerSize: size)
        let reactionTags = self.tagFactory.createTags(self.layoutItems.map({ ($0.reactionTagModel(), $0.reactionTagLayout()) }))
        self.lock.lock()
        self.reactionTags = reactionTags
        self.lock.unlock()
        return size
    }

    public override func update(view: ReactionView) {
        super.update(view: view)
        view.identifier = props.identifier
        self.lock.lock()
        view.tags = self.reactionTags
        self.lock.unlock()
        view.syncTagsToSubviews()
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        self.layoutEngine.padding = new.padding
        self.layoutEngine.preferMaxLayoutWidth = 0
        self.layoutItems = new.reactions.compactMap({ (reaction) -> ReactionTagLayoutItem? in
            guard let layout = ReactionTagLayoutItem(reaction: reaction, displayName: new.getChatterDisplayName, delegate: new.delegate) else { return nil }
            layout.tagBgColor = new.tagBgColor
            layout.separatorColor = new.separatorColor
            layout.textColor = new.textColor
            return layout
        })
        self.layoutEngine.semaphore.wait()
        self.layoutEngine.subviews = self.layoutItems
        self.layoutEngine.semaphore.signal()
        return true
    }
}
