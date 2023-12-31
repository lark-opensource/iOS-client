//
//  MinutesEditSession.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/6/24.
//

import Foundation
import LKCommonsLogging

public enum MinutesEditSessionCreateError: Error {
    case otherEditor(String)
    case lowversion
    case network(Error)
}

public protocol MinutesEditSessionDelegate: AnyObject {
    func onDeactive(_ reason: KeepEditExitReason)
}

public final class MinutesEditSession {
    public static let logger = Logger.log(MinutesEditSession.self, category: "Minutes.Network")

    public let minutes: Minutes
    var timer: Timer?
    public weak var delegate: MinutesEditSessionDelegate?

    private init(minutes: Minutes) {
        self.minutes = minutes
    }

    deinit {
        Self.logger.info("edit session deinit", additionalData: ["minutes": String(self.objectToken.suffix(6))])
        self.timer?.invalidate()
        self.timer = nil
        exit()
    }

    let session = UUID().uuidString

    var objectToken: String {
        return self.minutes.objectToken
    }

    var version: Int {
        return self.minutes.info.statusInfo?.objectVersion ?? self.minutes.basicInfo?.objectVersion ?? 0
    }

    var api: MinutesAPI {
        return minutes.api
    }

    func entry(completionHandler: @escaping (Result<EditStatus, Error>) -> Void ) {
        let objectToken = self.objectToken
        Self.logger.info("UpdateEditStatusRequest entry start", additionalData: ["minutes": String(objectToken.suffix(6))])
        let request = UpdateEditStatusRequest(objectToken: objectToken,
                                              action: .entry,
                                              version: version,
                                              session: session)
        api.sendRequest(request) { (result) in
            switch result {
            case .success(let response):
                Self.logger.info("UpdateEditStatusRequest entry success", additionalData: ["minutes": String(objectToken.suffix(6)), "denyType": "\(response.data.denyType)"])
            case .failure(let error):
                Self.logger.error("UpdateEditStatusRequest entry failed", additionalData: ["minutes": String(objectToken.suffix(6))], error: error)
            }

            completionHandler(result.map { $0.data })
        }
    }

    func keep() {
        let objectToken = self.objectToken

        guard UIApplication.shared.applicationState == .active else {
            Self.logger.debug("in background ignore KeepEditStatus", additionalData: ["minutes": String(objectToken.suffix(6))])
            return
        }

        Self.logger.info("KeepEditStatusRequest start", additionalData: ["minutes": String(objectToken.suffix(6))])
        let request = KeepEditStatusRequest(objectToken: objectToken,
                                            session: session)
        api.sendRequest(request) { [weak self] (result) in
            switch result {
            case .success(let response):
                switch response.data.reason {
                case .expired, .otherDevice:
                    self?.deactive(response.data.reason)
                default:
                    break
                }
                Self.logger.info("KeepEditStatusRequest success", additionalData: ["minutes": String(objectToken.suffix(6)), "exitStatus": "\(response.data.reason)"])
            case .failure(let error):
                Self.logger.error("KeepEditStatusRequest failed", additionalData: ["minutes": String(objectToken.suffix(6))], error: error)
            }
        }
    }

    func active() {

        guard !isActive else {
            return
        }

        DispatchQueue.main.async {
            Self.logger.info("edit session active", additionalData: ["minutes": String(self.objectToken.suffix(6))])
            let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self]_ in
                self?.keep()
            }
            self.timer = timer
        }
    }

    func deactive(_ reason: KeepEditExitReason) {

        guard isActive else {
            return
        }

        DispatchQueue.main.async {
            Self.logger.info("edit session deactive", additionalData: ["minutes": String(self.objectToken.suffix(6)), "reason": "\(reason)"])
            self.timer?.invalidate()
            self.timer = nil
            self.delegate?.onDeactive(reason)
        }
    }

    public var isActive: Bool {
        return self.timer?.isValid == true
    }

    public func exit() {
        let objectToken = self.objectToken
        Self.logger.info("UpdateEditStatusRequest exit start", additionalData: ["minutes": String(objectToken.suffix(6))])

        let request = UpdateEditStatusRequest(objectToken: objectToken,
                                              action: .exit,
                                              version: version,
                                              session: session)
        api.sendRequest(request) { (result) in
            switch result {
            case .success:
                Self.logger.info("UpdateEditStatusRequest exit success", additionalData: ["minutes": String(objectToken.suffix(6))])
            case .failure(let error):
                Self.logger.error("UpdateEditStatusRequest exit failed", additionalData: ["minutes": String(objectToken.suffix(6))], error: error)
            }
        }
        deactive(.keep)
    }

    public static func createSession(for minutes: Minutes, completionHandler: @escaping (Result<MinutesEditSession, MinutesEditSessionCreateError>) -> Void) {
        Self.logger.info("createSession", additionalData: ["minutes": String(minutes.objectToken.suffix(6))])

        let session = MinutesEditSession(minutes: minutes)

        session.entry { result in
            switch result {
            case .success(let status):
                let denyType = status.denyType
                switch denyType {
                case .success:
                    session.active()
                    completionHandler(.success(session))
                case .inEditing:
                    let editorName = status.editorName
                    completionHandler(.failure(.otherEditor(editorName)))
                case .lowversion:
                    completionHandler(.failure(.lowversion))
                }
                Self.logger.info("createSession", additionalData: ["minutes": String(session.objectToken.suffix(6)), "denyType": "\(denyType)"])
            case .failure(let error):
                Self.logger.warn("createSession failed", additionalData: ["minutes": String(session.objectToken.suffix(6))], error: error)
                completionHandler(.failure(.network(error)))
            }
        }
    }

    // disable-lint: magic number
    public func fetchSpeakerSuggestion(paragraphId: String, completionHandler: @escaping (Result<SpeakerSuggestion, Error>) -> Void) {
        let objectToken = self.objectToken
        Self.logger.info("fetch speaker suggestion begin", additionalData: ["minutes": String(objectToken.suffix(6))])
        let req = FetchSpeakerSuggestionRequest(objectToken: objectToken, paragraphId: paragraphId, offset: 0, size: 50, language: "")
        api.sendRequest(req) { (result) in
            completionHandler(result.map { $0.data })
            switch result {
            case .success:
                Self.logger.info("fetch speaker suggestion success", additionalData: ["minutes": String(objectToken.suffix(6))])
            case .failure(let error):
                Self.logger.error("fetch speaker suggestion failed", additionalData: ["minutes": String(objectToken.suffix(6))], error: error)
            }
        }
    }
    // enable-lint: magic number

    public func searchParticipants(with query: String, uuid: String, completionHandler: @escaping (Result<ParticipantsSearch, Error>) -> Void) {
        let objectToken = self.objectToken
        Self.logger.info("search participants begin", additionalData: ["minutes": String(objectToken.suffix(6))])
        let req = FetchParticipantsSearchReqeust(objectToken: objectToken, query: query, uuid: uuid)
        api.sendRequest(req) { (result) in
            completionHandler(result.map { $0.data })
            switch result {
            case .success:
                Self.logger.info("search participants begin success", additionalData: ["minutes": String(objectToken.suffix(6))])
            case .failure(let error):
                Self.logger.error("search participants begin failed", additionalData: ["minutes": String(objectToken.suffix(6))], error: error)
            }
        }
    }

    public func updateSpeaker(catchError: Bool, withParagraphId pid: String, userType: Int, userId: String, userName: String, batch: Bool, completionHandler: @escaping (Result<SpeakerUpdate, Error>) -> Void) {
        let objectToken = self.objectToken
        Self.logger.info("update speaker begin", additionalData: ["minutes": String(objectToken.suffix(6))])
        let req = SpeakerUpdateRequest(objectToken: objectToken, paragraphId: pid, usetType: userType, userId: userId, userName: userName, editSession: session, batch: batch, catchError: catchError)
        api.sendRequest(req) { (result) in
            completionHandler(result.map { $0.data })
            switch result {
            case .success:
                Self.logger.info("update speaker success", additionalData: ["minutes": String(objectToken.suffix(6))])
            case .failure(let error):
                Self.logger.error("update speaker failed", additionalData: ["minutes": String(objectToken.suffix(6))], error: error)
            }
        }
    }

    public func fetchUserChoiceStatus(userType: Int, completion: @escaping ((Result<SpeakerUserChoice, Error>) -> Void)) {
        let req = SpeakerUserChoiceRequest(userType: userType)
        api.sendRequest(req) { [weak self] result in
            completion(result.map { $0.data })
            switch result {
            case .success(let res):
                Self.logger.info("fetch UserChoice success batch\(res.data.batchUpdateStatus)")
            case .failure(let error):
                Self.logger.error("fetch UserChoice failed")
            }
        }
    }
}
