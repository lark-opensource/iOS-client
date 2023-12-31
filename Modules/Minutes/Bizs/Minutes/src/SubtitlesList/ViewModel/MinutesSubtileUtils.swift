//
//  MinutesSubtileUtils.swift
//  Minutes
//
//  Created by yangyao on 2021/4/26.
//

import Foundation

typealias LineCommentsCountType = [Int: Int]
typealias LineCommentsIdsType = [Int: [(String, NSRange)]]
typealias CommentIdLineType = [String: Int]
typealias LineHeightType = [Int: CGRect]

class MinutesSubtileUtils {
    static func runOnMain(_ block: @escaping () -> Void) {
        if Thread.current == .main {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    static func firstVMStartTime(_ data: [MinutesParagraphViewModel]) -> String? {
        return data.first?.getFirstTime()?[0]
    }

    static func findWordRanges(_ data: [MinutesParagraphViewModel],
                               time: String?,
                               index: NSInteger? = nil) -> (MinutesParagraphViewModel?, [[String]]) {
        guard let time = time else { return (nil, []) }

        var matchedVM: MinutesParagraphViewModel?
        var allWordsTimes: [[String]] = []
        if let index = index {
            // 有index则找和index相等的，典型场景在搜索
            for (idx, vm) in data.enumerated() {
                let wordRanges = vm.matchedWordRanges(with: time)
                vm.highlightedRanges = wordRanges
                if idx == index && wordRanges != nil {
                    matchedVM = vm
                }
                allWordsTimes.append(contentsOf: vm.wordTimesInSentence)
            }
        } else {
            for (idx, vm) in data.enumerated() {
                let wordRanges = vm.matchedWordRanges(with: time)
                vm.highlightedRanges = wordRanges
                if wordRanges != nil {
                    // 默认匹配最后一个
                    matchedVM = vm
                }
                allWordsTimes.append(contentsOf: vm.wordTimesInSentence)
            }
        }
        
        return (matchedVM, allWordsTimes)
    }

    // 如果没有匹配到，则定位到stop time最近的那个点
    static func findLatestWordRanges(with allWordsTimes: [[String]], startTime: String) -> [[String]] {
        if let currentStartTimeInt = NSInteger(startTime) {
            var diff: NSInteger = 0
            var matchedTimes: [[String]] = []
            for time in allWordsTimes {
                if let stopTimeInt = NSInteger(time[1]) {
                    let tmp = abs(currentStartTimeInt - stopTimeInt)
                    if diff == 0 {
                        diff = tmp
                    } else if tmp < diff {
                        diff = tmp
                        matchedTimes = []
                        matchedTimes.append(time)
                    }
                }
            }
            return matchedTimes
        }
        return []
    }

    static func highlightedOffsetIn(_ data: [MinutesParagraphViewModel], pVM: MinutesParagraphViewModel, isSearch: Bool) -> CGFloat {
        var totalHeight: CGFloat = 0.0
        for (idx, vm) in data.enumerated() {
            if idx < pVM.pIndex {
                totalHeight += vm.cellHeight
            } else {
                let rect = pVM.boundingRect(isSearch)
                totalHeight += rect.origin.y + MinutesSubtitleCell.LayoutContext.yyTextTopMargin
                break
            }
        }
        return totalHeight
    }
    
    static func highlightedRowHeaderOffsetIn(_ data: [MinutesParagraphViewModel], pVM: MinutesParagraphViewModel, isSearch: Bool) -> CGFloat {
        var totalHeight: CGFloat = 0.0
        for (idx, vm) in data.enumerated() {
            if idx < pVM.pIndex {
                totalHeight += vm.cellHeight
            }
        }
        return totalHeight
    }

    static func rangeOffsetIn(_ data: [MinutesParagraphViewModel], row: NSInteger, range: NSRange) -> CGFloat {
        let pVM = data[row]
        var totalHeight: CGFloat = 0.0
        for (idx, vm) in data.enumerated() {
            if idx < row {
                totalHeight += vm.cellHeight
            } else {
                let rect = pVM.boundingRectForRange(range)
                totalHeight += rect.origin.y
                break
            }
        }
        return totalHeight
    }
    
    static func rangeCountIn(_ pVM: MinutesParagraphViewModel, ccms: [MinutesCCMComment]) -> (LineCommentsCountType, LineCommentsIdsType, CommentIdLineType, LineHeightType) {
        // 在该行中遍历所有的range
        let ranges = pVM.commentsRanges
        
        var lineCommentsCount: LineCommentsCountType = [:]
        var lineCommentsIds: LineCommentsIdsType = [:]
        var commentIdLine: CommentIdLineType = [:]
        var lineHeight: LineHeightType = [:]

        
        for kv in pVM.commentIDAndRanges {
            let commentId: String = kv.key
            let range: NSRange = kv.value
            let rect = pVM.boundingRectForRange(range)

            if rect != .zero {
                let textCenterY = rect.origin.y - MinutesPodcastLyricCell.LayoutContext.yyTextViewTopMarginLittle
                let textHeight: CGFloat = 24.0
                let row: Int = Int(textCenterY / textHeight)

                var count: Int = lineCommentsCount[row] ?? 0
                let c = ccms.first(where: { $0.commentID == commentId})
                count += (c?.replyCount ?? 0)
                lineCommentsCount[row] = count
                
                var cids = lineCommentsIds[row]
                if var ids = cids {
                    ids.append((commentId, range))
                    cids = ids
                } else {
                    cids = [(commentId, range)]
                }
                cids = cids?.sorted(by: {$0.1.location < $1.1.location})
                lineCommentsIds[row] = cids
                commentIdLine[commentId] = row
                lineHeight[row] = rect
            }
        }
        return (lineCommentsCount, lineCommentsIds, commentIdLine, lineHeight)
    }
}
