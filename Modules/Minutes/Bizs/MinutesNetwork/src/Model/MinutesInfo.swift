//
//  MinutesPermission.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/28.
//

import Foundation
import LKCommonsLogging
import MinutesFoundation

public final class MinutesInfo {

    static let logger = Logger.log(MinutesInfo.self, category: "Minutes.Network")

    let api: MinutesAPI

    public let objectToken: String

    public var basicInfo: BasicInfo?

    public var newTags: NewDisplayTags?
    
    public var participants: [Participant] = []
    public var files: [FileInfo] = []
    public var baseURL: URL {
        return api.baseURL
    }

    public var lastError: Error?
    public var lastAction: String?
    public var isFirstRequest: Bool = true

    public var currentUserPermission: PermissionCode {
        guard let someBasicInfo = basicInfo else {
            return .none
        }

        var permission: PermissionCode = .view

        if let someIsOwner = someBasicInfo.isOwner, someIsOwner {
            permission.formUnion(.owner)
        }

        if someBasicInfo.canModify {
            permission.formUnion(.edit)
        }

        return permission

    }

    public var listeners = MulticastListener<MinutesInfoChangedListener>()

    private var changed: Event<MinutesInfo> = Event<MinutesInfo>()

    public var statusInfo: StatusInfo? {
        didSet {
            if let info = statusInfo {
                updateStatus(info)
            }
        }
    }

    var lastEditVersion: Int?
    private var currentEditVerion: Int? {
        didSet {
            DispatchQueue.main.async {
                if let version = self.currentEditVerion, let lastVersion = self.lastEditVersion {
                    Self.logger.info("version update: \(version), last version: \(lastVersion)")
                    self.listeners.invokeListeners { listener in
                        listener.onMinutesInfoVersionUpdate(newVersion: version, oldVersion: lastVersion)
                    }
                }
            }
        }
    }

    private var objectStatus: ObjectStatus? {
        didSet {
            DispatchQueue.main.async {
                if let oldObjectStatus = oldValue, let currentObjectStatus = self.objectStatus {
                    self.listeners.invokeListeners { listener in
                        listener.onMinutesInfoObjectStatusUpdate(newStatus: currentObjectStatus, oldStatus: oldObjectStatus)
                    }
                }
            }
        }
    }

    public var summaries: Summaries? {
        didSet {
            if let summaries = summaries {
                self.summaryStatus = summaries.summaryStatus
            }
        }
    }

    public var summaryStatus: NewSummaryStatus? {
        didSet {
            DispatchQueue.main.async {
                if let oldSummaryStatus = oldValue, let currentSummaryStatus = self.summaryStatus {
                    self.listeners.invokeListeners { listener in
                        listener.onMinutesInfoSummaryStatusUpdate(newStatus: currentSummaryStatus, oldStatus: oldSummaryStatus)
                    }
                }
            }
        }
    }

    public var agendaStatus: NewSummaryStatus? {
        didSet {
            DispatchQueue.main.async {
                if let oldStatus = oldValue, let currentStatus = self.agendaStatus {
                    self.listeners.invokeListeners { listener in
                        listener.onMinutesInfoAgendaStatusUpdate(newStatus: currentStatus, oldStatus: oldStatus)
                    }
                }
            }
        }
    }

    public var speakerAiStatus: NewSummaryStatus? {
        didSet {
            DispatchQueue.main.async {
                if let oldStatus = oldValue, let currentStatus = self.speakerAiStatus {
                    self.listeners.invokeListeners { listener in
                        listener.onMinutesInfoSpeakerStatusUpdate(newStatus: currentStatus, oldStatus: oldStatus)
                    }
                }
            }
        }
    }

    public var isInProcessing: Bool {
        guard let objectStatus = self.basicInfo?.objectStatus else {
            return false
        }
        let objectType = self.basicInfo?.objectType ?? .unknown
        return objectStatus.minutesIsProcessing() || MinutesInfoStatus.status(from: objectStatus, objectType: objectType) == .processing
                || MinutesInfoStatus.status(from: objectStatus, objectType: objectType) == .transcoding
    }
    
    public dynamic private(set) var status: MinutesInfoStatus = .unkown {
        didSet {
            guard oldValue != status else {
                return
            }
            Self.logger.info("minutes info status change from \(oldValue) to \(status)")
            listeners.invokeListeners { [weak self] listener in
                guard let self = self else {
                    return
                }
                listener.onMinutesInfoStatusUpdate(self)
            }
        }
    }

    public var reviewStatus: ReviewStatus = .normal {
        didSet {
            guard oldValue != reviewStatus else {
                return
            }
            listeners.invokeListeners { [weak self] listener in
                guard let self = self else {
                    return
                }
                listener.onMinutesInfoStatusUpdate(self)
            }
            NotificationCenter.default.post(name: Notification.ReloadDetail, object: nil, userInfo: nil)
        }
    }

    public var schedulerType: MinutesSchedulerType = .none {
        didSet {
            guard oldValue != schedulerType else {
                return
            }
            listeners.invokeListeners { [weak self] listener in
                guard let self = self else {
                    return
                }
                listener.onMinutesInfoStatusUpdate(self)
            }
        }
    }

    public var schedulerExecuteDeltaTime: Int? = -1 {
        didSet {
            guard oldValue != schedulerExecuteDeltaTime else {
                return
            }
            listeners.invokeListeners { [weak self] listener in
                guard let self = self else {
                    return
                }
                listener.onMinutesInfoStatusUpdate(self)
            }
        }
    }

    public var silenceInfo: SilenceInfo?

    public init(api: MinutesAPI, objectToken: String) {
        self.api = api
        self.objectToken = objectToken
    }
}

extension MinutesInfo {

    public func refresh(catchError: Bool, completionHandler: (() -> Void)? = nil) {

        self.lastError = nil
        self.lastAction = nil

        changed.addHander { (info) -> Bool in
            switch info.status {
            case .otherError(let error):
                completionHandler?()
                return true
            case .ready:
                completionHandler?()
                return true
            default:
                return false
            }
        }

        self.status = .fetchingData(.empty)

        fetchSummaries(catchError: catchError, language: nil, completionHandler: { [weak self] result in
            switch result {
            case .success(let data):
                self?.summaries = data
            case .failure(let error):
                Self.logger.info("fetch summaries error: \(error)")
                self?.lastError = error
                self?.lastAction = "summaries"
            }
            if let status = self?.status.updatingFetchingStatus(with: .summaries) {
                self?.status = status
            }
        })

        fetchBasicInfo(catchError: catchError) { [weak self] (result) in
            switch result {
            case .success(let info):
                self?.basicInfo = info
                let objectStatus = MinutesInfoStatus.status(from: info.objectStatus, objectType: info.objectType)

                if objectStatus.isFinal() {
                    self?.status = objectStatus
                } else {
                    if let status = self?.status.updatingFetchingStatus(with: .basicInfo) {
                        self?.status = status
                    }
                }
            case .failure(let error):
                self?.lastError = error
                self?.lastAction = "baseinfo"
                self?.status = .status(from: error)
            }
        }

        fetchFiles(catchError: catchError)
        fetchParticipant(catchError: catchError)
        fetchSilenceRange(catchError: catchError)

    }

    public func fetchBasicInfo(catchError: Bool, completionHandler: ((Result<BasicInfo, Error>) -> Void)? = nil) {
        let request = BasicInfoRequest(objectToken: objectToken, catchError: true)

        api.sendRequest(request) { (result) in
            completionHandler?(result.map({ $0.data }))
        }
    }

    public func fetchSummaries(catchError: Bool, language: Language? = nil, chapter: Bool? = nil, completionHandler: ((Result<Summaries, Error>) -> Void)? = nil) {
        let request = FetchSummariesRequest(objectToken: objectToken, language: language?.code, catchError: catchError, chapter: chapter)

        api.sendRequest(request) { (result) in
            completionHandler?(result.map({ $0.data }))
        }
    }

    // disable-lint: magic number
    public func fetchParticipant(catchError: Bool, size: Int? = 500, completionHandler: ((Result<List<Participant>, Error>) -> Void)? = nil) {

        let request = FetchParticipantsReqeust(objectToken: objectToken, offset: 0, size: size, catchError: catchError)

        api.sendRequest(request) { [weak self] (result) in
            switch result {
            case .success(let response):
                // 存在原子性问题：子线程赋值，外部主线程消费
                DispatchQueue.main.async {
                    self?.participants = response.data.list ?? []
                    let first = self?.participants.first
                }
            case .failure(let error):
                Self.logger.warn("fetch participants error: \(error)")
            }
            completionHandler?(result.map({ $0.data }))
        }
    }
    // enable-lint: magic number

    func fetchFiles(catchError: Bool) {
        let size = 100
        let request = FetchFilesReqeust(objectToken: objectToken, offset: 0, size: size, catchError: catchError)

        api.sendRequest(request) { [weak self] (result) in
            switch result {
            case .success(let response):
                self?.files = response.data.list ?? []
            case .failure(let error):
                Self.logger.warn("fetch files error: \(error)")
            }
        }
    }

}

extension MinutesInfo {
    public func fetchParticipantSuggestion(completionHandler: @escaping (Result<ParticipantsSearch, Error>) -> Void) {
        let request = FetchParticipantsSuggestionReqeust(objectToken: objectToken)

        api.sendRequest(request) { (result) in
            completionHandler(result.map {
                $0.data
            })
        }
    }

    public func fetchParticipantSearch(text: String, uuid: String, completionHandler: @escaping (Result<ParticipantsSearch, Error>) -> Void) {
        let request = FetchParticipantsSearchReqeust(objectToken: objectToken, query: text, uuid: uuid)
        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data
            })
        }
    }

    public func participantDelete(catchError: Bool, userId: String, userType: Int, actionId: String,
                                  completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = ParticipantDeleteRequest(objectToken: objectToken, userId: userId, userType: userType, actionId: actionId, catchError: catchError)
        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func participantsAdd(catchError: Bool, users: [Participant], uuid: String,
                                completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = ParticipantsAddRequest(objectToken: objectToken, users: users, uuid: uuid, catchError: catchError)
        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func participantSearchAdd(catchError: Bool, userName: String, uuid: String,
                                     completionHandler: @escaping (Result<Participant, Error>) -> Void) {
        let request = ParticipantSearchUsersAddRequest(objectToken: objectToken, userName: userName, uuid: uuid, catchError: catchError)
        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data
            })
        }
    }
}

extension MinutesInfo {

    func startUpdatingStatusInfo(catchError: Bool, isFirstRequest: Bool = false) {
        fetchStatusInfo(catchError: catchError) { [weak self] result in
            switch result {
            case .success(let info):
                self?.isFirstRequest = isFirstRequest
                self?.statusInfo = info
                self?.currentEditVerion = info.lastEditVersion
                self?.reviewStatus = info.reviewStatus
                self?.objectStatus = info.objectStatus
                self?.summaryStatus = info.summaryStatus
                self?.agendaStatus = info.agendaStatus
                self?.speakerAiStatus = info.speakerAiStatus
            case .failure(let error):
                let status: MinutesInfoStatus = .status(from: error)
                if !status.isOtherError() {
                    self?.lastError = error
                    self?.lastAction = "statusInfo"
                    self?.status = status
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak self] in
            self?.startUpdatingStatusInfo(catchError: catchError)
        }
    }

    private func updateStatus(_ info: StatusInfo) {
        // 这个地方触发了三个通知
        switch status {
        case .fetchingData, .ready:
            break
        default:
            self.status = MinutesInfoStatus.status(from: info.objectStatus, objectType: basicInfo?.objectType)
        }
        schedulerType = info.schedulerType
        schedulerExecuteDeltaTime = info.schedulerDeltaExecuteTime
    }

    public func fetchStatusInfo(catchError: Bool, completionHandler: ((Result<StatusInfo, Error>) -> Void)? = nil) {

        let request = StatusRequest(objectToken: objectToken, catchError: catchError)

        api.sendRequest(request) { (result) in
            completionHandler?(result.map({ $0.data }))
        }

    }

    public func updateTitle(catchError: Bool, topic: String, completionHandler: ((Result<Void, Error>) -> Void)? = nil) {
        let request = UpdateTitleRequest(objectToken: objectToken, topic: topic, catchError: catchError)

        api.sendRequest(request) { [weak self] result in
            completionHandler?(result.map({ _ in () }))
            self?.refresh(catchError: false)
        }
    }

    public func fetchSilenceRange(catchError: Bool, completionHandler: ((Result<SilenceInfo, Error>) -> Void)? = nil) {
        let reqeust = FetchSilenceRangeRequest(objectToken: objectToken, language: nil, catchError: catchError)

        api.sendRequest(reqeust) { [weak self] result in
            switch result {
            case .success(let response):
                self?.silenceInfo = response.data
                Self.logger.info("fetch silence info success: \(response.data.toast)")
            case .failure(let error):
                Self.logger.warn("fetch silence info error: \(error)")
            }
            completionHandler?(result.map({ $0.data }))

        }
    }

}

extension MinutesInfo {
    public func reviewAppeal(completionHandler: ((Bool) -> Void)? = nil) {
        let request = ReviewAppealRequest(objectToken: objectToken)
        api.sendRequest(request) { result in
            switch result {
            case .success(let response):
                completionHandler?(true)
            case .failure(let error):
                completionHandler?(false)
            }
        }
    }
}
