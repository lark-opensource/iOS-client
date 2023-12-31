//
//  DKIMFileConvertVMDependencyImpl.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/5/23.
//

import Foundation
import SKFoundation
import SKCommon
import RxSwift
import SwiftyJSON
import LKCommonsLogging
import SKInfra

enum DKFileImportResultStatus {
    case success
    case converting
    case unknown(code: Int)
    init(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .success
        case 1, 2:
            self = .converting
        default:
            self = .unknown(code: rawValue)
        }
    }
}

class DKIMFileConvertVMDependencyImpl: NSObject, DKIMFileConvertVMDependency {
    static let logger = Logger.log(DKIMFileConvertVMDependencyImpl.self, category: "DocsSDK.drive.convertIMFile")
    private var pollingStrategy: DrivePollingStrategy?
    private var getResultRequest: DocsRequest<JSON>?
    deinit {
        Self.logger.info("deinit")
    }
    func getChatToken(msgID: String) -> Observable<SpaceRustRouter.ConvertInfo> {
        Self.logger.info("start get chat token: \(msgID.encryptToken)")
        return SpaceRustRouter.shared.getConvertToken(msgID: msgID)
    }
    func createTask(msgID: String, chatToken: String, type: String?) -> Observable<[String: Any]> {
        var params = ["message_token": msgID.toBase64(),
                    "chat_token": chatToken]
        if let type = type {
            params["type"] = type
        }
        Self.logger.info("start create task: \(msgID.encryptToken)")
        return DocsRequest<JSON>(path: OpenAPI.APIPath.importIMFile, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .rxStart().asObservable().flatMap { json -> Observable<[String: Any]> in
                guard let code = json?["code"].int else {
                    Self.logger.error("DKIMFileConvertVMDependencyImpl -- importIMFile has no code")
                    return Observable.error(DriveConvertFileError.invalidDataError)
                }
                guard code == 0 else {
                    Self.logger.error("DKIMFileConvertVMDependencyImpl -- importIMFile create code \(code)")
                    return Observable.error(DriveConvertFileError.serverError(code: code))
                }
                if let dic = json?["data"].dictionaryObject {
                    Self.logger.error("DKIMFileConvertVMDependencyImpl -- importIMFile create success")
                    return Observable<[String: Any]>.just(dic)
                } else {
                    Self.logger.error("DKIMFileConvertVMDependencyImpl -- importIMFile create success but has no data")
                    return Observable.error(DriveConvertFileError.invalidDataError)
                }
            }
    }
    
    func startPolling(ticket: String, timeOut: Int) -> Observable<[String: Any]> {
        Self.logger.info("start polling timeout: \(timeOut)")
        pollingStrategy = DKIMImportFilePolling(timeOut: timeOut)
        return Observable<[String: Any]>.create {[weak self] observer -> Disposable in
            self?.getImportResult(ticket: ticket, completion: { json, error in
                if let error = error {
                    Self.logger.info("polling error")
                    observer.on(.error(error))
                } else {
                    if let dic = json?.dictionaryObject {
                        Self.logger.info("polling next")
                        observer.on(.next(dic))
                        observer.on(.completed)
                    } else {
                        Self.logger.info("polling invalid data")
                        observer.on(.error(DocsNetworkError.invalidData))
                    }
                }
            })
            return Disposables.create {
                self?.getResultRequest?.cancel()
            }
        }
    }
    
    private func getImportResult(ticket: String, completion: @escaping (JSON?, Error?) -> Void) {
        Self.logger.info("start get import result")
        getResultRequest?.cancel()
        getResultRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getImportResult + ticket, params: nil)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .set(needVerifyData: false)
            .start(result: {[weak self] (json, error) in
                if let error = error {
                    completion(json, error)
                } else {
                    if true == self?.pollingStrategy?.shouldPolling(data: json, error: error),
                       case let .interval(interval) = self?.pollingStrategy?.nextInterval() {
                        Self.logger.info("get import result will retry in \(interval) seconds")
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(interval)) {
                            self?.getImportResult(ticket: ticket, completion: completion)
                        }
                    } else {
                        completion(json, error)
                    }
                }
            })
    }
}
