//
//  MinutesChapterViewModel.swift
//  Minutes
//
//  Created by ByteDance on 2023/9/6.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import LarkContainer

struct MinutesChapterInfo {
    let title: String
    let content: String
    let startTime: Int
    let stopTime: Int
    let isSelected: Bool

    var formatTime: String {
        let timeInterval = TimeInterval(startTime) / 1000
        return timeInterval.autoFormat() ?? ""
    }
    var dPhrases: [ChapterDictRegion: [Phrase]] = [:]
    var phrases: [LingoDictPhrases] = []
}

enum ChapterDictRegion {
    case title
    case content
}

class MinutesChapterViewModel {
    var phrasesCache: [Int: [ChapterDictRegion: [Phrase]]] = [:]
    var phraseingCache: [String: Bool] = [:]
    
    var data: [MinutesChapterInfo] = []
    var foldData: [MinutesChapterInfo] = []

    var curPlayIndex: Int = 0
    public var summaries: Summaries?

    var minutes: Minutes
    let userResolver: UserResolver

    var showEmptyView: Bool = false
    let player: MinutesVideoPlayer

    var reload: ((Int) -> Void)?

    init(minutes: Minutes, userResolver: UserResolver, player: MinutesVideoPlayer) {
        self.minutes = minutes
        self.userResolver = userResolver
        self.player = player
        player.listeners.addListener(self)
    }

    public func fetchSummaries(language: Language? = nil, completionHandler: ((Bool) -> Void)? = nil) {
        let request = FetchSummariesRequest(objectToken: minutes.objectToken, language: language?.code, catchError: false, chapter: true)
        minutes.api.sendRequest(request) { [weak self] (result) in
            let r = result.map({ $0.data })
            switch r {
            case .success(let data):
                self?.summaries = data
                self?.parse()
                DispatchQueue.main.async {
                    completionHandler?(true)
                }
            case .failure:
                DispatchQueue.main.async {
                    completionHandler?(false)
                }
            }
        }
    }

    func parse() {
        guard let someSummaries = summaries, let someSectionList = someSummaries.sectionList, someSummaries.total != 0 else {
            data = []
            showEmptyView = true
            return
        }
        data = []
        foldData = []
        for section in someSectionList {
            for contentId in (section.contentIds ?? []) {
                if let content = someSummaries.contentList?[contentId] {
                    let m = MinutesChapterInfo(title: content.title, content: content.data, startTime: content.startTime, stopTime: content.stopTime, isSelected: false)
                    data.append(m)
                    foldData.append(MinutesChapterInfo(title: content.title, content: "", startTime: content.startTime, stopTime: content.stopTime, isSelected: false))
                }
            }
        }

        showEmptyView = parseContentIds()
    }

    private func parseContentIds() -> Bool {
        var showEmptyView = false
        var contentIds: [String] = []
        if summaries?.sectionList?.isEmpty == true {
            showEmptyView = true
        } else {
            for section in minutes.info.summaries?.sectionList ?? [] {
                contentIds.append(contentsOf: section.contentIds ?? [])
            }
        }
        showEmptyView = contentIds.isEmpty
        return showEmptyView
    }

    func selectItem(_ index: Int) {
        data = data.enumerated().map { (idx, s) in
            return MinutesChapterInfo(title: s.title, content: s.content, startTime: s.startTime, stopTime: s.stopTime, isSelected: index == idx, dPhrases: s.dPhrases)
        }
        let playTime = data[index].startTime
        handleSpeakerPlay(CGFloat(playTime / 1000))

        reload?(playTime)
    }

    func handleSpeakerPlay(_ playTime: CGFloat) {
        player.seekVideoPlaybackTime(TimeInterval(playTime))
        player.play()
    }
}

extension MinutesChapterViewModel: MinutesVideoPlayerListener {
    func videoEngineDidLoad() {

    }
    func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {

    }
    func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        let playTime = Int(time.time) * 1000

        var matchedIndex: Int?
        if let index = data.firstIndex(where: { playTime > $0.startTime && playTime < $0.stopTime } ) {
            matchedIndex = index
        } else if let index = data.firstIndex(where: { playTime <= $0.startTime } ) {
            matchedIndex = index
        }

        if let i = matchedIndex {
            if i != curPlayIndex {
                data = data.enumerated().map {
                    MinutesChapterInfo(title: $1.title, content: $1.content, startTime: $1.startTime, stopTime: $1.stopTime, isSelected: i == $0, dPhrases: $1.dPhrases)
                }

                foldData = data.map({ MinutesChapterInfo(title: $0.title, content: "", startTime: $0.startTime, stopTime: $0.stopTime, isSelected: $0.isSelected, dPhrases: $0.dPhrases) })
                reload?(playTime)
            }
            curPlayIndex = i
        }
    }
}

extension MinutesChapterViewModel {
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
                    var info = self.data[key]
                    info.dPhrases = value
                    self.data[key] = info
                }
            }
            DispatchQueue.main.async {
                completion?()
            }
            return
        }

        let visibleText = filterRows.enumerated().map { (_, element) in
            if data.indices.contains(element) {
                return data[element].title + data[element].content
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
        phraseingCache[rowString] = true

        let request = LingoDictQueryRequest(objectToken: minutes.objectToken, texts: visibleText, catchError: true)
        minutes.api.sendRequest(request) { [weak self] (result) in
            guard let self = self else { return }
            let r = result.map({ $0.data })

            self.phraseingCache[rowString] = false

            switch r {
            case .success(let data):
                let phrases = data.phrases
                // 每一行
                for (idx, phrase) in phrases.enumerated() {
                    if filterRows.indices.contains(idx) {
                        let row = filterRows[idx]
                        if self.data.indices.contains(row) {
                            var info = self.data[row]
                            info.phrases = phrase
                            // 每行多个元素
                            var dPhrases: [ChapterDictRegion: [Phrase]] = [:]
                            var titlePhrases: [Phrase] = []
                            var contentPhrases: [Phrase] = []
                            for p in phrase {
                                if self.data.indices.contains(row) {
                                    let d = self.data[row]
                                    let titleLength = d.title.count
                                    if p.span.start >= titleLength {
                                        if p.span.start - titleLength >= 0 {
                                            let range = NSRange(location: p.span.start - titleLength, length: p.span.end - p.span.start)
                                            let contentPhrase = Phrase(name: p.name, dictId: p.ids.first, range: range)
                                            contentPhrases.append(contentPhrase)
                                        }
                                    } else {
                                        if p.span.end < titleLength {
                                            let range = NSRange(location: p.span.start, length: p.span.end - p.span.start)
                                            let titlePhrase = Phrase(name: p.name, dictId: p.ids.first, range: range)
                                            titlePhrases.append(titlePhrase)
                                        }
                                    }
                                }
                            }
                            dPhrases[.title] = titlePhrases
                            dPhrases[.content] = contentPhrases
                            info.dPhrases = dPhrases

                            self.data[row] = info
                            self.phrasesCache[row] = dPhrases
                        }
                    }
                }
                DispatchQueue.main.async {
                    completion?()
                }
            case .failure(let error):
                MinutesLogger.network.error("chapter lingo dict query failed: \(error)")
            }
        }
    }
    // enable-lint: duplicated_code
}
