//
//  MinutesSubtitleCell.swift
//  Minutes
//
//  Created by yangyao on 2021/1/12.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork
import LarkStorage

class MinutesSubtitlesViewModel {
    var data: [MinutesParagraphViewModel] = []
    var pidAndSentenceDict: [String: [Sentence]] = [:]
    var sentenceContentLenDict: [[String]: NSInteger] = [:]
    var pidAndIdxDict: [String: NSInteger] = [:]
    var allWordsTimes: [[String]] = []
    var hasSetMetaIds: Bool = false

    var phrasesCache: [Int: [LingoDictPhrases]] = [:]
    var phraseingCache: [String: Bool] = [:]

    let store = KVStores.udkv(
        space: .global,
        domain: Domain.biz.minutes
    )

    private var lastTextTimeInternal: Double?

    var lastTextTime: Double? {
        if let lastTextTimeInternal = lastTextTimeInternal {
            return lastTextTimeInternal
        } else {
            if let dict: [String: Double] = store.value(forKey: NewPlaytimeKey) {
                lastTextTimeInternal = dict[minutes.objectToken]
            }
            return lastTextTimeInternal
        }
    }


    public var minutes: Minutes

    public var isPullRefreshing = false

    public var isSupportASR: Bool {
        return minutes.basicInfo?.supportAsr == true
    }

    public var isClip: Bool {
        return minutes.isClip
    }

    public var endPullRefreshCallBack: (() -> Void)?
    var isInTranslationMode: Bool = false

    var isInCCMfg: Bool {
        minutes.info.basicInfo?.isInCCMfg == true
    }
    
    init(minutes: Minutes) {
        self.minutes = minutes
    }

    func createSkeletonTypeParagraph(_ paragraph: Paragraph, paragraphId: ParagraphID) -> Paragraph {
        var newParagraph = paragraph
        newParagraph.id = paragraphId.id
        newParagraph.startTime = paragraphId.startTime
        newParagraph.stopTime = paragraphId.stopTime
        newParagraph.type = .unknown
        newParagraph.speaker = nil
        newParagraph.sentences = []
        newParagraph.isSkeletonType = true
        return newParagraph
    }
    
    func firstLocateHeight() -> CGFloat {
        let pIndex = minutes.data.getParagrapIdx() ?? 0
        let beforeCount = minutes.data.beforeSubtitlesReversed.count
        
        var fragmentStart = pIndex - beforeCount
        fragmentStart = fragmentStart < 0 ? 0 : fragmentStart
        
        var height: CGFloat = 0.0
        // 鱼骨图高度
        for _ in 0..<fragmentStart {
            height += MinutesSubtitleSkeletonCell.height
        }

        // before高度
        for idx in fragmentStart..<pIndex {
            if data.indices.contains(idx) {
                height += data[idx].cellHeight
            }
        }
        return height
    }
    
    func firstParagraphIndex() -> NSInteger {
        let pIndex = minutes.data.getParagrapIdx() ?? 0
        return pIndex
    }
    
    func newLocateHeight() -> CGFloat? {
        let pIndex = minutes.data.getParagrapIdx() ?? 0
        guard data.indices.contains(pIndex) else { return nil }
        
        var height: CGFloat = 0.0
        for idx in 0..<pIndex {
            height += data[idx].cellHeight
        }
        return height
    }
    
    var paragraphs: [Paragraph]?
    var ccmComments: [MinutesCCMComment]?
    
    func calculate(containerWidth: CGFloat, paragraphs: [Paragraph]?, commentsInfo: [String: ParagraphCommentsInfo]?, highlightedCommentId: String?, isInTranslationMode: Bool, ccmComments: [MinutesCCMComment]?, complete: ([MinutesParagraphViewModel], [String: [Sentence]], [[String]: NSInteger], [String: NSInteger]) -> Void) {
        guard let paragraphs = paragraphs else { return }

        self.ccmComments = ccmComments
        var data: [MinutesParagraphViewModel] = []
        var pidAndSentenceDict: [String: [Sentence]] = [:]
        var sentenceContentLenDict: [[String]: NSInteger] = [:]
        var pidAndIdxDict: [String: NSInteger] = [:]
        
        let isClip = minutes.isClip
        // 当预先请求的个数小于总个数的时候，填充一些模型数据用于鱼骨图的展示
        var newParagraphs = paragraphs
        let totalSubtitleCount = minutes.data.totalSubtitleCount
        let paragraphIdsList = minutes.data.paragraphIds?.list ?? []
        
        if paragraphIdsList.count != totalSubtitleCount {
            assertionFailure("paragraphIdsList count not equal to totalSubtitleCount: \(paragraphIdsList.count), \(totalSubtitleCount)")
        }
        if paragraphs.count > 0,
            paragraphs.count < totalSubtitleCount,
            let tmpParagraph = paragraphs.first,
            !minutes.data.isAllDataReady {
            
            let pIndex = minutes.data.getParagrapIdx() ?? 0
            let beforeCount = minutes.data.beforeSubtitlesReversed.count
            let afterCount = minutes.data.afterSubtitles.count
            
            var fragmentStart = pIndex - beforeCount
            if fragmentStart < 0 {
                assertionFailure("something wrong! fragmentStart could not less than zero")
            }
            fragmentStart = fragmentStart < 0 ? 0 : fragmentStart
            
            var firstParagraphs: [Paragraph] = []
            for idx in 0..<fragmentStart {
                if paragraphIdsList.indices.contains(idx) {
                    firstParagraphs.append(createSkeletonTypeParagraph(tmpParagraph, paragraphId: paragraphIdsList[idx]))
                } else {
                    assertionFailure("paragraphIdsList not contain first idx")
                }
            }

            var lastParagraphs: [Paragraph] = []
            var fragmentEnd = pIndex + afterCount
            if fragmentEnd > totalSubtitleCount {
                fragmentEnd = totalSubtitleCount
            }
            for idx in fragmentEnd..<totalSubtitleCount {
                if paragraphIdsList.indices.contains(idx) {
                    lastParagraphs.append(createSkeletonTypeParagraph(tmpParagraph, paragraphId: paragraphIdsList[idx]))
                } else {
                    assertionFailure("paragraphIdsList not contain last idx")
                }
            }
            newParagraphs.insert(contentsOf: firstParagraphs, at: 0)
            newParagraphs.append(contentsOf: lastParagraphs)
            
            if newParagraphs.count != totalSubtitleCount {
                assertionFailure("newParagraphs count not equal to totalSubtitleCount")
            }
        }
        
        for (pIndex, p) in newParagraphs.enumerated() {
            for s in p.sentences {
                var contentLength: NSInteger = 0
                for c in s.contents {
                    contentLength += c.content.count
                }
                sentenceContentLenDict[[p.id, s.id]] = contentLength
            }
            pidAndSentenceDict[p.id] = p.sentences
            pidAndIdxDict[p.id] = pIndex

            let vm = MinutesParagraphViewModel(containerWidth: containerWidth,
                                               paragraph: p,
                                               pIndex: pIndex,
                                               pidAndSentenceDict: pidAndSentenceDict,
                                               highlightedCommentId: highlightedCommentId,
                                               isClip: isClip,
                                               ccmComments: ccmComments,
                                               isInCCMfg: isInCCMfg)
            vm.commentsInfo = commentsInfo?[p.id]
            vm.isInTranslationMode = isInTranslationMode
            if minutes.basicInfo?.objectStatus.minutesIsNeedBashStatus() == true || minutes.basicInfo?.canComment == false || minutes.isClip {
                vm.couldComment = false
            }
            data.append(vm)
        }
        complete(data, pidAndSentenceDict, sentenceContentLenDict, pidAndIdxDict)
    }

    public func searchAndMarkSpecifiedRange(with info: (NSInteger, NSRange)) {
        let index = info.0
        let range = info.1
        for (idx, vm) in data.enumerated() {
            if idx == index {
                vm.specifiedRange = range
            } else {
                vm.specifiedRange = nil
            }
        }
    }

    func pullToRefreshAllData(completionHandler: ((Result<MinutesData, Error>) -> Void)? = nil) {
        isPullRefreshing = true

        if isInTranslationMode {
            minutes.translateData?.refresh(catchError: true, completionHandler: { [weak self] result in
                guard let self = self else {
                    return
                }
                if self.isPullRefreshing {
                    self.isPullRefreshing = false
                }

                DispatchQueue.main.async {
                    self.endPullRefreshCallBack?()
                    completionHandler?(result)
                }
            })
        } else {
            minutes.refresh(catchError: true, refreshAll: true, completionHandler: { [weak self] in
                guard let self = self else {
                    return
                }
                if self.isPullRefreshing {
                    self.isPullRefreshing = false
                }

                DispatchQueue.main.async {
                    self.endPullRefreshCallBack?()
                }
            })
        }
    }

    func updateViewDataSpeaker(with speaker: Participant?) {
        minutes.data.updateSubtitleSpeaker(with: speaker)
    }

    func updateOneSubtitle(with speaker: Participant?, pid: String?) {
        minutes.data.updateOneSubtitle(with: speaker, pid: pid)
    }

    func requestRemoveSpeaker (paragraph: Paragraph, isBatch: Bool, successHandler: @escaping(Participant?) -> Void, failureHandler:@escaping(Error?) -> Void) {
        guard let speaker = paragraph.speaker else { return }
        minutes.speakerRemove(catchError: true, userId: speaker.userID, userType: speaker.userType.rawValue, paragraphId: paragraph.id, isBatch: isBatch) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let speaker):
                    successHandler(speaker.user)
                case .failure(let error):
                    failureHandler(error)
                    break
                }
            }
        }
    }

    func requestSpeakerCount(userId: String, userType: UserType, successHandler: @escaping(SpeakerCount) -> Void, failureHandler:@escaping(Error?) -> Void) {
        minutes.getSpeakerCount(catchError: true, userId: userId, userType: userType.rawValue) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let count):
                    successHandler(count)
                case .failure(let error):
                    failureHandler(error)
                    break
                }
            }
        }
    }
}

extension MinutesSubtitlesViewModel {
    func updateFullTextRange(_ index: NSInteger) {
        for (idx, pVM) in data.enumerated() {
            pVM.fullTextRanges = idx == index ? NSRange(location: 0, length: pVM.paragraphContent.count) : nil
        }
    }
}

extension MinutesSubtitlesViewModel {
    // disable-lint: duplicated_code
    func clearDictCache() {
        phrasesCache.removeAll()
        phraseingCache.removeAll()
    }

    func queryDict(rows: [Int], completion: (() -> Void)?) {
        let filterRows = rows.filter({ !self.phrasesCache.keys.contains($0) })
        guard filterRows.isEmpty == false else {
            for (key, value) in phrasesCache {
                if self.data.indices.contains(key) {
                    let pVM = self.data[key]
                    pVM.phrases = value
                }
            }
            DispatchQueue.main.async {
                completion?()
            }
            return
        }

        let visibleText = filterRows.enumerated().map { (_, element) in
            if data.indices.contains(element) {
                return data[element].attributedText.string
            } else {
                return ""
            }
        }
        guard visibleText.isEmpty == false else {
            DispatchQueue.main.async {
                completion?()
            }
            return
        }

        let rowString = filterRows.map { String($0) }.joined(separator: "_")
        if phraseingCache[rowString] == true {
            return
        }
        /// 标记正在请求
        phraseingCache[rowString] = true

        let request = LingoDictQueryRequest(objectToken: minutes.objectToken, texts: visibleText, catchError: true)
        minutes.api.sendRequest(request) { [weak self] (result) in
            guard let self = self else { return }
            let r = result.map({ $0.data })
            /// 取消标记
            self.phraseingCache[rowString] = false

            switch r {
            case .success(let data):
                let phrases = data.phrases

                for (idx, phrase) in phrases.enumerated() {
                    if filterRows.indices.contains(idx) {
                        let row = filterRows[idx]
                        if self.data.indices.contains(row) {
                            let pVM = self.data[row]
                            pVM.phrases = phrase
                            self.phrasesCache[row] = phrase
                        }
                    }
                }

                DispatchQueue.main.async {
                    completion?()
                }
            case .failure(let error):
                MinutesLogger.network.error("lingo dict query failed: \(error)")
            }
        }
    }
    // enable-lint: duplicated_code
}
