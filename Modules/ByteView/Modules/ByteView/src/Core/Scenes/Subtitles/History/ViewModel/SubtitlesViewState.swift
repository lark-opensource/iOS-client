//
//  SubtitlesViewState.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/8/12.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import RxSwift
import RxRelay
import ByteViewMeeting
import UniverseDesignIcon

// 字幕类型
enum SubtitleType: Int {
    case unknown = 0
    case translation
    case transcription  // 保留字段
    case event
}

// 关键行为类型
enum SubtitleEventType: Int {
    case unknown = 0
    case general
    case follow
}

protocol SubtitleViewDataProtocol {
    var identifier: String? { get }
}

class SubtitleViewData: SubtitleViewDataProtocol, InMeetParticipantListener {
    var subtitle: Subtitle
    let meetingId: String
    var segId: Int { subtitle.segID }
    var avatarInfo: AvatarInfo { subtitle.avatarInfo }
    var participantId: ParticipantId { subtitle.participantId }
    var isSegFinal: Bool { subtitle.isSegFinal }
    var translatedContent: NSMutableAttributedString {
        return NSMutableAttributedString(string: content, config: .bodyAssist)
    }
    var content: String {
        if shouldShowAnnotation {
            return getContentsIncludeAnnotations()
        } else {
            return subtitle.translatedContent.vc.substring(to: wordEnd)
        }
    }
    var time: String
    var realTime: String
    private(set) var name: String
    let type: SubtitleType
    var eventType: SubtitleEventType?
    var behaviorDescText: String?
    var behaviorDocLinkUrl: String?
    var behaviorDocLinkTitle: String?
    var icon: UDIconType?
    var identifier: String?
    var ranges: [NSRange] = []
    var needMerge: Bool = false

    var topOffset: CGFloat = 0

    var annotationRanges: [NSRange] = []
    var annotationContents: [String] = []

    let nameRelay: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)

    var shouldCacheHeight: Bool {
        return isSegFinal
    }

    private var count: Int {
        subtitle.translatedContent.utf16.count
    }

    var currentWordEnd: Int = -1

    var wordEnd: Int {
        if currentWordEnd == -1 || currentWordEnd > count {
            currentWordEnd = count
        }
        return currentWordEnd
    }

    var isShowAll: Bool {
        if currentWordEnd == count, isSegFinal {
            return true
        }
        return false
    }

    var shouldShowAnnotation: Bool {
        return phraseStatus == .on && !annotationContents.isEmpty && isShowAll
    }

    var isShowAnnotation: Bool = false

    var phraseStatus = GetSubtitleSettingResponse.PhraseTranslationStatus.on

    var batchID: Int64 { subtitle.batchID }

    var textHeight: CGFloat = 0
    var lineCount: Int = 0

    func changeMatch(range: [NSRange]) {
        self.ranges = range
    }

    func updateWordEnd() {
        if isShowAll {
            isShowAnnotation = true
        }
        if let last = subtitle.wordEnds.last, Int(last) == currentWordEnd {
            return
        }
        if subtitle.wordEnds.isEmpty {
            currentWordEnd = count
            return
        }
        for end in subtitle.wordEnds {
            let e = Int(end)
            if e > currentWordEnd {
                currentWordEnd = e
                break
            }
        }
    }

    init(subtitle: Subtitle, phraseStatus: GetSubtitleSettingResponse.PhraseTranslationStatus) {
        self.phraseStatus = phraseStatus
        let meeting = subtitle.meeting
        self.subtitle = subtitle
        self.meetingId = meeting?.meetingId ?? ""
        let second = subtitle.timestamp / 1000 as Int
        let time = SubtitleViewData.getTime(seconds: second)
        self.time = time
        self.realTime = time
        self.name = subtitle.name ?? ""

        let date = Date(timeIntervalSince1970: TimeInterval(subtitle.timestamp / 1000))
        self.realTime = SubtitleViewData.convertDateToString(date)
        if subtitle.batchID > 0, subtitle.data.subtitleType == .event {
            self.realTime = ""
        }

        switch subtitle.data.subtitleType {
        case .translation:
            self.type = .translation
            self.identifier = SubtitleHistoryCell.description()
        case .transcription: // 保留字段
            self.type = .transcription
        case .event:
            self.type = .event
            if let event = subtitle.data.event {
                switch event.type {
                case .startShareScreen, .stopShareScreen:
                    self.icon = .shareScreenOutlined
                    if event.type == .startShareScreen {
                        self.behaviorDescText = I18n.View_G_StartedScreenSharingNameBraces(self.name)
                    } else if event.type == .stopShareScreen {
                        self.behaviorDescText = I18n.View_G_StoppedScreenSharingNameBraces(self.name)
                    }
                    self.eventType = .general
                    self.identifier = SubtitleHistoryBehaviorCell.description()
                case .startFollow, .stopFollow:
                    self.icon = .fileLinkWordOutlined
                    if event.type == .startFollow {
                        self.behaviorDescText = I18n.View_G_StartedSharingColonNameBraces(self.name)
                    } else if event.type == .stopFollow {
                        self.behaviorDescText = I18n.View_G_StoppedSharingColonNameBraces(self.name)
                    }
                    let docTitle = event.followInfo?.docTitle ?? ""
                    let docURL = event.followInfo?.docURL ?? ""
                    if docTitle.isEmpty {
                        self.behaviorDocLinkTitle = I18n.View_VM_UntitledDocument
                    } else {
                        self.behaviorDocLinkTitle = docTitle
                    }
                    self.behaviorDocLinkUrl = docURL
                    self.eventType = .follow
                    self.identifier = SubtitleHistoryDocCell.description()
                default:
                    break
                }
            }
        default:
            self.type = .unknown
        }
        processAnnotations(subtitle.annotations)
        meeting?.participant.addListener(self)
    }

    func update(with subtitle: Subtitle) {
        self.subtitle = subtitle
        processAnnotations(subtitle.annotations)
    }

    private func processAnnotations(_ annotations: [MeetingSubtitleData.Subtitle.Annotation]) {
        if annotations.isEmpty { return }
        var ranges = [NSRange]()
        var contents = [String]()
        var loc = 0
       annotations.sorted {
            $0.end < $1.end
       }.forEach { annotation in
           guard annotation.type == .translation, let content = annotation.translation.contents.first else {
               return
           }
           let end = Int(annotation.end)
           let range = NSRange(location: loc, length: end - loc)
           ranges.append(range)
           loc = end
           contents.append(content)
       }
        ranges.append(NSRange(location: loc, length: self.count - loc))
        annotationRanges = ranges
        annotationContents = contents
    }

    private func getContentsIncludeAnnotations() -> String {
        var newContent = ""
        for i in 0..<annotationRanges.count {
            let range = annotationRanges[i]
            let substring = subtitle.translatedContent.vc.substring(from: range.location, length: range.length)
            if !substring.isEmpty {
                newContent.append(contentsOf: substring)
            }
            if i < annotationContents.count {
                newContent.append(contentsOf: " [\(annotationContents[i])]")
            }
        }
        return newContent
    }

    private static let oneHour = 3600
    private static let oneMinute = 60
    private static func getTime(seconds: Int) -> String {
        if seconds >= oneHour {
            //传入秒 返回:xx:xx:xx
            let hour = String(format: "%02td", seconds / oneHour)
            let minute = String(format: "%02td", (seconds % oneHour) / oneMinute)
            let second = String(format: "%02td", seconds % oneMinute)
            return  String("\(hour):\(minute):\(second)")
        }
        //传入秒,返回xx:xx
        let minute = String(format: "%02td", seconds / oneMinute)
        let second = String(format: "%02td", seconds % oneMinute)
        return String("\(minute):\(second)")
    }

    private static func convertDateToString(_ date: Date, withFormat format: String = "HH:mm:ss") -> String {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = format
        let date = dateFormatter.string(from: date)
        return date
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        if let participant = subtitle.meeting?.participant.find(user: subtitle.data.user) {
            let participantService = subtitle.meeting?.httpClient.participantService
            participantService?.participantInfo(pid: participant, meetingId: meetingId) { [weak self] ap in
                self?.name = ap.name
                self?.nameRelay.accept(ap.name)
            }
        }
    }
}

extension SubtitleViewData: Equatable {
    static func == (lhs: SubtitleViewData, rhs: SubtitleViewData) -> Bool {
        lhs.segId == rhs.segId &&
        lhs.avatarInfo == rhs.avatarInfo &&
        lhs.subtitle.translatedContent == rhs.subtitle.translatedContent &&
        lhs.isSegFinal == rhs.isSegFinal &&
        lhs.time == rhs.time &&
        lhs.realTime == rhs.realTime &&
        lhs.name == rhs.name &&
        lhs.type == rhs.type &&
        lhs.eventType == rhs.eventType &&
        lhs.behaviorDescText == rhs.behaviorDescText &&
        lhs.behaviorDocLinkUrl == rhs.behaviorDocLinkUrl &&
        lhs.behaviorDocLinkTitle == rhs.behaviorDocLinkTitle &&
        lhs.icon == rhs.icon &&
        lhs.identifier == rhs.identifier &&
        lhs.ranges == rhs.ranges
    }
}

enum SubtitleTableViewScrollType: Equatable {
    case forcesKeepingPosition // 下拉操作，tableview需要设置偏移量来保证原有的数据在当前屏幕内
    case normal // 上滑操作，tableview默认不滑动
    case autoScrollToBottom(Bool) // 新的数据，自动下滑到底部（isPush）
}

enum ChangeType: Equatable {
    case olderInserted // 一般是通过pull接口拿到数据，从数组前面插入数据
    case newerInserted // 一般是通过pull接口拿到数据，，从数组后面插入数据
    case newerAppended(Bool) // 从数组后面插入数据（true表示push，false表示clear之后主动拉取）
}

struct SubtitlesViewData: Equatable {
    private static let expireSeconds = 30

    @RwAtomic
    var oldestSegID: Int? // 当前最早的字幕ID
    var hasOlderData: Bool = true // 是否存在更早的字幕
    var hasNewData: Bool = true // 是否存在比较新的字幕
    var changeType: ChangeType = .olderInserted // 变化类型
    var needJump: Bool = false // 是否需要跳转到第一个命中的subtitle-cell

    var subtitleViewDatas: [SubtitleViewData] = []

    var reloadRows: Set<Int> = []

    var tableViewScrollType: SubtitleTableViewScrollType {
        switch changeType {
        case .olderInserted:
            return .forcesKeepingPosition
        case .newerInserted:
            return .normal
        case .newerAppended(let isPush):
            return .autoScrollToBottom(isPush)
        }
    }

    init() {

    }

    static func == (lhs: SubtitlesViewData, rhs: SubtitlesViewData) -> Bool {
        return lhs.hasOlderData == rhs.hasOlderData
        && lhs.hasNewData == rhs.hasNewData
        && lhs.changeType == rhs.changeType
        && lhs.needJump == rhs.needJump
        && lhs.subtitleViewDatas == rhs.subtitleViewDatas
    }

    mutating func update(subtitleViewDatas: [SubtitleViewData]) {
        self.subtitleViewDatas = Self.mergeSubtitle(subtitleViewDatas)
    }

    mutating func add(subtitleViewData: SubtitleViewData) {
        if self.subtitleViewDatas.isEmpty {
            subtitleViewData.needMerge = false
            self.subtitleViewDatas.append(subtitleViewData)
            return
        }
        let count = self.subtitleViewDatas.count
        var index = count - 1
        while index > 0 {
            if self.subtitleViewDatas[index].needMerge == false {
                break
            }
            index -= 1
        }
        let lastSeg = self.subtitleViewDatas[index]
        if lastSeg.type == .translation
            && subtitleViewData.type == .translation
            && lastSeg.participantId == subtitleViewData.participantId
            && count - index <= 2
            && abs(subtitleViewData.subtitle.timestamp - lastSeg.subtitle.timestamp) < Self.expireSeconds * 1000 {
            subtitleViewData.needMerge = true
            self.subtitleViewDatas.append(subtitleViewData)
        } else {
            subtitleViewData.needMerge = false
            self.subtitleViewDatas.append(subtitleViewData)
        }
    }

    static func mergeSubtitle(_ origin: [SubtitleViewData]) -> [SubtitleViewData] {
        var newList: [SubtitleViewData] = []
        if origin.isEmpty {
            return newList
        }

        var preSeg = origin[0]
        preSeg.needMerge = false
        newList.append(preSeg)

        var counter = 1

        for i in 1..<origin.count {
            let curSeg = origin[i]
            if preSeg.type == .translation
                && curSeg.type == .translation
                && preSeg.participantId == curSeg.participantId
                && abs(curSeg.subtitle.timestamp - preSeg.subtitle.timestamp) < Self.expireSeconds * 1000
            && counter < 3 {
                curSeg.needMerge = true
                counter += 1
            } else {
                curSeg.needMerge = false
                preSeg = curSeg
                counter = 1
            }
            newList.append(curSeg)
        }
        return newList
    }
}

enum SubtitlesViewState: Equatable {
    case emptyData
    case loading(SubtitlesViewData?)
    case loaded(SubtitlesViewData)
    case error(VCError, SubtitlesViewData?)
}

extension SubtitlesViewState {
    var subtitlesViewData: SubtitlesViewData? {
        switch self {
        case .emptyData:
            return nil
        case let .loaded(subtitlesViewData):
            return subtitlesViewData
        case .loading(let subtitlesViewData), .error(_, let subtitlesViewData):
            return subtitlesViewData
        }
    }

    var count: Int {
        return subtitlesViewData?.subtitleViewDatas.count ?? 0
    }

    var needJump: Bool {
        return subtitlesViewData?.needJump ?? false
    }

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        case .emptyData, .loaded, .error:
            return false
        }
    }

    var pullOldAllowsRefreshing: Bool {
        switch self {
        case .emptyData:
            return false
        case .loading, .loaded, .error:
            return subtitlesViewData?.hasOlderData ?? true
        }
    }

    var pullNewAllowsRefreshing: Bool {
        switch self {
        case .emptyData:
            return false
        case .loading, .loaded, .error:
            return subtitlesViewData?.hasNewData ?? false
        }
    }

    mutating func update(_ data: SubtitlesViewData) {
        switch self {
        case .emptyData:
            self = .loaded(data)
        case .loading:
            self = .loading(data)
        case .loaded:
            self = .loaded(data)
        case .error(let err, _):
            self = .error(err, data)
        }
    }

    mutating func toLoading() {
        switch self {
        case .loading:
            print("Wrong State Transition")
        case .emptyData, .loaded, .error:
            self = .loading(subtitlesViewData)
        }
    }

    mutating func toLoaded(with data: SubtitlesViewData) {
        switch self {
        case .emptyData, .error, .loaded:
            print("Wrong State Transition")
        case .loading:
            self = .loaded(data)
        }
    }

    mutating func toError(with error: VCError) {
        switch self {
        case .emptyData, .error, .loaded:
            print("Wrong State Transition")
        case .loading:
            self = .error(error, subtitlesViewData)
        }
    }
}
