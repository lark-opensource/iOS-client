//
//  EventCardOldRSVPReactionComponent.swift
//  Calendar
//
//  Created by pluto on 2023/1/15.
//

import UIKit
import UniverseDesignIcon
import Foundation
import LarkModel
import CalendarFoundation
import AsyncComponent
import EEFlexiable
/*
 Reaction模块，无现成开放接口，故暂时复用Reaction Component布局，仅做了数据适配修改
 */

final class EventCardOldRSVPReactionComponent<C: Context>: ASComponent<EventCardRSVPReactionComponentProps, EmptyState, ReactionView, C> {
    
    /// 布局相关
    private var layoutEngine: ReactionLayoutEngine = ReactionLayoutEngineImpl()
    private var layoutItems: [ReactionTagLayoutItem] = []
    /// 在sizeToFit和update()中针对reactionTags的存取做防护
    private let lock = NSLock()
    /// 针对ReactionTagView定制的Factory，产生ReactionTag
    private let tagFactory = ReactionTagFactory()
    /// 用来保存完整计算后的数据，待update()使用
    private var reactionTags: [ReactionTag] = []
    
    override var isComplex: Bool {
        return true
    }

    override var isSelfSizing: Bool {
        return true
    }
    
    override func sizeToFit(_ size: CGSize) -> CGSize {
        if self.layoutEngine.preferMaxLayoutWidth == 0 { self.layoutEngine.preferMaxLayoutWidth = size.width }
        let size = self.layoutEngine.layout(containerSize: size)
        let reactionTags = self.tagFactory.createTags(self.layoutItems.map({ ($0.reactionTagModel(), $0.reactionTagLayout()) }))
        self.lock.lock()
        self.reactionTags = reactionTags
        self.lock.unlock()
        return size
    }

    override func update(view: ReactionView) {
        super.update(view: view)
        self.lock.lock()
        view.tags = self.reactionTags
        self.lock.unlock()
        view.syncTagsToSubviews()
        view.showProfile = { [weak self] chattedID in
            self?.props.didSelectChat?(chattedID)
        }
        
        view.reactionDidTapped = { [weak self] type in
            self?.props.didSelectReaction?(type)
        }
    }

    override func willReceiveProps(_ old: EventCardRSVPReactionComponentProps, _ new: EventCardRSVPReactionComponentProps) -> Bool {
        self.layoutEngine.padding = UIEdgeInsets(top: 9, left: 9, bottom: -3, right: 9)
        self.layoutEngine.preferMaxLayoutWidth = 0
        self.layoutItems = new.rsvpList.compactMap({ item -> ReactionTagLayoutItem? in
            guard let layout = ReactionTagLayoutItem(rsvpStatusType: item.type, justShowCount: false, userNameAndIds: item.userNameAndIds, ownerChatterId: "" ) else { return nil }
            return layout
        })
        self.layoutEngine.semaphore.wait()
        self.layoutEngine.subviews = self.layoutItems
        self.layoutEngine.semaphore.signal()
        return true
    }
}
