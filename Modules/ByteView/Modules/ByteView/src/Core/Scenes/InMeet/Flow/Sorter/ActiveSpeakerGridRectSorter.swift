//
//  ActiveSpeakerGridRectSorter.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/2/1.
//

import Foundation

class ActiveSpeakerGridRectSorter {
    @RwAtomic
    private var currentGridInfos: [ByteviewUser] = []
    private let myself: ByteviewUser

    init(myself: ByteviewUser) {
        self.myself = myself
    }

    // https://bytedance.feishu.cn/docs/doccnbigp3wujKQurgnNG71YDQd#
    func sort(scoreInfos: [GridSortInputEntry], context: InMeetGridSortContext) -> [ByteviewUser] {
        let (startIndex, endIndex, pageSize) = visibleRange(from: context)

        let infos = GridSortOrderedInfos(scoredInfos: scoreInfos)

        // 1. 保存之前的首屏和当前屏
        let resultPage = newPageWithNewScores(scoreInfos: infos, context: context, visibleRange: (startIndex..<endIndex), pageSize: pageSize)
        // 2. 特殊宫格预处理
        handleSpecialGrids(resultPage, infos: infos, context: context, pageSize: pageSize)
        // 3. 处理首屏特殊逻辑
        preprocessFirstPage(resultPage, infos: infos, context: context, pageSize: pageSize)
        // 4. 在剩余空位按序填充其他参会人
        resultPage.insertOnNull(infos.enumerated)
        // 5. 排序结果整理
        let normalized = normalizeResult(resultPage, context: context)
        currentGridInfos = normalized.map { $0.pid }

        return currentGridInfos
    }

    private func visibleRange(from context: InMeetGridSortContext) -> (Int, Int, Int) {
        if case .range(let start, let end, let size) = context.displayInfo.visibleRange {
            return (start, end, size)
        } else {
            return (0, 0, 4)
        }
    }

    /// 根据上一次的宫格排序结果和新一轮得分排序，结合参会人是否依然在会中，创建新一轮宫格排序对象；保证在会中的参会人依然在相同位置
    private func newPageWithNewScores(scoreInfos: GridSortOrderedInfos, context: InMeetGridSortContext, visibleRange: Range<Int>, pageSize: Int) -> RectSortPage {
        let resultPage = RectSortPage(initialCapacity: currentGridInfos.count, firstPageSize: pageSize)

        let firstPageRange = (0..<pageSize).clamped(to: 0..<currentGridInfos.count)
        let clampedVisibleRange = visibleRange.clamped(to: 0..<currentGridInfos.count)
        let savedRange = [firstPageRange, clampedVisibleRange].joined()
        for i in savedRange {
            let grid = currentGridInfos[i]
            if let removed = scoreInfos.remove(with: grid) {
                _ = resultPage.replace(removed, at: i)
            }
        }
        return resultPage
    }

    /// 处理特殊宫格：自己、焦点视频、AS
    private func handleSpecialGrids(_ resultPage: RectSortPage, infos: GridSortOrderedInfos, context: InMeetGridSortContext, pageSize: Int) {
        // 如果之前首页没有自己，在首位添加自己。首次排序、隐藏自己、隐藏非视频等场景会出现这种情况
        if let me = infos.remove(with: myself) {
            let removed = resultPage.insertOrReplace(me, in: 0..<1)
            infos.insert(removed)
        }

        // 首屏第二位固定为焦点视频（如果有）
        if let focusID = context.focusingParticipantID, focusID != myself {
            // original: 新的焦点视频在上次排序中的位置
            if let original = resultPage.index(where: { $0.pid == focusID }), original != 1 {
                if original < pageSize {
                    // 新焦点视频原来在首屏时，直接与宫格第二位交换位置
                    resultPage.swapAt(original, j: 1)
                } else if let focusItem = resultPage.remove(at: original) {
                    // 新焦点视频原来在非首屏，从原来位置移除，添加到第二位，把第二位被替换的人（如果有）存到 infos 里
                    let removed = resultPage.insertOrReplace(focusItem, in: 1..<2)
                    infos.insert(removed)
                }
            } else if let focusInfo = infos.remove(with: focusID) {
                // 新焦点视频不在原首屏或当前屏，添加到第二位，并把被替换的人存到 infos 里
                let removed = resultPage.insertOrReplace(focusInfo, in: 1..<2)
                infos.insert(removed)
            }
        }

        // 如果首页和当前页都不存在 AS，将 AS 插入到首页
        if let asID = context.currentActiveSpeaker, resultPage.index(where: { $0.pid == asID }) == nil, let asInfo = infos.remove(with: asID) {
            let removed = resultPage.insertOrReplace(asInfo, in: 0..<pageSize)
            infos.insert(removed)
        }
    }

    /// 处理处理符合要求的参会人上下首屏的特殊逻辑
    private func preprocessFirstPage(_ resultPage: RectSortPage, infos: GridSortOrderedInfos, context: InMeetGridSortContext, pageSize: Int) {
        let firstPageRange = 0..<pageSize

        // 1. 有资格的人尝试上首屏
        for info in infos.filter({ $0.action.isEnterFirstPageCandidate }) {
            if info.rank < resultPage.lastSortRankInFirstPage {
                _ = infos.remove(with: info.pid)
                let replaced = resultPage.insertOrReplace(info, in: firstPageRange)
                infos.insert(replaced)
            }
        }
        // 2. 失去资格的人检查是否需要下首屏
        for (index, info) in resultPage.enumerated(in: firstPageRange).filter({ $0.1.action.isExitFirstPageCandidate && !$0.1.shouldStayInFirstPage }) {
            if let first = infos.first, first.rank < info.rank {
                _ = infos.remove(with: first.pid)
                let removed = resultPage.replace(first, at: index)
                infos.insert(removed)
            }
        }
    }

    /// 整理最终结果，处理当前屏是最后一屏的特殊逻辑
    private func normalizeResult(_ resultPage: RectSortPage, context: InMeetGridSortContext) -> [GridSortInputEntry] {
        // 处理数据不够导致当前屏需要前移的情况
        var sortResult = resultPage.normalized

        // 宫格视图下，如果(作为最后一屏的)当前屏中 AS 被移到上一屏，将其复原到当前屏，保证用户在当前屏依然能看到 AS
        if context.displayInfo.displayMode == .gridVideo,
            let asID = context.currentActiveSpeaker,
           // beforeNomalized: 进行前移之前 AS 宫格的位置
            let beforeNomalized = resultPage.index(of: asID),
           // afterNomalized: 进行前移之后 AS 宫格的位置
            let afterNomalized = sortResult.firstIndex(where: { $0.pid == asID }),
           // 如果两者不匹配，且当前宫格总数量允许将两者互换
            beforeNomalized != afterNomalized && sortResult.count > beforeNomalized {
            // 交换位置，让 AS 宫格位置相对上次维持不变
            sortResult.swapAt(beforeNomalized, afterNomalized)
        }

        return sortResult
    }
}
