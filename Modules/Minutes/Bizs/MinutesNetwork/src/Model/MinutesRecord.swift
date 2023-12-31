//
//  MinutesAudioRecord.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/18.
//

import Foundation
import LKCommonsLogging

public final class MinutesRecord {

    static let logger = Logger.log(MinutesRecord.self, category: "Minutes.Network")
    let logger = MinutesRecord.logger

    let api: MinutesAPI
    let objectToken: String

    var languageList: [Language] = [
        Language(name: "普通话", code: "zh_cn"),
        Language(name: "English", code: "en_us"),
        Language(name: "日本語", code: "ja_jp")
    ]

    public init(api: MinutesAPI, objectToken: String) {
        self.api = api
        self.objectToken = objectToken
    }

    public init(_ minutes: Minutes) {
        self.api = minutes.api
        self.objectToken = minutes.objectToken
    }
}

extension MinutesRecord {
    private func updateAudioRecordStatus(status: AudioRecordStatus) {
        let reqeust = UpdateAudioRecordStatusRequest(objectToken: objectToken, status: status, catchError: false)
        api.sendRequest(reqeust) { result in
            switch result {
            case .success:
                self.logger.info("update audio record status \(status) success.")
            case .failure(let error):
                self.logger.error("update audio record status \(status) error: \(error)")
            }
        }
    }

    public func resume() {
        updateAudioRecordStatus(status: .resume)
    }

    public func pause() {
        updateAudioRecordStatus(status: .paused)
    }

    public func recordingStopped() {
        updateAudioRecordStatus(status: .recordComplete)
    }

    public func uploadStopped() {
        updateAudioRecordStatus(status: .uploadComplete)
    }

    public func changeSpokenLaunguage(catchError: Bool, _ lang: Language, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {
        let request = ChangeAudioLanguageRequest(objectToken: objectToken, translateLanguage: nil, recordingLanguage: lang.code, catchError: catchError)
        api.sendRequest(request) { result in
            switch result {
            case .success:
                self.logger.info("change spoken launguage \(lang.name) success.")
                success?()
            case .failure(let error):
                self.logger.error("change spoken launguage error: \(error)")
                failure?(error)
            }
        }
    }
}

extension MinutesRecord {

    public func fetchLanguageList(completionHandler: ((Result<[Language], Error>) -> Void)? = nil) {
        let requst = FetchSpokenLanguageListRequest(objectToken: objectToken, type: .spoken)
        api.sendRequest(requst) { result in
            switch result {
            case .success(let response):
                self.languageList = response.data
                Self.logger.info("fetch spoken list: \(response.data.count)")
                completionHandler?(.success(response.data))
            case .failure(let error):
                Self.logger.error("fetch spoken list error: \(error)")
                completionHandler?(.failure(error))
            }
        }
    }
}

extension MinutesAPI {
    public func uploadComplete(for token: String, completionHandler: ((Bool) -> Void)? = nil) {
        let reqeust = UpdateAudioRecordStatusRequest(objectToken: token, status: .uploadComplete, catchError: false)
        self.sendRequest(reqeust) { result in
            switch result {
            case .success:
                Self.logger.info("update audio record status uploadComplete success.")
                completionHandler?(true)
            case .failure(let error):
                Self.logger.error("update audio record status uploadComplete error: \(error)")
                if let _ = error as? ResponseError {
                    completionHandler?(true)
                } else {
                    completionHandler?(false)
                }
            }
        }
    }

    public func recordComplete(for token: String, completionHandler: ((Bool) -> Void)? = nil) {
        let reqeust = UpdateAudioRecordStatusRequest(objectToken: token, status: .recordComplete, catchError: false)
        self.sendRequest(reqeust) { result in
            switch result {
            case .success:
                Self.logger.info("update audio record status recordComplete success.")
                completionHandler?(true)
            case .failure(let error):
                Self.logger.error("update audio record status recordComplete error: \(error)")
                if let _ = error as? ResponseError {
                    completionHandler?(true)
                } else {
                    completionHandler?(false)
                }
            }
        }
    }
}

extension MinutesRecord {

    public static func fetchDefaultLanguage(catchError: Bool, completionHandler: ((Result<Language, Error>) -> Void)? = nil) {
        let api = MinutesAPI.clone()
        let reqeust = FetchDefaultSpokenLanguageReqeust(catchError: catchError)
        api.sendRequest(reqeust) { result in
            completionHandler?(result.map({ Language(name: $0.data.name, code: $0.data.code) }))
            Self.logger.info("fetch default language result: \(result)")
        }
    }
}
