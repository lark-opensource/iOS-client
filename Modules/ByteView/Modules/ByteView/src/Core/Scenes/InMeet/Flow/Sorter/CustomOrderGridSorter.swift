//
//  CustomOrderGridSorter.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/2.
//

import Foundation
import ByteViewNetwork

class CustomOrderGridSorter: GridSorter {
    private var shareIndex: Int?
    private let myself: ByteviewUser

    init(myself: ByteviewUser) {
        self.myself = myself
    }

    // MARK: - Public

    func sort(participants: [Participant], with context: InMeetGridSortContext) -> SortResult {
        // 检查无需重排或快速排序的路径
        if let shortPathResult = handleShortPath(context: context) {
            return shortPathResult
        }

        // === 排序 pipeline begin ===

        // 1. 过滤符合条件的参会人
        let participantMap = filterParticipants(participants, context: context)
        // 2. 对参会人排序
        var sortResult = gridSort(participantMap: participantMap, context: context)
        // 3. phone 1:1 宫格视图特殊逻辑处理
        if shouldUseTileSort(context) {
            sortResult = normalize(sortResult: sortResult, context: context)
        }
        // 4. 处理兜底和共享宫格
        let finalResult = handleShareAndAS(sortResult, context: context)

        // === 排序 pipeline end ===

        return .sorted(finalResult)
    }

    // MARK: - Private

    private var observedChanges: Set<GridSortTrigger> {
        [.participants, .hideSelf, .hideNonVideo,
            .voiceMode, .displayInfo, .shareGridEnabled,
            .shareSceneType, .reorder, .isGridDragging]
    }

    private func handleShortPath(context: InMeetGridSortContext) -> SortResult? {
        // 处理用户手动调整宫格顺序
        // 对于拖动宫格来说，此时 isGridDragging 依然为 true，不会触发排序 pipeline。collectionView 回调 dragEnd 时会结合最新的参会人数据重新刷新；
        // 对于选择交换宫格顺序来说，此操作为轻量级局部顺序调整，也不需要触发排序 pipeline
        if let order = handleReorderAction(context: context) {
            return .sorted(order)
        }

        // 共享类型变更时，更新自身维护的共享宫格位置，并将其从 changedTypes 移除
        var intersection = context.changedTypes.intersection(observedChanges)
        if intersection.contains(.shareSceneType) {
            if [.none, .selfSharingScreen].contains(context.shareSceneType) {
                shareIndex = nil
            }
            intersection.subtract([.shareSceneType])
        }

        // 用户开始拖拽，直到拖拽结束期间，忽略一切排序
        if context.isGridDragging {
            return .unchanged
        }

        // 强制刷新时，走完整的排序 pipeline
        if context.isDirty {
            return nil
        }

        // 如果不需要重排，直接返回 unchanged
        if intersection.isEmpty {
            return .unchanged
        }

        // 对于共享宫格显示与否、displayMode 的变更是同步操作，直接基于上次的排序结果对共享和兜底宫格操作，无需走排序全路径
        if !context.changedTypes.isDisjoint(with: [.shareGridEnabled, .displayInfo]) {
            let lastSortResult = context.currentSortResult.filter {
                if case .participant = $0.type {
                    return true
                } else {
                    return false
                }
            }
            let quickSortResult = handleShareAndAS(lastSortResult, context: context)
            return .sorted(quickSortResult)
        }

        return nil
    }

    private func handleReorderAction(context: InMeetGridSortContext) -> [GridSortOutputEntry]? {
        guard context.changedTypes.contains(.reorder) else { return nil }
        switch context.reorderAction {
        case .swap(let i, let j):
            var order = context.currentSortResult
            if i < order.count && j < order.count {
                order.swapAt(i, j)
            }
            updateShareIndex(order: order, context: context)
            return order
        case .move(let from, let to):
            var order = context.currentSortResult
            if from < order.count && to < order.count {
                let removed = order.remove(at: from)
                order.insert(removed, at: to)
            }
            updateShareIndex(order: order, context: context)
            return order
        case .none:
            return nil
        }
    }

    private func updateShareIndex(order: [GridSortOutputEntry], context: InMeetGridSortContext) {
        if context.shareGridEnabled, let index = order.firstIndex(where: { $0.type == .share }) {
            shareIndex = index
        }
    }

    /// 预处理会中参会人，过滤出实际需要参与排序的参会人，以及这些参会人排序结果的展示策略
    private func filterParticipants(_ participants: [Participant], context: InMeetGridSortContext) -> [ByteviewUser: GridSortParticipant] {
        var newParticipants = participants

        if context.isHideSelf {
            newParticipants.removeAll(where: { $0.user == myself })
        }

        if context.isHideNonVideo {
            if context.isVoiceMode {
                // 语音模式下其他参会人均视为关闭摄像头
                newParticipants.removeAll(where: { $0.user != myself || $0.settings.isCameraMutedOrUnavailable })
            } else {
                newParticipants.removeAll(where: { $0.settings.isCameraMutedOrUnavailable })
            }
        }

        let gridSortParticipants = newParticipants.map { GridSortParticipant(participant: $0, strategy: .normal) }
        return Dictionary(gridSortParticipants.map { ($0.participant.user, $0) }, uniquingKeysWith: { $1 })
    }

    private func shouldUseTileSort(_ context: InMeetGridSortContext) -> Bool {
        context.isNewLayoutEnabled && context.displayInfo.displayMode == .gridVideo
    }

    // 根据最新的参会人列表、当前的排序结果，计算新一轮的宫格排序结果
    private func gridSort(participantMap: [ByteviewUser: GridSortParticipant], context: InMeetGridSortContext) -> [GridSortOutputEntry] {
        let isSyncedByHost = context.isGridOrderSyncing && !context.selfIsHost
        let currentOrder = isSyncedByHost ? context.orderFromServer : context.currentSortResult
        var result: [GridSortOutputEntry] = []
        var userMap = participantMap
        var idMap = Dictionary(participantMap.values.map { ($0.participant.user.id, $0) }, uniquingKeysWith: { $1 })

        // 对于当前还在会中的用户（存在于 userMap 或 idMap），按照自定义顺序排布
        for user in currentOrder {
            switch user.type {
            case .participant(let p):
                var existed = userMap[p.user]
                if existed == nil && p.user.deviceIdIsEmpty {
                    if let info = idMap[p.user.id], userMap[info.participant.user] != nil {
                        existed = info
                    }
                }
                if let existed = existed {
                    userMap.removeValue(forKey: existed.participant.user)
                    idMap.removeValue(forKey: existed.participant.user.id)
                    result.append(GridSortOutputEntry(type: .participant(existed.participant), strategy: existed.strategy))
                }
            case .activeSpeaker:
                // 上次排序结果中有兜底 AS 宫格，如果本次还需要，则保留兜底 AS 宫格的相对位置
                if participantMap.isEmpty && context.isHideNonVideo {
                    result.append(user)
                }
            case .share:
                // 上次排序结果中有共享宫格，如果本次还需要，则保留共享宫格的相对位置
                if context.shareGridEnabled {
                    shareIndex = result.count
                    if context.isPhone {
                        result.insert(.share, at: 0)
                    } else {
                        result.append(.share)
                    }
                }
            }
        }

        // 对于新加入的用户，或者是因为筛选逻辑与其他 sorter 不同导致额外多出来的用户（userMap里剩余的用户），按照入会时间排序
        let left = userMap.values.sorted(by: { $0.participant.joinTime < $1.participant.joinTime })
        result.append(contentsOf: left.map { GridSortOutputEntry(type: .participant($0.participant), strategy: $0.strategy) })
        return result
    }

    private func handleShareAndAS(_ sortResult: [GridSortOutputEntry], context: InMeetGridSortContext) -> [GridSortOutputEntry] {
        var result = sortResult
        let isEmpty = !sortResult.contains { $0.type != .share }
        // 如果本次需要兜底，但上次排序结果中没有兜底宫格，则添加一个兜底 AS 宫格
        if isEmpty && context.isHideNonVideo {
            result.append(.activeSpeaker)
        }
        // 如果本次需要共享宫格，但上次排序结果中没有，则在 shareIndex 或默认位置添加
        let shareGrid = sortResult.first(where: { $0.type == .share })
        if context.shareGridEnabled && shareGrid == nil {
            let newShareIndex: Int
            if let shareIndex = shareIndex {
                newShareIndex = min(shareIndex, result.count)
            } else if context.isPhone || isEmpty {
                newShareIndex = 0
            } else {
                newShareIndex = 1
            }
            result.insert(.share, at: newShareIndex)
            shareIndex = newShareIndex
        }
        if result.isEmpty && context.displayInfo.displayMode == .gridVideo {
            // 如果排序的最终输出结果是空，宫格视图兜底展示 AS，防止宫格流展示空数据
            result.append(.activeSpeaker)
        }
        return result
    }

    // 如果是 phone 上 1:1 Layout 优化需求后的宫格视图，需要对最终排序结果处理，使其适配新的宫格布局
    private func normalize(sortResult: [GridSortOutputEntry], context: InMeetGridSortContext) -> [GridSortOutputEntry] {
        var map: [ByteviewUser: GridSortOutputEntry] = [:]
        let scoreInfos = sortResult.enumerated().compactMap { (i, entry) in
            switch entry.type {
            case .participant(let p):
                map[p.user] = entry
                return GridSortInputEntry(participant: p,
                                          myself: myself,
                                          asID: context.currentActiveSpeaker,
                                          focusedID: context.focusingParticipantID,
                                          rank: i,
                                          action: .none)
            // phone 上目前宫格流中不会出现共享宫格，因此无需考虑
            default:
                return nil
            }
        }

        var pages: [TileSortPage] = []
        let infos = GridSortOrderedInfos(scoredInfos: scoreInfos)
        while !infos.isEmpty {
            pages.append(newPage(infos: infos, context: context))
        }

        return pages.flatten().compactMap { map[$0.pid] }
    }

    private func newPage(infos: GridSortOrderedInfos, context: InMeetGridSortContext) -> TileSortPage {
        let page = TileSortPage()
        fillPage(page, infos: infos, context: context)
        return page
    }

    private func fillPage(_ page: TileSortPage, infos: GridSortOrderedInfos, context: InMeetGridSortContext) {
        var uninsertedItems: [TileSortItem] = []
        while !page.isFull, let top = infos.pop() {
            let item = TileSortItem(item: top)
            if !page.insert(item) {
                // 暂存插入不成功的 room 宫格，等该页处理完后需要重新放到 infos 中
                uninsertedItems.append(item)
            }
        }
        infos.insert(contentsOf: uninsertedItems)
    }
}
