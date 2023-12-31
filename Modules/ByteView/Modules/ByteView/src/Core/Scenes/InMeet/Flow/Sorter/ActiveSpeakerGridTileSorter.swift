//
//  ActiveSpeakerGridTileSorter.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/2/1.
//

import Foundation

class ActiveSpeakerGridTileSorter {
    private static let logger = Logger.ui
    @RwAtomic
    private var currentGridInfos: [TileSortResult] = []
    private let myself: ByteviewUser

    init(myself: ByteviewUser) {
        self.myself = myself
    }

    // https://bytedance.feishu.cn/docx/doxcnTmYqoMJ7sBa9994O8uy1ac
    func sort(scoreInfos: [GridSortInputEntry], context: InMeetGridSortContext) -> [ByteviewUser] {
        let currentPageIndex: Int
        if case .page(let index) = context.displayInfo.visibleRange {
            currentPageIndex = index
        } else {
            currentPageIndex = 0
        }

        let infos = GridSortOrderedInfos(scoredInfos: scoreInfos)
        var finalPages: [TileSortPage] = []

        // 1. 尽量保留原来的首屏和当前屏
        let firstPage = newPageWithNewScores(pageIndex: 0, scoreInfos: infos, context: context)
        let currentPage = currentPageIndex == 0 ? firstPage : newPageWithNewScores(pageIndex: currentPageIndex, scoreInfos: infos, context: context)
        // 2. 特殊宫格预处理
        handleSpecialGrids(firstPage: firstPage, currentPage: currentPage, infos: infos, context: context)
        // 3. 构造首屏
        buildFirstPage(firstPage, infos: infos, context: context)
        finalPages.append(firstPage)
        // 4. 构造首屏与当前屏之间的屏，这里不考虑因 room 导致的不饱和屏问题，当且仅当不饱和屏跟当前屏挨着时，使用当前屏填充前一页不饱和屏
        var cursor = 1
        while cursor < currentPageIndex && !infos.isEmpty {
            finalPages.append(newPage(infos: infos, context: context))
            cursor += 1
        }
        // 5. 构造当前屏
        if currentPageIndex != 0 {
            guard let lastPage = finalPages.last else { return [] }
            buildCurrentPage(currentPage, lastPage: lastPage, infos: infos, context: context)
            finalPages.append(currentPage)
        }
        // 6. 构造剩余所有屏
        while !infos.isEmpty {
            finalPages.append(newPage(infos: infos, context: context))
        }

        currentGridInfos = finalPages.flatten()
        return currentGridInfos.map { $0.pid }
    }

    /// 根据指定页数的上一次的宫格排序结果和新一轮得分排序，结合参会人是否依然在会中，创建新一轮宫格排序对象；
    /// 保证在会中的参会人依然在指定页数的相同位置
    private func newPageWithNewScores(pageIndex: Int, scoreInfos: GridSortOrderedInfos, context: InMeetGridSortContext) -> TileSortPage {
        let pageInfos = currentGridInfos.filter { $0.coordinate.pageIndex == pageIndex }
        let page = TileSortPage()
        for pageInfo in pageInfos {
            if let scoreInfo = scoreInfos.remove(with: pageInfo.pid) {
                page.insert(TileSortItem(item: scoreInfo), at: pageInfo.coordinate)
            }
        }
        return page
    }

    // 处理特殊宫格：自己、AS、焦点视频
    private func handleSpecialGrids(firstPage: TileSortPage, currentPage: TileSortPage, infos: GridSortOrderedInfos, context: InMeetGridSortContext) {
        // 如果之前首页没有自己，在首位添加自己。首次排序、隐藏自己、隐藏非视频等场景会出现这种情况
        if let me = infos.remove(with: myself) {
            let replaced = firstPage.replace(TileSortItem(item: me), at: (0, 0))
            infos.insert(contentsOf: replaced)
        }

        // 首屏第二位固定为焦点视频（如果有）
        if let focusID = context.focusingParticipantID, focusID != myself {
            var focusItem: TileSortItem?
            if let item = firstPage.remove(with: focusID) {
                focusItem = item
            } else if let item = currentPage.remove(with: focusID) {
                focusItem = item
            } else if let item = infos.remove(with: focusID) {
                focusItem = TileSortItem(item: item)
            }
            if let focusItem = focusItem {
                let targetCoordinate = focusItem.isRoom ? (1, 0) : (0, 1)
                let replaced = firstPage.replace(focusItem, at: targetCoordinate)
                infos.insert(contentsOf: replaced)
            }
        }

        // 如果首页和当前页都不存在 AS，将 AS 插入到首页
        if let asID = context.currentActiveSpeaker,
          !firstPage.contains(where: { $0.pid == asID }) && !currentPage.contains(where: { $0.pid == asID }),
          let asInfo = infos.remove(with: asID) {
            let replaced = firstPage.insertOrReplace(TileSortItem(item: asInfo))
            infos.insert(contentsOf: replaced)
        }
    }

    // 构造首屏，处理符合要求的参会人上下首屏
    private func buildFirstPage(_ firstPage: TileSortPage, infos: GridSortOrderedInfos, context: InMeetGridSortContext) {
        // 构造首页
        // a. 有资格的人尝试上首屏
        for info in infos.filter({ $0.action.isEnterFirstPageCandidate }) {
            if info.rank < firstPage.lastSortRank {
                _ = infos.remove(with: info.pid)
                let replaced = firstPage.insertOrReplace(TileSortItem(item: info))
                infos.insert(contentsOf: replaced)
            }
        }
        // b. 失去资格的人检查是否需要下首屏
        for info in firstPage.enumerated.filter({ $0.action.isExitFirstPageCandidate }) {
            if let first = infos.first, first.rank < info.rank {
                _ = infos.remove(with: first.pid)
                let removed = firstPage.remove(with: info.pid)
                var replaced = firstPage.insertOrReplace(TileSortItem(item: first))
                if let removed = removed {
                    replaced.append(removed)
                }
                infos.insert(contentsOf: replaced)
            }
        }

        // c. 如果首屏还没满，按照排名往首屏添加，此时不允许出现替换行为，即 room 宫格不能再把参会人宫格挤出首屏，
        // 因此如果首屏只剩一格但是待插入宫格是 room，则跳过 room 寻找下一个排名靠前的参会人
        fillPage(firstPage, infos: infos, context: context)
    }

    // 构造当前屏，必要时填充当前屏的上一屏
    private func buildCurrentPage(_ currentPage: TileSortPage, lastPage: TileSortPage, infos: GridSortOrderedInfos, context: InMeetGridSortContext) {
        // 上一屏不满，且 infos 里剩余的（如果有）都已经无法插入上一屏，用当前屏里的宫格（如果有）尝试补齐上一屏
        var notInserted: [TileSortItem] = []
        while !lastPage.isFull, let top = currentPage.pop() {
            if !lastPage.insert(top) {
                notInserted.append(top)
            }
        }
        // 当前屏尝试插入上一屏失败的，重新补回当前屏。理论上不会存在这种情况，这里为了逻辑完备而添加
        for item in notInserted {
            _ = currentPage.insert(item)
        }
        // 填充当前屏
        fillPage(currentPage, infos: infos, context: context)
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
