//
//  Minutes.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation
import LKCommonsLogging
import LarkLocalizations
import MinutesFoundation

public final class Minutes {
    public static let podcastTokenListKey = "MinutesPodcastTokenListKey"
    public static let fromSourceKey = "MinutesFromSourceKey"

    public static let logger = Logger.log(Minutes.self, category: "Minutes.Network")

    static public func isMinutesURL(_ url: URL) -> Bool {
        let host = url.host ?? ""
        let path = url.path
        if host.mins.isLarkDomain(),
           path.mins.isMinutesPath() {
            return true
        }
        return false
    }

    static public func isHomeURL(_ url: URL) -> Bool {
        let host = url.host ?? ""
        let path = url.path
        if host.mins.isLarkDomain(),
           path.mins.isHomePath() {
            return true
        }
        return false
    }

    static public func isMyURL(_ url: URL) -> Bool {
        let host = url.host ?? ""
        let path = url.path
        if host.mins.isLarkDomain(),
           path.mins.isMyPath() {
            return true
        }
        return false
    }

    let domain: String
    public let api: MinutesAPI

    public let objectToken: String

    public var baseURL: URL

    public let info: MinutesInfo

    public let data: MinutesData

    public var translateData: MinutesData?

    public var basicInfo: BasicInfo? {
        return info.basicInfo
    }
    
    public var recordDisplayName: String?


    public var isLingoOpen: Bool {
        return data.isLingoOpen
    }

    public var topic: String? {
        return basicInfo?.topic.isEmpty != false ? recordingTopic : basicInfo?.topic
    }
    private var recordingTopic: String = ""

    public var subtitleLanguages: [Language] {
        return info.basicInfo?.subtitleLanguages ?? []
    }

    public var spokenLanguages: [Language] {
        return record?.languageList ?? []
    }

    public var record: MinutesRecord?

    public var podcastURLList: [URL] = []

    public var lastError: Error? {
        return info.lastError ?? data.lastError
    }
    public var lastAction: String? {
        return info.lastAction ?? data.lastAction
    }

    public func setTopic(_ topic: String) {
        recordingTopic = topic
    }

    public var isClip: Bool {
        return info.basicInfo?.clipInfo?.isClip ?? false
    }

    public var isClipCreator: Bool {
        return info.basicInfo?.clipInfo?.isClipCreator ?? false
    }

    convenience public init?(_ urlString: String) {
        self.init(URL(string: urlString))
    }
    
    public init?(_ url: URL?) {
        guard let baseURL = url else {
            return nil
        }

        guard Minutes.isMinutesURL(baseURL) else {
            return nil
        }

        let components = baseURL.pathComponents
        
        if let host = baseURL.host, let token = components.last {
            domain = host
            objectToken = token
            api = MinutesAPI.clone(baseURL)

            self.baseURL = baseURL
            self.info = MinutesInfo(api: api, objectToken: token)
            self.data = MinutesData(api: api, objectToken: token)
            self.data.minutesInfo = self.info
            MinutesInstanceRegistry.shared.register(self)
            data.listeners.addListener(self)
            
            // 是否启用分段加载
            let isEnabled: Bool = MinutesSettingsManager.shared.isSegRequestEnabled
            Self.logger.info("[minutes setting] use seq request: \(isEnabled)")
            // 如果是评论来的，那么就不进行分段加载，防止跳转到未加载的的部分
            let isFromComment = checkIsFromComment(baseURL)
            let isFirstRequest = isFromComment ? false : isEnabled
            
            refresh(catchError: false, isFirstRequest: isFirstRequest)
            return
        }
        return nil
    }

    public init(token: String) {
        baseURL = MinutesAPI.buildURL(for: token)
        api = MinutesAPI.clone(baseURL)
        domain = api.domain
        objectToken = token
        info = MinutesInfo(api: api, objectToken: token)
        data = MinutesData(api: api, objectToken: token)
        record = MinutesRecord(api: api, objectToken: token)
        MinutesInstanceRegistry.shared.register(self)
        data.listeners.addListener(self)
        
        // 是否启用分段加载
        let isEnabled: Bool = MinutesSettingsManager.shared.isSegRequestEnabled
        Self.logger.info("use seq request: \(isEnabled)")
        // 如果是评论来的，那么就不进行分段加载，防止跳转到未加载的的部分
        let isFromComment = checkIsFromComment(baseURL)
        let isFirstRequest = isFromComment ? false : isEnabled
        
        refresh(catchError: false, isFirstRequest: isFirstRequest)
        record?.fetchLanguageList()
    }

    private func checkIsFromComment(_ url: URL) -> Bool{
        let queryItems = URLComponents(string: url.absoluteString)?.queryItems
        if let commentId = queryItems?.first(where: { $0.name == "c" })?.value as? String, let contentId = queryItems?.first(where: { $0.name == "cci" })?.value as? String {
            return true
        }
        return false
    }

    public static func createMinutesForAudioRecord(catchError: Bool, isForced: Bool, topic: String, completionHandler: @escaping (Swift.Result<Minutes, Error>) -> Void) {
        let api = MinutesAPI.clone()

        let lanuage = LanguageManager.currentLanguage.identifier
        let request = CreateAudioRecordMinutesRequest(topic: topic, language: lanuage, isForced: isForced, catchError: catchError)

        api.sendRequest(request) { result in
            switch result {
            case .success(let response):
                let code = 1007
                if response.code != code, let token = response.data.objectToken {
                    let minutes = Minutes(token: token)
                    minutes.recordDisplayName = response.data.userName
                    minutes.setTopic(response.data.topic ?? "")
                    completionHandler(.success(minutes))
                } else {
                    let spaceError = StorageSpaceError(code: code, isAdmin: response.data.isAdmin ?? false, description: response.data.noQuotaNotice, billUrl: response.data.billUrl)
                    completionHandler(.failure(spaceError))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public static func getAudioRecordUserGuide(catchError: Bool, completionHandler: @escaping (Result<GetUserGuidedResponse, Error>) -> Void) {
        let api = MinutesAPI.clone()
        let request = GetUserGuidedRequest(guideType: "MM_FIRST_RECORD", catchError: catchError)
        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data
            })
        }
    }

    public static func addAudioRecordUserGuide(catchError: Bool, completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let api = MinutesAPI.clone()
        let request = AddUserGuidedRequest(guideType: "MM_FIRST_RECORD", catchError: catchError)
        api.sendRequest(request, completionHandler: completionHandler)
    }
}

extension Minutes: MinutesDataChangedListener {
    public func onMinutesDataStatusUpdate(_ data: MinutesData) {
        info.lastEditVersion = data.lastEditVersion
    }
}

extension Minutes {
    public func refresh(catchError: Bool, refreshAll: Bool = true, isFirstRequest: Bool = false, completionHandler: (() -> Void)? = nil) {
        if refreshAll {
            info.refresh(catchError: catchError)

            // 录音也会进入到这
            data.refresh(catchError: catchError, isFirstRequest: isFirstRequest) { [weak self] _ in
                completionHandler?()
                // 成功之后再进行轮询，防止提前reload导致进来和跳转之间有gap
                self?.info.startUpdatingStatusInfo(catchError: true, isFirstRequest: true)
            }
        } else {
            info.refresh(catchError: catchError, completionHandler: completionHandler)
        }
    }
}

extension Minutes {
    private func translateAudio(catchError: Bool, to lang: Language) {
        let request = ChangeAudioLanguageRequest(objectToken: objectToken, translateLanguage: lang.code, recordingLanguage: nil, catchError: catchError)
        api.sendRequest(request) { result in
            switch result {
            case .success:
                Self.logger.info("translate launguage \(lang.name) success.")
            case .failure(let error):
                Self.logger.error("translate launguage error: \(error)")
            }
        }
    }

    public func translateAudio(catchError: Bool, language: Language, completionHandler: @escaping (Result<MinutesData, Error>) -> Void) {
        translateAudio(catchError: catchError, to: language)
        let data = MinutesData(api: api, objectToken: objectToken, language: language)
        translateData = data
        data.refresh(catchError: false, completionHandler: completionHandler)
    }

    public func exitTranslateAudio(catchError: Bool, completionHandler: @escaping (Result<MinutesData, Error>) -> Void) {
        translateAudio(catchError: catchError, to: data.language)
        translateData = nil
        data.refresh(catchError: false, completionHandler: completionHandler)
    }
}

extension Minutes {

    public func translate(language: Language, completionHandler: @escaping (Result<MinutesData, Error>) -> Void) {
        let data = MinutesData(api: api, objectToken: objectToken, language: language)
        translateData = data
        data.refresh(catchError: false, completionHandler: completionHandler)
    }

    public func permissionApplyInfo(completionHandler: @escaping (Result<PermissionApplyInfo, Error>) -> Void) {
        let request = FetchPermissionApplyInfoRequest(objectToken: objectToken)

        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data
            })
        }
    }

    public func delete(completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = DeleteRequest(objectToken: objectToken)

        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func applyAction(catchError: Bool, applyText: String, completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = ApplyPermissionRequest(objectToken: objectToken, remark: applyText, catchError: catchError)
        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func fetchMoreDetails(catchError: Bool, completionHandler: @escaping (Result<MoreDetailsInfo, Error>) -> Void) {
        let request = FetchMoreDetailsRequest(objectToken: objectToken, catchError: catchError)

        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data
            })
        }
    }

    public func updateSummaryCheckbox(contentId: String, isChecked: Bool, completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = UpdateSummaryCheckboxRequest(objectToken: objectToken, contentId: contentId, checked: isChecked)

        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func speakerConfirm(catchError: Bool, userId: String, userType: Int, paragraphId: String, completionHandler: @escaping (Result<SpeakerUpdate, Error>) -> Void) {
        let request = SpeakerConfirmRequest(objectToken: objectToken, paragraphId: paragraphId, usetType: userType, userId: userId, catchError: catchError)
        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data
            })
        }
    }

    public func speakerRemove(catchError: Bool, userId: String, userType: Int, paragraphId: String, isBatch: Bool, completionHandler: @escaping (Result<SpeakerUpdate, Error>) -> Void) {
        let request = SpeakerRemoveRequest(objectToken: objectToken, paragraphId: paragraphId, usetType: userType, userId: userId, batch: isBatch, catchError: catchError)
        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data
            })
        }
    }

    public func getSpeakerCount(catchError: Bool, userId: String, userType: Int, completionHandler: @escaping (Result<SpeakerCount, Error>) -> Void) {
        let request = SpeakerCountRequest(objectToken: objectToken, usetType: userType, userId: userId, catchError: catchError)
        api.sendRequest(request) { result in
            completionHandler(result.map {
                $0.data
            })
        }
    }
}

extension Minutes {
    public static func fetchPodcastBackground(completionHandler: @escaping (Result<PodcastBacground, Error>) -> Void) {
        let api = MinutesAPI.clone()
        let reqeust = FetchPodcastBackgroundRequest()

        api.sendRequest(reqeust) {
            completionHandler($0.map {
                $0.data
            })
        }
    }
}

extension Minutes {
    public func doClipListRequest(completionHandler: @escaping (Result<MinutesClipList, Error>) -> Void) {
        let request = FetchClipListRequest(objectToken: objectToken)
        api.sendRequest(request) { (result) in
            completionHandler(result.map {
                $0.data
            })
        }
    }

    public func doMinutesClipDeleteRequest(clipObjectToken: String, completionHandler: @escaping (Result<BasicResponse, Error>) -> Void) {
        let request = MinutesClipDeleteRequest(objectToken: clipObjectToken)

        api.sendRequest(request, completionHandler: completionHandler)
    }
}

