//
//  MinutesSpeakersViewModel.swift
//  Minutes
//
//  Created by ByteDance on 2023/8/30.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import LarkContainer
import LarkSetting

struct MinutesSpeakerTimelineInfo {
    struct Thumb {
        var show: Bool = false
        var index: Int = 0
        var progress: CGFloat = 0
    }
    let participant: Participant
    var speakerTimeline: [(startTime: Int, stopTime: Int)]
    let speakerDuration: Int
    let videoDuration: Int
    var percent: CGFloat = 0
    var color: UIColor? = nil
    var thumbInfo: Thumb? = nil
    var summaryStatus: NewSummaryStatus = .generating
    var content: String?
    var isInTranslateMode: Bool
    var isContentEmpty: Bool = false

    var dPhrases: [Phrase] = []
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
}

class MinutesSpeakersViewModel: UserResolverWrapper {
    var phrasesCache: [Int: [LingoDictPhrases]] = [:]
    var phraseingCache: [String: Bool] = [:]

    let minutes: Minutes
    var originSpeakersTimeline: [MinutesSpeakerTimelineInfo] = []
    var speakersTimeline: [MinutesSpeakerTimelineInfo] = []
    var videoDuration: Int = 0
    var isInTranslateMode: Bool = false

    var colors: [UIColor] = [UIColor.ud.B400, UIColor.ud.G400, UIColor.ud.I400, UIColor.ud.T400, UIColor.ud.V400, UIColor.ud.W400, UIColor.ud.P400]

    var onDataUpdated: (() -> Void)?
    var speakerContainerWidth: CGFloat = 0.0

    var summaries: SpeakersSummaries?
    let userResolver: UserResolver

    init(resolver: UserResolver, minutes: Minutes) {
        self.userResolver = resolver
        self.minutes = minutes
        self.videoDuration = minutes.basicInfo?.duration ?? 0
    }

    @ScopedProvider var featureGatingService: FeatureGatingService?

    func addSpeakerObserver(speakerContainerWidth: CGFloat = 0, language: Language) {
        self.speakerContainerWidth = speakerContainerWidth
        if minutes.data.speakerData != nil {
            self.onSpeakerDataUpdate(language: language)
        }

        minutes.data.listeners.addListener(self)
    }

    private var isSummaryViewControllerEnable: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .aiSummaryVisible) == true && minutes.basicInfo?.isAiAnalystSummary == true && minutes.basicInfo?.summaryStatus != .notSupport
    }

    lazy var showSpeakerSummary: Bool = {
        guard isSummaryViewControllerEnable == true else { return false }
        guard featureGatingService?.staticFeatureGatingValue(with: .aiSummaryVisible) == true, featureGatingService?.staticFeatureGatingValue(with: .aiSpeakersVisible) == true else { return false }
        if let status = minutes.basicInfo?.speakerAiStatus, status != .notSupport {
            return true
        }
        return false
    }()

    func onSpeakerDataUpdate(language: Language? = nil, reload: Bool = true, callback: (() -> Void)? = nil) {
        if showSpeakerSummary {
            fetchSpeakersSummaries(language: language, completionHandler: { _ in
                handle()
            })
        } else {
            handle()
        }

        func handle() {
            guard let speakerData = minutes.data.speakerData else { return }

            self.isInTranslateMode = (language != nil) && language != .default

            var speakersInfo: [String: MinutesSpeakerTimelineInfo] = [:]
            for paragraph in minutes.data.subtitles {
                let startTime = Int(paragraph.startTime) ?? 0
                let stopTime = Int(paragraph.stopTime) ?? 0
                let duration = stopTime - startTime
                /// 根据段落获取说话人id
                if let participantId = speakerData.paragraphToSpeaker[paragraph.id] {
                    /// 已有该说话人的说话信息，取出并累加
                    /// 过滤2s以下的说话时间
                    if let info = speakersInfo[participantId], duration / 1000 > 2 {
                        var timeline = info.speakerTimeline
                        var totalDuration = info.speakerDuration
                        let maxTime = 2000
                        if var last = timeline.last, startTime - last.stopTime <= maxTime {
                            last.stopTime = stopTime
                            timeline.removeLast()
                            timeline.append(last)
                        } else {
                            timeline.append((startTime, stopTime))
                        }
                        totalDuration += duration
                        /// 获取说话人信息
                        if let p = speakerData.speakerInfoMap[participantId] {
                            let percent = formatPercent(CGFloat(totalDuration) / CGFloat(videoDuration) * 100)
                            speakersInfo[participantId] = MinutesSpeakerTimelineInfo(participant: p, speakerTimeline: timeline, speakerDuration: totalDuration, videoDuration: videoDuration, percent: percent, isInTranslateMode: isInTranslateMode)
                        }
                    } else {
                        /// 获取说话人信息
                        if let p = speakerData.speakerInfoMap[participantId], duration / 1000 > 2 {
                            let percent = formatPercent(CGFloat(duration) / CGFloat(videoDuration) * 100)
                            speakersInfo[participantId] = MinutesSpeakerTimelineInfo(participant: p, speakerTimeline: [(startTime, stopTime)], speakerDuration: duration, videoDuration: videoDuration, percent: percent, isInTranslateMode: isInTranslateMode)
                        }
                    }
                }
            }
            var speakers = speakersInfo.compactMap({$0.value})
            speakers.sort(by: { $0.speakerDuration > $1.speakerDuration })

            let count = colors.count

            speakers = speakers.enumerated().map { (idx, e) in
                MinutesSpeakerTimelineInfo(participant: e.participant, speakerTimeline: e.speakerTimeline, speakerDuration: e.speakerDuration, videoDuration: e.videoDuration, percent: e.percent, color: colors[idx % count], isInTranslateMode: e.isInTranslateMode)
            }

            var tmpSpeakers: [MinutesSpeakerTimelineInfo] = []
            for info in speakers {
                var previousRight: CGFloat = 0

                var newTimeline: [(startTime: Int, stopTime: Int)] = []
                for (_, (start, stop)) in info.speakerTimeline.enumerated() {
                    let totalLength = info.videoDuration
                    let length: CGFloat = CGFloat(stop - start)
                    var width: CGFloat = speakerContainerWidth * length / CGFloat(totalLength)
                    // 最小宽度
                    width = max(width, MinutesSpeakerSlider.Layout.thumbViewWidth)
                    let left: CGFloat = speakerContainerWidth * CGFloat(start) / CGFloat(totalLength)

                    if left <= previousRight && previousRight != 0, let preTimeline = newTimeline.last {
                        let newLength: CGFloat = CGFloat(stop - preTimeline.startTime)
                        var newWidth: CGFloat = speakerContainerWidth * newLength / CGFloat(totalLength)
                        newWidth = max(newWidth, MinutesSpeakerSlider.Layout.thumbViewWidth)
                        let newLeft: CGFloat = speakerContainerWidth * CGFloat(preTimeline.startTime) / CGFloat(totalLength)

                        previousRight = newLeft + newWidth
                        // 更新前一个
                        if var preNewTimeline = newTimeline.last {
                            preNewTimeline.stopTime = stop

                            newTimeline.popLast()
                            newTimeline.append(preNewTimeline)
                        }
                    } else {
                        previousRight = left + width
                        newTimeline.append((start, stop))
                    }
                }

                var newInfo = info
                newInfo.speakerTimeline = newTimeline
                if let summary = summaries {
                    if summary.aiSpeakerSummary?.summaryStatus != .complete {
                        newInfo.content = BundleI18n.Minutes.MMWeb_G_GeneratingSpeakerSummary_Desc
                        newInfo.isContentEmpty = false
                    } else {
                        var content = summary.aiSpeakerSummary?.details[newInfo.participant.userID]?.content ?? ""
                        newInfo.isContentEmpty = false
                        if summary.aiSpeakerSummary?.summaryStatus == .complete, content.isEmpty == true {
                            content = BundleI18n.Minutes.MMWeb_G_NoSummaryDidntSpeakMuch_Desc
                            newInfo.isContentEmpty = true
                        }
                        newInfo.content = content
                    }
                    newInfo.summaryStatus = summary.aiSpeakerSummary?.summaryStatus ?? .generating
                }
                tmpSpeakers.append(newInfo)
            }
            speakersTimeline = tmpSpeakers

            if self.isInTranslateMode == false {
                originSpeakersTimeline = tmpSpeakers
            }
            if reload {
                DispatchQueue.main.async {
                    self.onDataUpdated?()
                }
            }
            callback?()
        }
    }

    func formatPercent(_ percent: CGFloat) -> CGFloat {
        return percent < 1 ? ceil(percent) : floor(percent)
    }

    public func fetchSpeakersSummaries(language: Language? = nil, completionHandler: ((Bool) -> Void)? = nil) {
        let request = FetchSpeakersSummariesRequest(objectToken: minutes.objectToken, language: language?.code, catchError: false, aiType: 3)
        minutes.api.sendRequest(request) { [weak self] (result) in
            let r = result.map({ $0.data })
            switch r {
            case .success(let data):
                self?.summaries = data

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
}

extension MinutesSpeakersViewModel: MinutesDataChangedListener {
    public func onMinutesSpeakerDataUpdate(_ data: SpeakerData?) {
        self.onSpeakerDataUpdate()
    }
}

extension MinutesSpeakersViewModel {
    // disable-lint: duplicated_code
    func queryDict(rows: [Int], completion: (() -> Void)?) {
        let filterRows = rows.filter({ !self.phrasesCache.keys.contains($0) })
        guard filterRows.isEmpty == false else {
            for (key, value) in phrasesCache {
                if self.speakersTimeline.indices.contains(key) {
                    var info = self.speakersTimeline[key]
                    info.phrases = value
                    self.speakersTimeline[key] = info
                }
            }
            DispatchQueue.main.async {
                completion?()
            }
            return
        }

        let visibleText = filterRows.enumerated().map { (_, element) in
            if speakersTimeline.indices.contains(element) {
                return speakersTimeline[element].content ?? ""
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
                for (idx, phrase) in phrases.enumerated() {
                    if filterRows.indices.contains(idx) {
                        let row = filterRows[idx]
                        if self.speakersTimeline.indices.contains(row) {
                            var info = self.speakersTimeline[row]
                            info.phrases = phrase
                            self.speakersTimeline[row] = info
                            self.phrasesCache[row] = phrase
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
