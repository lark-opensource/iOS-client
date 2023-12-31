//
//  MinutesParagraphViewModel.swift
//  Minutes
//
//  Created by yangyao on 2021/1/12.
//

import Foundation
import CoreGraphics
import UIKit
import MinutesFoundation
import MinutesNetwork
import YYText
import UniverseDesignColor

public struct Phrase {
    let name: String
    let dictId: String?
    let range: NSRange
}

class MinutesParagraphViewModel {
    
    let leftMargin: CGFloat = MinutesSubtitleCell.LayoutContext.yyTextViewLeftMargin
    let rightMargin: CGFloat = MinutesSubtitleCell.LayoutContext.rightMargin
    
    let isClip: Bool
    let paragraph: Paragraph
    /// the start time of this paragraph, in ms
    let startTime: Int
    /// the end time of this paragraph, in ms
    let endTime: Int
    // ms
    var playTime: Double?


    var searchRanges: [NSRange]?
    var specifiedRange: NSRange?
    var commentsIdRanges: [String: NSRange] = [:]
    var commentsRanges: [NSRange] = []
    var selectedRange: NSRange?
    
    var fullTextRanges: NSRange?
    var isInTranslationMode: Bool = false
    var isLastParagraph: Bool = false
    // 录制的时候，最后一句话高亮，如果这个值为false则要高亮
    var lastSentenceFinal: Bool = false
    
    var lineCommentsCount: LineCommentsCountType = [:]
    var lineCommentsId: LineCommentsIdsType = [:]
    var commentIdLine: CommentIdLineType = [:]
    var lineHeight: LineHeightType = [:]
    
    var ccmComments: [MinutesCCMComment]?
    var ccmCommentIds: [String]?

    var phrases: [LingoDictPhrases] = [] {
        didSet {
            dPhrases.removeAll()
            for p in phrases {
                let range = NSRange(location: p.span.start, length: p.span.end - p.span.start)
                let phrase = Phrase(name: p.name, dictId: p.ids.first, range: range)
                dPhrases.append(phrase)
            }
        }
    }

    var dPhrases: [Phrase] = []

    var commentIDAndRanges: [String: NSRange] = [:]
    var sentenceIDAndRanges: [String: NSRange] = [:]
    var sentenceIDAndWordRanges: [String: [(NSRange, Content)]] = [:]

    var highlightedCommentsRange: NSRange?
    var pidAndSentenceDict: [String: [Sentence]] = [:]

    var highlightedRange: NSRange?
    var highlightedRanges: [NSRange]?
    let pIndex: NSInteger
    var highlightedRect = CGRect.zero

    var sentenceContentLenDict: [[String]: NSInteger] = [:]
    var wordRanges: [NSRange] = []
    var wordsInSentence: [Content] = []
    var wordContentsInSentence: [String] = []
    var wordTimesInSentence: [[String]] = []

    var lastSentencesRange: NSRange?

    var timeAndIndexMap: [[String]: [NSInteger]] = [:]
    var paragraphContent: String = ""
    var cellHeight: CGFloat = 0.0

    var commentsInfo: ParagraphCommentsInfo?
    var couldComment: Bool = true
    var commentsCount: NSInteger {
        return commentsInfo?.commentNum ?? 0
    }
    var highlightedCommentId: String?

    var userType: UserType {
        return paragraph.speaker?.userType ?? .unknow
    }
    var isSkeletonType: Bool {
        paragraph.isSkeletonType
    }

    var name: String {
        return paragraph.speaker?.userName ?? ""
    }
    var avatarUrl: URL {
        return paragraph.speaker?.avatarURL ?? URL(fileURLWithPath: "")
    }
    var roomUrl: URL {
        return URL(string: paragraph.speaker?.roomInfo?.avatarUrl ?? "") ?? URL(fileURLWithPath: "")
    }
    var userID: String {
        return paragraph.speaker?.userID ?? ""
    }

    lazy var time: String = {
        var timeStr = ""
        if let time = TimeInterval(paragraph.startTime) {
            let timeInterval = time / 1000
            timeStr = timeInterval.autoFormat() ?? ""
        }
        return timeStr
    }()

    public lazy var attributedText: NSMutableAttributedString = {
        let attributedText = NSMutableAttributedString(string: paragraphContent, attributes: [.foregroundColor: UIColor.ud.textTitle])
        attributedText.yy_font = MinutesSubtitleCell.LayoutContext.yyTextFont
        attributedText.yy_minimumLineHeight = MinutesSubtitleCell.LayoutContext.yyTextLineHeight
        attributedText.yy_setTextHighlight(YYTextHighlight(), range: attributedText.yy_rangeOfAll())
        return attributedText
    }()

    var containerWidth: CGFloat

    var textWidth: CGFloat {
        var width = containerWidth - leftMargin - rightMargin
        if isInCCMfg {
            width -= 10
        }
        return width
    }

    var layout: YYTextLayout? {
        guard let text = attributedText.mutableCopy() as? NSMutableAttributedString  else {
            return nil
        }
        let size = CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude)
        let insets = UIEdgeInsets(top: MinutesSubtitleCell.LayoutContext.yyTextViewTopInset, left: MinutesSubtitleCell.LayoutContext.yyTextViewLeftInset, bottom: MinutesSubtitleCell.LayoutContext.yyTextViewTopInset, right: MinutesSubtitleCell.LayoutContext.yyTextViewLeftInset)
        let container = YYTextContainer(size: size, insets: insets)
        text.replaceCharacters(in: NSRange(location: text.length, length: 0), with: "\r")
        let layout = YYTextLayout(container: container, text: text)
        return layout
    }
    let isInCCMfg: Bool
    init(containerWidth: CGFloat, paragraph: Paragraph, pIndex: NSInteger, pidAndSentenceDict: [String: [Sentence]], highlightedCommentId: String?, isRecording: Bool = false, isLastParagraph: Bool = false, lastSentenceFinal: Bool = false, isClip: Bool = false, ccmComments: [MinutesCCMComment]?, isInCCMfg: Bool) {
        self.containerWidth = containerWidth
        self.paragraph = paragraph
        self.pIndex = pIndex
        self.pidAndSentenceDict = pidAndSentenceDict
        self.highlightedCommentId = highlightedCommentId
        self.isLastParagraph = isLastParagraph
        self.lastSentenceFinal = lastSentenceFinal
        self.startTime = Int(paragraph.startTime) ?? 0
        self.endTime = Int(paragraph.stopTime) ?? 0
        self.isClip = isClip
        self.ccmComments = ccmComments
        self.ccmCommentIds = ccmComments?.flatMap({ $0.commentID})
        self.isInCCMfg = isInCCMfg
        calculateRanges()
        calculateHeight()
        calculateCommentsHighlightRanges()
    }

    func updateHighlightedRect() {
        if let range = highlightedRanges?.first, let rect = layout?.rect(for: YYTextRange(range: range)) {
            highlightedRect = rect
        }
    }

    public func matchedWordRanges(with currentTime: String) -> [NSRange]? {
        return matchedWordRanges(with: currentTime, stopTime: currentTime)
    }

    public func matchedWordWithSameRanges(with startTime: String, stopTime: String) -> [NSRange]? {
        // 根据时间找到相同时间的索引
        if let idxs = timeAndIndexMap[[startTime, stopTime]] {
            // 根据索引找到range
            let ranges = idxs.map { wordRanges[$0] }
            return ranges
        }
        return nil
    }

    // 根据点击的range找到其所属的range范围
    // 找到range所属的time
    // 找到所有包含这个时间的range
    public func foundWordRanges(with tappedRange: NSRange) -> (String, String)? {
        // 根据range找到索引
        for (idx, wordRange) in wordRanges.enumerated() {
            if tappedRange.location >= wordRange.location && tappedRange.location + tappedRange.length <= wordRange.location + wordRange.length {
                // 根据索引找到内容，获取开始和结束时间
                let content = wordsInSentence[idx]
                return (content.startTime, content.stopTime)
            }
        }
        return nil
    }

    // 找到所有包含这个时间的range
    public func matchedWordRanges(with startTime: String, stopTime: String) -> [NSRange]? {
        var matchedTimes: [[String]] = []
        var matchedRanges: [NSRange] = []

        guard let currentStartTimeInt = NSInteger(startTime), let currentStopTimeInt = NSInteger(stopTime) else { return nil }
        guard currentStopTimeInt < self.endTime, currentStartTimeInt >= self.startTime else { return nil }
        if isSkeletonType {
            // 鱼骨图类型没有内容，返回空
            return []
        }
        for (idx, time) in wordTimesInSentence.enumerated() {
            if let startTimeInt = NSInteger(time[0]), let stopTimeInt = NSInteger(time[1]) {
                if currentStartTimeInt >= startTimeInt && ((idx != wordTimesInSentence.count - 1) ? currentStopTimeInt < stopTimeInt : currentStopTimeInt <= stopTimeInt) {
                    if !matchedTimes.contains(time) {
                        matchedTimes.append(time)
                    }
                }
            }
        }
        matchedTimes.forEach { (time) in
            if let idxs = timeAndIndexMap[time] {
                // 根据索引找到range
                let ranges = idxs.map { wordRanges[$0] }
                matchedRanges.append(contentsOf: ranges)
            }
        }
        // 排序
        matchedRanges.sort(by: { $0.location < $1.location })
        return matchedRanges.isEmpty ? nil : matchedRanges
    }

    public func isInPargraphRange(with startTime: String) -> Bool {
        guard let currentStartTimeInt = NSInteger(startTime) else {
            return false
        }
        guard wordTimesInSentence.isEmpty == false, let first = wordTimesInSentence.first?[0], let last = wordTimesInSentence.last?[1] else {
            return false
        }
        if let startTimeInt = NSInteger(first), let stopTimeInt = NSInteger(last) {
            return currentStartTimeInt >= startTimeInt && currentStartTimeInt <= stopTimeInt
        }
        return false
    }

    func findOffsetAndSizeInSentence(selectedRange: NSRange) -> [OffsetAndSize] {
        var results: [OffsetAndSize] = []
        let sentenceIDs = sentenceIDAndRanges.keys.sorted(by: { $0 < $1 })

        for sid in sentenceIDs {
            guard let range = sentenceIDAndRanges[sid] else { return results }
            var offset: NSInteger = 0
            var size: NSInteger = 0

            let rangeStart = range.location
            let selectedRangeStart = selectedRange.location
            let rangeEnd = range.location + range.length
            let selectedRangeEnd = selectedRange.location + selectedRange.length

            let wordRangesInEachSentence: [(NSRange, Content)]? = sentenceIDAndWordRanges[sid]

            var startTimeClosure: ((NSInteger) -> Int) = { offset -> Int in
                // 根据这个offset在sentence里找到words
                var startTime: Int = 0
                if let first = wordRangesInEachSentence?.first(where: { offset >= $0.0.location }) {
                    startTime = Int(first.1.startTime) ?? 0
                }
                return startTime
            }

            if range.intersection(selectedRange) != nil {
                // () = sentence range  [] = selectedRange
                if selectedRangeStart >= rangeStart &&
                    selectedRangeEnd <= rangeEnd {
                    // ([])
                    offset = selectedRangeStart - rangeStart
                    size = selectedRange.length
                    let startTime = startTimeClosure(offset)
                    results.append((sid, offset, size, startTime))
                } else if selectedRangeStart <= rangeStart &&
                    selectedRangeEnd > rangeStart {
                    // [(])
                    offset = 0
                    size = selectedRangeEnd - rangeStart
                    let startTime = startTimeClosure(offset)
                    results.append((sid, offset, size, startTime))
                } else if selectedRangeStart >= rangeStart &&
                    selectedRangeEnd >= rangeEnd {
                    // ([)]
                    offset = selectedRangeStart - rangeStart
                    size = rangeEnd - selectedRangeStart
                    let startTime = startTimeClosure(offset)
                    results.append((sid, offset, size, startTime))
                } else if selectedRangeStart <= rangeStart &&
                    selectedRangeEnd >= rangeEnd {
                    // [()]
                    offset = 0
                    size = range.length
                    let startTime = startTimeClosure(offset)
                    results.append((sid, offset, size, startTime))
                }
            }
        }
        return results
    }

    public func boundingRect(_ isSearch: Bool = false) -> CGRect {
        if isSearch {
            if let specifiedRange = specifiedRange {
                return boundingRectForRange(specifiedRange)
            }
            return .zero
        } else {
            if let lastRange = highlightedRanges?.last {
                return boundingRectForRange(lastRange)
            }
            return .zero
        }
    }

    func boundingRectForRange(_ range: NSRange) -> CGRect {
        guard range.location + range.length <= attributedText.length else { return .zero }
        return autoreleasepool {
            return self.layout?.rect(for: YYTextRange(range: range)) ?? .zero
        }
    }

    var yyTextViewHeight: CGFloat {
        autoreleasepool {
            if let height = self.layout?.textBoundingSize.height {
                return height
            }
            return 0.0
        }
    }

    var rowCount: UInt {
        autoreleasepool {
            if let rowCount = self.layout?.rowCount {
                return rowCount
            }
            return 0
        }
    }
    
    public func calculateHeight() {
        if cellHeight > MinutesSubtitleCell.LayoutContext.yyTextTopMargin { return }
        var height: CGFloat = 0.0
        if isSkeletonType {
            height += MinutesSubtitleSkeletonCell.height
        } else {
            height += MinutesSubtitleCell.LayoutContext.yyTextTopMargin + yyTextViewHeight
        }
        cellHeight = height
    }

    var pid: String {
        return paragraph.id
    }

    func calculateCommentsHighlightRanges() {
        // pid获取sentence数组
        guard let sentencesInParagraph = pidAndSentenceDict[pid] else {
            return
        }
        commentsRanges.removeAll()
        commentIDAndRanges.removeAll()
        lineCommentsCount.removeAll()
        lineCommentsId.removeAll()
        commentIdLine.removeAll()

        for sentence in paragraph.sentences {
            if let sentenceHighlights = sentence.highlight {
                let sid = sentence.id
                var beforeLength = 0
                // 找出在当前sentence顺序之前的sentence
                let before = sentencesInParagraph.filter { $0.id < sid }.map { [pid, $0.id] }
                // 算出总长度
                beforeLength += before.reduce(0) { (last, element) -> NSInteger in
                    return last + (sentenceContentLenDict[element] ?? 0)
                }

                if isInCCMfg {
                    // 加上当前sentence的range
                    for highlighted in sentenceHighlights {
                        // 当前highligh在sentence里的range
                        let range = NSRange(location: beforeLength + highlighted.offset, length: highlighted.size)
                        if let ccmCommentIds = ccmCommentIds {
                            if let commentID = highlighted.commentID, ccmCommentIds.contains(commentID) {
                                if !commentsRanges.contains(range) {
                                    commentsRanges.append(range)
                                }
                                // 一个commentID有好多个range
                                if let oldRange = commentIDAndRanges[commentID] {
                                    let newRange = oldRange.union(range)
                                    commentIDAndRanges[commentID] = newRange
                                } else {
                                    commentIDAndRanges[commentID] = range
                                }
                            }
                        }
                    }
                } else {
                    // 加上当前sentence的range
                    for highlighted in sentenceHighlights {
                        // 当前highligh在sentence里的range
                        let range = NSRange(location: beforeLength + highlighted.offset, length: highlighted.size)
                        
                        if let commentID = highlighted.commentID {
                            if !commentsRanges.contains(range) {
                                commentsRanges.append(range)
                            }
                            // 一个commentID有好多个range
                            if let oldRange = commentIDAndRanges[commentID] {
                                let newRange = oldRange.union(range)
                                commentIDAndRanges[commentID] = newRange
                            } else {
                                commentIDAndRanges[commentID] = range
                            }
                        }
                    }
                }
 
            }
        }
        
        if let commentId = highlightedCommentId {
            highlightCommentRange(commentId)
        }

        // 排序
        commentsRanges.sort(by: { $0.location < $1.location })
    }

    // 根据传入的comment id更新highlightedCommentId和highlightedCommentsRange
    func highlightCommentRange(_ commentId: String?) -> NSRange? {
        if let commentId = commentId {
            highlightedCommentId = commentId
            let range = commentIDAndRanges[commentId]
            highlightedCommentsRange = range

            return range
        } else {
            highlightedCommentId = nil
            highlightedCommentsRange = nil

            return nil
        }
    }

    private func calculateRanges() {
        var timeAndIndexMap: [[String]: [NSInteger]] = [:]
        var idx = 0

        var previousSentenceLength: NSInteger = 0
        var length: NSInteger = 0
        for (sIndex, sentence) in paragraph.sentences.enumerated() {
            var contentLength: NSInteger = 0
            var lastSentenceID: String?
            if sIndex == paragraph.sentences.count - 1 {
                lastSentenceID = sentence.id
            }
            var wordRangesInEachSentence: [(NSRange, Content)] = []
            for word in sentence.contents {
                // 每个单词，添加到数组
                wordsInSentence.append(word)
                // 每个单词的内容，添加到数组
                wordContentsInSentence.append(word.content)

                let wordRange = NSRange(location: length, length: word.content.count)
                length += word.content.count
                wordRanges.append(wordRange)

                wordRangesInEachSentence.append((NSRange(location: contentLength, length: word.content.count), word))

                // 段落的内容
                paragraphContent.append(word.content)
                wordTimesInSentence.append([word.startTime, word.stopTime])

                contentLength += word.content.count

                if let idxs = timeAndIndexMap[[word.startTime, word.stopTime]] {
                    var tmp = idxs
                    tmp.append(idx)
                    timeAndIndexMap[[word.startTime, word.stopTime]] = tmp
                } else {
                    timeAndIndexMap[[word.startTime, word.stopTime]] = [idx]
                }
                idx += 1
            }
            sentenceContentLenDict[[paragraph.id, sentence.id]] = contentLength
            sentenceIDAndWordRanges[sentence.id] = wordRangesInEachSentence

            let sentenceRange: NSRange = NSRange(location: previousSentenceLength, length: contentLength)
            sentenceIDAndRanges[sentence.id] = sentenceRange
            previousSentenceLength += contentLength

            if let lastSentenceID = lastSentenceID {
                lastSentencesRange = sentenceIDAndRanges[lastSentenceID]
            }
        }
        self.timeAndIndexMap = timeAndIndexMap
    }

    func getFirstTime() -> [String]? {
        return wordTimesInSentence.first
    }

    func clearSearchRanges() {
        searchRanges = nil
        specifiedRange = nil
    }
}
