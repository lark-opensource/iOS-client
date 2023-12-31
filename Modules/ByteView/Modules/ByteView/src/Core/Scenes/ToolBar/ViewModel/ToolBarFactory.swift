//
//  ToolBarFactory.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/7.
//

import Foundation

class ToolBarFactory {
    private let meeting: InMeetMeeting
    private let resolver: InMeetViewModelResolver
    weak var provider: ToolBarServiceProvider?

    private static let allItems: [ToolBarItemType: ToolBarItem.Type] = [
        .microphone: ToolBarMicItem.self,
        .camera: ToolBarCameraItem.self,
        .chat: ToolBarChatItem.self,
        .speaker: ToolBarSpeakerItem.self,
        .security: ToolBarSecurityItem.self,
        .share: ToolBarShareItem.self,
        .record: ToolBarRecordItem.self,
        .participants: ToolBarParticipantsItem.self,
        .more: ToolBarMoreItem.self,
        .leaveMeeting: ToolBarLeaveMeetingItem.self,
        .subtitle: ToolBarSubtitleItem.self,
        .effects: ToolBarEffectsItem.self,
        .settings: ToolBarSettingsItem.self,
        .handsup: ToolBarHandsUpItem.self,
        .interpretation: ToolBarInterpretationItem.self,
        .interviewPromotion: ToolBarInterviewPromotionItem.self,
        .interviewSpace: ToolBarInterviewSpaceItem.self,
        .countDown: ToolBarCountdownItem.self,
        .askHostForHelp: ToolBarAskHostForHelpItem.self,
        .rejoinBreakoutRoom: ToolBarBreakoutRejoinItem.self,
        .breakoutRoomHostControl: ToolBarBreakoutControlItem.self,
        .live: ToolBarLiveItem.self,
        .switchAudio: ToolBarSwitchAudioItem.self,
        .room: ToolBarRoomItem.self,
        .roomControl: ToolbarRoomControlItem.self,
        .vote: ToolBarVoteItem.self,
        .notes: ToolBarNotesItem.self,
        .transcribe: ToolBarTranscribeItem.self,
        .myai: ToolBarMyAIItem.self,
        .reaction: ToolBarReactionItem.self,
        .roomCombined: ToolBarRoomCombinedItem.self
    ]

    private var cache: [ToolBarItemType: ToolBarItem] = [:]

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.resolver = resolver
    }

    func resolveToolbarItems() {
        let pairs = Self.allItems
            .map { resolve(itemType: $0.key, clazz: $0.value) }
            .map { ($0.itemType, $0) }
        self.cache = Dictionary(pairs) { $1 }
        cache.forEach { $0.value.initialize() }
    }

    func phoneView(for itemType: ToolBarItemType) -> PhoneToolBarItemView {
        let item = item(for: itemType)
        switch itemType {
        case .microphone: return PhoneToolBarMicView(item: item)
        case .camera: return PhoneToolBarCameraView(item: item)
        case .participants: return PhoneToolBarParticipantsView(item: item)
        default: return PhoneToolBarItemView(item: item)
        }
    }

    func padItemView(for itemType: ToolBarItemType) -> PadToolBarItemView {
        let subItemTypes = ToolBarConfiguration.combination[itemType]
        if let subItemTypes = subItemTypes, !subItemTypes.isEmpty {
            return padItemCombinedView(for: itemType, subItemTypes: subItemTypes)
        }
        return padSubItemView(for: itemType)
    }

    private func padItemCombinedView(for itemType: ToolBarItemType, subItemTypes: [ToolBarItemType]) -> PadToolBarCombinedView {
        let item = item(for: itemType)
        let subItemViews = subItemTypes.map { self.padSubItemView(for: $0) }
        return PadToolBarCombinedView(item: item, itemViews: subItemViews)
    }

    private func padSubItemView(for subItemType: ToolBarItemType) -> PadToolBarItemView {
        let item = subItem(for: subItemType)
        switch subItemType {
        case .microphone:
            return PadToolBarMicView(item: item)
        case .participants:
            return PadToolBarParticipantsView(item: item)
        case .camera:
            return PadToolBarCameraView(item: item)
        case .speaker:
            return PadToolBarItemView(item: item)
        case .leaveMeeting:
            return PadToolBarLeaveMeetingView(item: item)
        case .security, .share, .record:
            return PadToolBarTitledView(item: item)
        case .notes:
            return PadToolBarNotesView(item: item)
        case .reaction:
            return PadToolBarReactionView(item: item)
        case let type where ToolBarConfiguration.padRightItems.contains(type) && type != .more:
            return PadToolBarTitledView(item: item)
        default:
            return PadToolBarItemView(item: item)
        }
    }

    func navigationBarView(for itemType: ToolBarItemType) -> NavigationBarItemView {
        let item = item(for: itemType)
        switch itemType {
        case .microphone: return NavigationBarMicView(item: item)
        case .camera: return NavigationBarCameraView(item: item)
        case .participants: return NavigationBarParticipantsView(item: item)
        default: return NavigationBarItemView(item: item)
        }
    }

    func item(for itemType: ToolBarItemType) -> ToolBarItem {
        guard let item = cache[itemType] else {
            if let subItemTypes = ToolBarConfiguration.combination[itemType] {
                return combinedItem(for: itemType, subItemTypes: subItemTypes)
            } else {
                return subItem(for: itemType)
            }
        }
        return item
    }

    private func subItem(for subItemType: ToolBarItemType) -> ToolBarItem {
        guard let item = cache[subItemType] else {
            assertionFailure("Cannot find ToolBarItem for type \(subItemType)")
            return ToolBarItem(meeting: meeting, provider: provider, resolver: resolver)
        }
        return item
    }

    private func combinedItem(for itemType: ToolBarItemType, subItemTypes: [ToolBarItemType]) -> ToolBarItem {
        guard let item = cache[itemType] else {
            assertionFailure("Cannot find ToolBarItem for combined type \(itemType)")
            let combinedItem = ToolBarCombinedItem(meeting: meeting, provider: provider, resolver: resolver)
            let subItems = subItemTypes.map { self.subItem(for: $0) }
            combinedItem.subItems = subItems
            return combinedItem
        }
        if let combinedItem = item as? ToolBarCombinedItem, combinedItem.subItems.isEmpty {
            assertionFailure("Cannot find ToolBarItem for combined subType \(itemType)")
            let subItems = subItemTypes.map { self.subItem(for: $0) }
            combinedItem.subItems = subItems
            return combinedItem
        }
        return item
    }

    private func resolve(itemType: ToolBarItemType, clazz: ToolBarItem.Type) -> ToolBarItem {
        assertMain()
        if let obj = cache[itemType] {
            return obj
        }
        let obj = clazz.init(meeting: meeting, provider: provider, resolver: resolver)
        if let combinedObj = obj as? ToolBarCombinedItem,
           let subItemTypes = ToolBarConfiguration.combination[itemType] {
            var subItems: [ToolBarItem] = []
            subItemTypes.forEach { subItemType in
                if let clazz = Self.allItems[subItemType] {
                    let subItem = resolve(itemType: subItemType, clazz: clazz)
                    subItems.append(subItem)
                }
            }
            combinedObj.subItems = subItems
        }
        cache[itemType] = obj
        return obj
    }

    static func combinedType(by subItemType: ToolBarItemType) -> ToolBarItemType? {
        ToolBarConfiguration.combination.first { $0.value.contains(subItemType) }?.key
    }

    /// 给定一个顺序数组 order 和它的子集 target，查找一个未在子集中的元素的插入位置
    static func insertPosition(of itemType: ToolBarItemType,
                               target: [ToolBarItemType],
                               order: [ToolBarItemType]) -> Int {
        assert(!target.contains(itemType))
        assert(order.contains(itemType))
        assert(target.count <= order.count)
        var i = 0
        var j = 0
        while i < target.count && j < order.count {
            if target[i] == order[j] {
                i += 1
                j += 1
            } else if order[j] == itemType {
                return i
            } else {
                j += 1
            }
        }
        return i
    }
}
