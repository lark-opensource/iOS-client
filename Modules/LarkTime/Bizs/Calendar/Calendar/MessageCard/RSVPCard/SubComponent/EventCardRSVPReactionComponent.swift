//
//  EventCardRSVPReactionComponent.swift
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

public struct RSVPReactionInfo {
    var type: ReplyStatus
    var justShowCount: Bool = false
    var userNameAndIds: [(String, String)]
}

final class EventCardRSVPReactionComponentProps: ASComponentProps {
    var userOwnChatterId: String?
    var rsvpList: [RSVPReactionInfo] = []
    var didSelectChat: ((String) -> Void)?
    var didSelectReaction: ((ReplyStatus) -> Void)?
    var didTapReactionMore: ((ReplyStatus) -> Void)?
    var maxWidth: CGFloat = 0
    var forNeedAction: Bool = false
}

final class EventCardRSVPReactionComponent<C: Context>: ASComponent<EventCardRSVPReactionComponentProps, EmptyState, ReactionView, C> {
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

        view.reactionTapMore = {[weak self] type in
            self?.props.didTapReactionMore?(type)
        }
    }

    override func willReceiveProps(_ old: EventCardRSVPReactionComponentProps, _ new: EventCardRSVPReactionComponentProps) -> Bool {
        var newRsvpList: [RSVPReactionInfo] = []
        
        if new.forNeedAction {
            newRsvpList = calculateLayoutData(rsvpList: new.rsvpList, userOwnChatterId: new.userOwnChatterId ?? "", maxWidth: new.maxWidth - 25)
        } else {
            newRsvpList = new.rsvpList
        }
        self.layoutEngine.padding = UIEdgeInsets(top: 5, left: 10, bottom: -3, right: 9)
        self.layoutEngine.preferMaxLayoutWidth = 0
        self.layoutItems = newRsvpList.compactMap { item in
            guard let layout = ReactionTagLayoutItem(rsvpStatusType: item.type,
                                                     justShowCount: item.justShowCount,
                                                     userNameAndIds: item.userNameAndIds,
                                                     ownerChatterId: new.userOwnChatterId ?? "") else {
                return nil
            }
            return layout
        }

        self.layoutEngine.semaphore.wait()
        self.layoutEngine.subviews = self.layoutItems
        self.layoutEngine.semaphore.signal()
        return true
    }
}

extension EventCardRSVPReactionComponent {
    /*
     计算目标数据格式：
     0. 将待回复的自己单独置于首位。
     1. 终止前待回复reaction打散存储。 举例： .needsAction, [("0","a"),("1","b")] 转为 .needsAction, [("0","a")] 和 .needsAction, [("1","b")]
     2. 待回复 末尾终止位，展位onlyShowCount所需格式。 举例： 保持.needsAction, [("0","a"),("1","b")]， onlyShowCount为True Layout内部会转为 +2more 文案
     */
    private func calculateLayoutData(rsvpList: [RSVPReactionInfo], userOwnChatterId: String, maxWidth: CGFloat) -> [RSVPReactionInfo] {
        if rsvpList.isEmpty { return rsvpList }
        
        let needActionsList = rsvpList.map { item in
            item.userNameAndIds.map {
                return RSVPReactionInfo(type: item.type, justShowCount: item.justShowCount, userNameAndIds: [$0])
            }
        }.flatMap { $0 }
        
        /// 获取 聚合数字块的pos 及是否有more（more就代表聚合块）
        let (pos, hasMore) = calCompressPosition(needActionsList: needActionsList, maxWidth: maxWidth)
        
        let finalReactionList = combineNeedActionReaction(pos: pos, hasMore: hasMore, rsvpList: rsvpList)
        
        return finalReactionList
    }
    
    private func combineNeedActionReaction(pos: Int, hasMore: Bool, rsvpList: [RSVPReactionInfo]) -> [RSVPReactionInfo] {
        if rsvpList.isEmpty { return rsvpList }
        var needActionsList: [RSVPReactionInfo] = []
        var originalNeedActionsList = rsvpList
        var singleAddCount = pos
        for item in originalNeedActionsList[0].userNameAndIds {
            if singleAddCount > 0 {
                needActionsList += [RSVPReactionInfo(type: .needsAction, userNameAndIds: [item])]
            } else {
                break
            }
            singleAddCount -= 1
        }
        /// 添加needAction聚合的数字块
        if hasMore {
            let ranger = pos > 0 ? pos : 0
            for _ in 0..<ranger {
                if originalNeedActionsList.isEmpty { break }
                originalNeedActionsList[0].userNameAndIds.remove(at: 0)
                originalNeedActionsList[0].justShowCount = true
            }
            
            if !originalNeedActionsList.isEmpty && !originalNeedActionsList[0].userNameAndIds.isEmpty {
                needActionsList += originalNeedActionsList
            }
        }
        return needActionsList
    }
    
    /// 计算  聚合数字块的pos 及是否有more（more就代表聚合块）
    private func calCompressPosition(needActionsList: [RSVPReactionInfo], maxWidth: CGFloat) -> (Int, Bool) {
        var pos = 0
        var hasMore = false
        var tCurrentWidth: CGFloat = 0
        var isFirst: Bool = true
        for info in needActionsList {
            if info.userNameAndIds.isEmpty { break }
            let item = info.userNameAndIds[0]
            var appendWidth = getNeedActionNameWidth(name: item.0, maxWidth: maxWidth) + 6
            if isFirst {
                appendWidth -= 6
                isFirst = false
            }
            if tCurrentWidth + appendWidth >= maxWidth {
                let moreWidth = I18n.Calendar_G_DetailMorePeople(count: needActionsList.count - pos).getWidth(font: UIFont.ud.caption1) + 6 + 16
                hasMore = true
                if tCurrentWidth + moreWidth > maxWidth {
                    pos -= 1
                }
                break
            } else {
                tCurrentWidth += appendWidth
                pos += 1
            }
        }
        return (pos, hasMore)
    }
}

// needAction单块的宽度最长不超过maxWidth/2
private func getNeedActionNameWidth(name: String, maxWidth: CGFloat) -> CGFloat {
    let nameWidth = name.getWidth(font: UIFont.ud.caption1) + 16
    if nameWidth > maxWidth / 2 {
        return maxWidth / 2
    } else {
        return nameWidth
    }
}
