//
//  MinutesData.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/28.
//

import Foundation
import LKCommonsLogging
import LarkStorage
import LarkSetting
import MinutesFoundation

public let PidKey = "minutes_pid"
public let PidxKey = "minutes_pidx"
public let PlaytimeKey = "minutes_playtime"

public let NewPidKey = "pid"
public let NewPidxKey = "pidx"
public let NewPlaytimeKey = "playtime"

extension Notification {
    public static let ReloadDetail = Notification.Name("minutes.detail.reload")
    public static let ReloadComments = Notification.Name("minutes.detail.comments.reload")
}

public final class MinutesData {

    static let logger = Logger.log(MinutesData.self, category: "Minutes.Network")

    let api: MinutesAPI

    let store = KVStores.udkv(
        space: .global,
        domain: Domain.biz.minutes
    )

    public var isLingoOpen: Bool = false

    public let objectToken: String

    public var minutesInfo: MinutesInfo?
    public let language: Language

    public var subtitles: [Paragraph] = []
    public var afterSubtitles: [Paragraph] = []
    public var beforeSubtitles: [Paragraph] = []
    public var beforeSubtitlesReversed: [Paragraph] = []
    
    public var totalSubtitleCount = 0

    public var speakerData: SpeakerData? {
        didSet {
            listeners.invokeListeners { listener in
                listener.onMinutesSpeakerDataUpdate(speakerData)
            }
        }
    }
    
    public var isAllDataReady: Bool = false
    public var subtitlesContentSize: Int {
        let size = subtitles.reduce(0) { totalSize, paragraph in
            let paragraphSize = paragraph.sentences.reduce(0) { totalSentenceSize, sentence in
                let sentenceSize = sentence.contents.reduce(0) { totalContentSize, content in
                    return totalContentSize + content.content.count
                }
                return totalSentenceSize + sentenceSize
            }
            return totalSize + paragraphSize
        }

        return size
    }

    public var lastSentenceFinal: Bool = true
    public var keywords: [String] = []
    public var paragraphIds: List<ParagraphID>?
    public var paragraphComments: [String: ParagraphCommentsInfo] = [:]
    public var newTags: NewDisplayTags? {
        didSet {
            minutesInfo?.newTags = newTags
        }
    }

    public var listeners = MulticastListener<MinutesDataChangedListener>()
    private var changed: Event<MinutesData> = Event<MinutesData>()
    public var paragraphUpdateBlock: ((String, Sentence) -> Void)?
    public var lastEditVersion: Int?

    public lazy var subtitleData: MinutesSubtitleData = MinutesSubtitleData(api: api, objectToken: objectToken, language: language)

    public var lastError: Error?
    public var lastAction: String?
    
    public var groupMeetings: [GroupMeeting]?
    public var shouldShowGroupMeetingTab: Bool {
        groupMeetings?.isEmpty == false
    }

    var subtitleStatus: MinutesDataStatus = .unkown
    var keywordsStatus: MinutesDataStatus = .unkown
    // 是否是首次请求
    public var isFirstRequest: Bool = true
    public dynamic private(set) var status: MinutesDataStatus = .unkown {
        didSet {
            listeners.invokeListeners { [weak self] listener in
                guard let self = self else {
                    return
                }
                listener.onMinutesDataStatusUpdate(self)
            }
            changed.update(data: self)
        }
    }

    public init(api: MinutesAPI, objectToken: String, language: Language = .default) {
        self.api = api
        self.objectToken = objectToken
        self.language = language
    }
}

extension MinutesData {
    var filterSpeakerSettingEnabled: Bool {
        if let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "vc_minutes_subtitle_speaker_ios")) {
            if let enabled = settings["is_apply_optimize"] as? Bool {
                Self.logger.info("get filter speaker setting enabled: \(enabled)")
                return enabled
            }
        }
        return false
    }

    // isFirstRequest: 是否是首次请求
    public func refresh(catchError: Bool, isFirstRequest: Bool = false, completionHandler: ((Result<MinutesData, Error>) -> Void)? = nil) {

        self.lastError = nil
        self.lastAction = nil

        changed.addHander { (data) -> Bool in
            switch data.status {
            case .otherError(let error):
                completionHandler?(.failure(error))
                return true
            case .ready:
                completionHandler?(.success(data))
                return true
            default:
                return false
            }
        }

        self.status = .fetchingData(.empty)

        // 首次请求需要分段加载
        fetchInitialData(catchError: catchError, isSeqRequest: isFirstRequest, forceSpeakers: true)
        fetchComments(catchError: catchError)
    }

    func fetchInitialData(catchError: Bool, isSeqRequest: Bool, forceSpeakers: Bool = false) {
        // 使用group，保证两个异步请求都回来之后再进行下一步的操作
        let group = DispatchGroup()
        group.enter()

        let lastPId = isSeqRequest ? getParagrapId() : nil
        let pIndex = getParagrapIdx() ?? 0

        let firstRequestCount: Int = MinutesSettingsManager.shared.firstRequestCount
        let maxRequestCount: Int = MinutesSettingsManager.shared.maxRequestCount
        
        Self.logger.info("[minutes setting] firstRequestCount: \(firstRequestCount), maxRequestCount: \(maxRequestCount)")
        
        let size = isSeqRequest ? firstRequestCount : maxRequestCount
        Self.logger.info("request size: \(size)")
        
        let filterSpeaker = isSeqRequest ? filterSpeakerSettingEnabled : false
        fetchSubtitles(catchError: catchError, paragraphID: lastPId, size: size, isSeqRequest: isSeqRequest, filterSpeaker: filterSpeaker) { status in
            group.leave()
        }
        // 如果是0开始就不需要第二个往前的分段请求了，减少不必要的请求
        if isSeqRequest && pIndex != 0 {
            // 往前取
            group.enter()
            fetchSubtitles(catchError: catchError, paragraphID: lastPId, size: size, forward: 2, isSeqRequest: isSeqRequest, filterSpeaker: filterSpeaker) { status in
                group.leave()
            }
        }

        group.enter()
        fetchTags(catchError: catchError) { _ in
            group.leave()
        }
        
        group.enter()
        fetchParagraphId { _ in
            group.leave()
        }

        group.enter()
        fetchKeywords(catchError: catchError) { _ in
            group.leave()
        }

        group.enter()
        fetchGroupMeetingList(completionHandler: { _ in
            group.leave()
        })

        group.enter()
        requestLingoSettings(completion: { [weak self] enabled in
            self?.isLingoOpen = enabled
            group.leave()
        })

        group.notify(queue: .main) {
            if isSeqRequest {
                var arrReversed: [Paragraph] = self.beforeSubtitles.reversed()
                if arrReversed.isEmpty == false {
                    arrReversed.removeLast()
                }
                self.beforeSubtitlesReversed = arrReversed
                // 拼接，去重
                self.subtitles = arrReversed + self.afterSubtitles
            }
            
            self.isFirstRequest = isSeqRequest
            
            // 在这里进行统一的通知
            self.status = self.subtitleStatus

            if isSeqRequest && self.isAllDataReady == false || forceSpeakers {
                let count = self.totalSubtitleCount
                // 分段加载需要再次请求全量的加载
                self.fetchSubtitles(catchError: catchError, paragraphID: nil, size: count, isSeqRequest: false, filterSpeaker: filterSpeaker) { [weak self] status in
                    guard let self = self else { return }
                    self.isFirstRequest = true
                    self.status = self.subtitleStatus

                    guard filterSpeaker == true else {
                        // 说话人tab信息
                        self.fetchSpeakers(catchError: true, paragraphID: nil, size: count) { [weak self] data in
                            guard let self = self, let data = data else { return }
                            self.speakerData = data
                        }
                        return
                    }
                    // speaker优化
                    self.fetchSpeakers(catchError: true, paragraphID: nil, size: count) { [weak self] data in
                        guard let self = self, let data = data else { return }
                        let subtitles = self.subtitles
                        var newSubtitles: [Paragraph] = []
                        // append speaker
                        for var subtitle in subtitles {
                            let pid = subtitle.id
                            if let uid = data.paragraphToSpeaker[pid] {
                                subtitle.speaker = data.speakerInfoMap[uid]
                            }
                            newSubtitles.append(subtitle)
                        }
                        self.subtitles = newSubtitles
                        self.speakerData = data

                        DispatchQueue.main.async {
                            // 发送通知进行刷新
                            NotificationCenter.default.post(name: Notification.ReloadDetail, object: nil, userInfo: nil)
                        }
                    }
                }
            }
        }
    }

    public func fetchSpeakers() {
        self.fetchSpeakers(catchError: true, paragraphID: nil, size: totalSubtitleCount) { [weak self] data in
            guard let self = self, let data = data else { return }
            let subtitles = self.subtitles
            var newSubtitles: [Paragraph] = []
            // append speaker
            for var subtitle in subtitles {
                let pid = subtitle.id
                if let uid = data.paragraphToSpeaker[pid] {
                    subtitle.speaker = data.speakerInfoMap[uid]
                }
                newSubtitles.append(subtitle)
            }
            self.subtitles = newSubtitles
            self.speakerData = data
        }
    }
    
    func requestLingoSettings(completion: ((Bool) -> Void)?) {
        let request = LingoDictSettingsRequest(objectToken: objectToken, catchError: true)
        api.sendRequest(request) { (result) in
            let r = result.map({ $0.data })
            switch r {
            case .success(let data):
                let isEnabled = data.minutes?.isEnabled ?? false
                MinutesLogger.network.error("lingo setting enabeld: \(isEnabled)")
                DispatchQueue.main.async {
                    completion?(isEnabled)
                }
            case .failure(let error):
                MinutesLogger.network.error("lingo setting query failed: \(error)")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }

    func getParagrapId() -> String? {
        if let dict: [String: String] = store.value(forKey: NewPidKey) {
            let key = objectToken
            return dict[key]
        }
        return nil
    }
    
    public func getParagrapIdx() -> NSInteger? {
        if let dict: [String: NSInteger] = store.value(forKey: NewPidxKey) {
            let key = objectToken
            return dict[key]
        }
        return nil
    }

    // isSeqRequest: 是否是分段请求
    func fetchSubtitles(catchError: Bool, paragraphID: String? = nil, size: Int? = nil, forward: Int = 1, isSeqRequest: Bool = false, filterSpeaker: Bool = false, completed: ((MinutesDataStatus) -> Void)?) {
        let request = FetchSubtitlesReqeust(objectToken: objectToken, paragraphID: paragraphID, size: size, fetchOrder: nil, translateLang: language.code, catchError: catchError, forward: forward, filterSpeaker: filterSpeaker)

        api.sendRequest(request) { [weak self] (result) in
            switch result {
            case .success(let response):
                if isSeqRequest {
                    if forward == 1 {
                        self?.afterSubtitles = response.data.paragraphs
                    } else {
                        self?.beforeSubtitles = response.data.paragraphs
                    }
                } else {
                    self?.subtitles = response.data.paragraphs
                }
                self?.lastEditVersion = response.data.lastEditVersion
                
                // 全量请求，标记数据已经全部加载完成
                if !isSeqRequest {
                    self?.isAllDataReady = true
                }
                if let status = self?.status.updatingFetchingStatus(with: .subtitles) {
                    self?.subtitleStatus = status
                    completed?(status)
                }
            case .failure(let error):
                self?.lastError = error
                self?.lastAction = "subtitles"
                self?.status = .otherError(error)
            }
        }
    }

    func updateSubtitles(catchError: Bool, paragraphID: String, filterSpeaker: Bool, sentence: Sentence) {
        let request = FetchSubtitlesReqeust(objectToken: objectToken, paragraphID: paragraphID, size: 1, fetchOrder: nil, translateLang: language.code, catchError: catchError, forward: 1, filterSpeaker: filterSpeaker)
        Self.logger.info("update subtitles for \(paragraphID)")
        api.sendRequest(request) { [weak self] (result) in
            switch result {
            case .success(let response):
                MinutesAPI.workQueue.async {
                    let subtitles = response.data.paragraphs
                    if let strongSelf = self,
                       let index = strongSelf.subtitles.lastIndex(where: { $0.id == paragraphID }),
                       let subtitle = subtitles.first {
                        strongSelf.subtitles[index] = subtitle
                        strongSelf.notifyReady(subtitle.id, sentence)
                    }
                }
            case .failure(let error):
                Self.logger.error("update subtitles error \(error)")
            }
        }
    }

    func fetchKeywords(catchError: Bool, completed: ((MinutesDataStatus) -> Void)?) {
        let request = FetchKeywordsRequest(objectToken: objectToken, language: language.code, catchError: catchError)

        api.sendRequest(request) { [weak self] (result) in
            switch result {
            case .success(let response):
                self?.keywords = response.data.keywords
                if let status = self?.status.updatingFetchingStatus(with: .keywords) {
                    self?.keywordsStatus = status
                    completed?(status)
                }
            case .failure(let error):
                self?.lastError = error
                self?.lastAction = "keywords"
                self?.status = .otherError(error)
            }
        }
    }

    func fetchTags(catchError: Bool, completed: ((NewDisplayTags?) -> Void)?) {
        let request = FetchTagsRequest(objectToken: objectToken, catchError: catchError)
        api.sendRequest(request) { [weak self] (result) in
            switch result {
            case .success(let response):
                let tagInfo = response.data
                self?.newTags = tagInfo.first
                completed?(self?.newTags)
            case .failure(let error):
                MinutesData.logger.warn("Fetch fetchTags failed with error: \(error)")
            }
        }
    }


    func fetchParagraphId(completed: ((List<ParagraphID>) -> Void)?) {
        let pageSize = 10000
        let request = FetchParagraphIDsReqeust(objectToken: objectToken, pageNum: nil, pageSize: pageSize)
        api.sendRequest(request) { [weak self] (result) in
            switch result {
            case .success(let response):
                let ids = response.data
                self?.paragraphIds = ids
                self?.totalSubtitleCount = ids.total
                completed?(ids)
            case .failure(let error):
                MinutesData.logger.warn("Fetch paragraph Id failed with error: \(error)")
                
            }
        }
    }

    func fetchComments(catchError: Bool) {
        let request = FetchCommentRequest(objectToken: objectToken, language: language.code, catchError: catchError)

        api.sendRequest(request) { [weak self] (result) in
            switch result {
            case .success(let response):
                let info = response.data.comments
                self?.paragraphComments = info
                if let status = self?.status.updatingFetchingStatus(with: .comments) {
                    self?.status = status
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.ReloadComments, object: info, userInfo: nil)
                }
            case .failure(let error):
                MinutesData.logger.warn("Fetch comments failed with error: \(error)")
                self?.lastError = error
                self?.lastAction = "comments"
                self?.status = .otherError(error)
            }
        }
    }

    public func updateSubtitleSpeaker(with speaker: Participant?) {
        guard let speaker = speaker, let pids = speaker.paragraphIds, !pids.isEmpty else {
            return
        }
        let pidsets = Set(pids)
        let newSubtitles = subtitles.map { (p) -> Paragraph in
            if pidsets.contains(p.id) {
                let newP = Paragraph(id: p.id, startTime: p.startTime, stopTime: p.stopTime, type: p.type, speaker: speaker, sentences: p.sentences)
                return newP
            }
            return p
        }
        subtitles = newSubtitles
        status = status.updatingFetchingStatus(with: .subtitles)
    }

    public func updateOneSubtitle(with speaker: Participant?, pid: String?) {
        guard let speaker = speaker, let pid = pid, pid.isEmpty == false else {
            return
        }

        let newSubtitles = subtitles.map { (p) -> Paragraph in
            if p.id == pid {
                let newP = Paragraph(id: p.id, startTime: p.startTime, stopTime: p.stopTime, type: p.type, speaker: speaker, sentences: p.sentences)
                return newP
            }
            return p
        }
        subtitles = newSubtitles
        status = status.updatingFetchingStatus(with: .subtitles)
    }
    
    public func fetchSpeakers(catchError: Bool, paragraphID: String? = nil, size: Int? = nil, completed: ((SpeakerData?) -> Void)?) {
        let request = FetchSpeakersRequest(objectToken: objectToken, paragraphID: paragraphID, size: size, translateLang: language.code, catchError: catchError)

        api.sendRequest(request) { (result) in
            switch result {
            case .success(let response):
                completed?(response.data)
            case .failure(_):
                completed?(nil)
            }
        }
    }

    func fetchGroupMeetingList(completionHandler: ((GroupMeetingListResponse?) -> Void)? = nil) {
        let request = FetchGroupMeetingListRequest(objectToken: objectToken)
        api.sendRequest(request) { [weak self] result in
            switch result {
            case .success(let response):
                self?.groupMeetings = response.data.groupMeetings
                completionHandler?(response.data)
            case .failure:
                completionHandler?(nil)
            }
        }
    }
}

extension MinutesData {

    public func find(query: String, type: FindType, completionHandler: @escaping (Result<FindResult, Error>) -> Void) {
        let request = FindRequest(objectToken: objectToken, language: language.code, type: type, query: query)

        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data
            })
        }
    }

    public func bindComment(catchError: Bool, quote: String, commentID: String, paragraphID: String, highlights: [SentenceHighlightsInfo], completionHandler: @escaping (Result<Response<CommentResponseV2>, Error>) -> Void) {
        let payload = BindCommentRequestPayload(quote: quote, commentID: commentID, content: nil, highlights: [paragraphID: highlights])
        let request = BindCommentRequest(objectToken: objectToken, comment: payload, catchError: catchError)
        api.sendRequest(request) { result in
            switch result {
            case .success(let response):
                self.updateNewCommentsInfo(nil, isFromPush: false)
            case .failure(let error):
                break
            }
            completionHandler(result)
        }
    }
    
    public func addComments(catchError: Bool, quote: String, content: String, paragraphID: String, highlights: [SentenceHighlightsInfo], completionHandler: @escaping (Result<Response<CommonCommentResponse>, Error>) -> Void) {
        let payload = AddCommentReqeustPayload(quote: quote, content: content, commentID: nil, highlights: [paragraphID: highlights])
        let request = AddCommentReqeust(objectToken: objectToken, comment: payload, catchError: catchError)
        api.sendRequest(request) { result in
            switch result {
            case .success(let response):
                self.updateCommentsInfo(response.data, isFromPush: false)
            case .failure(let error):
                break
            }
            completionHandler(result)
        }
    }

    public func deleteComment(catchError: Bool, contentID: String, completionHandler: @escaping (Result<Response<CommonCommentResponse>, Error>) -> Void) {
        let request = DeleteCommentRequest(objectToken: objectToken, contentId: contentID, catchError: catchError)
        api.sendRequest(request) { result in
            switch result {
            case .success(let response):
                self.updateCommentsInfo(response.data, isFromPush: false)
            case .failure(let error):
                break
            }
            completionHandler(result)
        }
    }

    public func unbindComment(catchError: Bool, commentId: String, completionHandler: @escaping (Result<Response<String>, Error>) -> Void) {
        let request = UnbindCommentRequest(objectToken: objectToken, commentId: commentId, catchError: catchError)
        api.sendRequest(request) { result in
            switch result {
            case .success(let response):
                break
            case .failure(let error):
                break
            }
            completionHandler(result)
        }
    }
    
    public func replyComments(catchError: Bool, content: String, commentID: String, completionHandler: @escaping (Result<Response<CommonCommentResponse>, Error>) -> Void) {
        let payload = AddCommentReqeustPayload(quote: nil, content: content, commentID: commentID, highlights: nil)
        let request = AddCommentReqeust(objectToken: objectToken, comment: payload, catchError: catchError)
        api.sendRequest(request) { result in
            switch result {
            case .success(let response):
                self.updateCommentsInfo(response.data, isFromPush: false)
            case .failure(let error):
                break
            }
            completionHandler(result)
        }
    }

    public func updateNewCommentsInfo(_ info: CommonCommentResponseV2?, isFromPush: Bool = true) {
        guard let info = info else { return }
        MinutesAPI.workQueue.async {
            let newParaghs = self.subtitles.map { value -> Paragraph in
                if let newValue = info.subtitles[value.id] {
                    var tmpValue = newValue
                    tmpValue.speaker = value.speaker
                    return tmpValue
                } else {
                    return value
                }
            }
            self.subtitles = newParaghs
            self.listeners.invokeListeners { listener in
                listener.onMinutesCommentsUpdateCCM(([], isFromPush))
            }
        }
    }
    
    public func updateCommentsInfo(_ info: CommonCommentResponse, isFromPush: Bool = true) {
        MinutesAPI.workQueue.async {
            self.paragraphComments.merge(info.comments) {
                $1
            }
            let newParaghs = self.subtitles.map { value -> Paragraph in
                if let newValue = info.subtitles[value.id] {
                    var tmpValue = newValue
                    tmpValue.speaker = value.speaker
                    return tmpValue
                } else {
                    return value
                }
            }
            self.subtitles = newParaghs
            self.listeners.invokeListeners { listener in
                listener.onMinutesCommentsUpdate((Array(info.comments.keys), isFromPush))
            }
        }
    }

    public func updateParagraphData(pid: String, sid: String, language: String, startTime: String, stopTime: String, contents: [Content], isFinal: Bool, filterSpeaker: Bool) {
        MinutesAPI.workQueue.async {
            let sentence = Sentence(id: sid, language: language, startTime: startTime, stopTime: stopTime, contents: contents, highlight: nil)
            let newParagraphTime = Int(pid) ?? 0
            if let paragraph = self.subtitles.last {
                let lastParagraphID = paragraph.id
                let lastParagraphTime = Int(paragraph.id) ?? 0
                if lastParagraphTime == newParagraphTime {
                    var sentences = paragraph.sentences
                    if let index = sentences.firstIndex(where: { $0.id == sid }) {
                        sentences[index] = sentence
                    } else {
                        sentences.append(sentence)
                    }
                    self.subtitles[self.subtitles.endIndex - 1] = Paragraph(id: pid, startTime: paragraph.startTime, stopTime: stopTime, type: nil, speaker: nil, sentences: sentences)
                    self.lastSentenceFinal = isFinal
                } else if lastParagraphTime < newParagraphTime {
                    let paragraph = Paragraph(id: pid, startTime: startTime, stopTime: stopTime, type: nil, speaker: nil, sentences: [sentence])
                    self.subtitles.append(paragraph)
                    self.lastSentenceFinal = isFinal
                    self.updateSubtitles(catchError: false, paragraphID: lastParagraphID, filterSpeaker: filterSpeaker, sentence: sentence)
                }
            } else {
                let paragraph = Paragraph(id: pid, startTime: startTime, stopTime: stopTime, type: nil, speaker: nil, sentences: [sentence])
                self.subtitles.append(paragraph)
                self.lastSentenceFinal = isFinal
            }
            self.notifyReady(pid, sentence)
        }
    }

    private func notifyReady(_ pid: String, _ sentence: Sentence) {
        paragraphUpdateBlock?(pid, sentence)
        Self.logger.info("notifyReady")
    }

    public func setupTimeline(_ duration: Int, completionHandler: @escaping (Result<[ReactionInfo], Error>) -> Void) {
        let request = FetchTimelineRequst(objectToken: objectToken, language: language.code)

        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data.timeline
            })
        }
    }

    public func updateReactionInfo(_ info: [ReactionInfo]) {
        MinutesAPI.workQueue.async {
            self.listeners.invokeListeners { listener in
                listener.onMinutesReactionInfosUpdate(info)
            }
        }
    }

    public func fetchMergedTimeline(catchError: Bool, startTime: Int, stopTime: Int, completionHandler: @escaping (Result<[ReactionInfo], Error>) -> Void) {
        let reqeust = FetchMergedTimelineRequest(objectToken: objectToken, language: language.code, startTime: startTime, stopTime: stopTime, catchError: catchError)

        api.sendRequest(reqeust) { result in
            completionHandler(result.map({ $0.data.reactions }))
        }
    }

    public func sendThumbsUp(at startTime: Int, completionHandler: @escaping (Result<[ReactionInfo], Error>) -> Void) {
        let reaction = ReactionInfo(type: 3, emojiCode: "THUMBSUP", count: nil, startTime: startTime)
        let reqeust = SendReactionReqeust(objectToken: objectToken, reaction: reaction)

        api.sendRequest(reqeust) { result in
            completionHandler(result.map {
                $0.data.timeline
            })
        }
    }

    public func loadPodcast(completionHandler: @escaping (Result<[OverlaySubtitleItem], Error>) -> Void) {
        let request = FetchPodcastSubtitleReqeust(objectToken: objectToken, language: language.code, translateLang: nil)

        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data.subtitles ?? []
            })
        }
    }
}
