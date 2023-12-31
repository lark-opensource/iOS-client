//
//  BatchUploader.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//

import Foundation
import LKCommonsLogging
import ThreadSafeDataStructure

final class BatchUploader {

    let client: HTTPClient = HTTPClient()

    let isUploading: SafeAtomic<Bool> = false + .readWriteLock

    static let logger = Logger.log(BatchUploader.self, category: "SecurityAudit.BatchUploader")

    var apiUrl: URL? {
        guard let host = SecurityAuditManager.shared.host else {
            Self.logger.error("not set host")
            return nil
        }
        let prefixUrl = Const.prefixHTTPS + host
        let apiUrl = prefixUrl.appendPath(Const.apiEvent, addLastSlant: true)
        guard let url = URL(string: apiUrl) else {
            Self.logger.error("inavalid url: \(apiUrl)")
            return nil
        }
        return url
    }

    // swiftlint:disable function_body_length
    func upload(
        complete: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let apiUrl = apiUrl else {
            return
        }
        if isUploading.value {
            return
        }
        isUploading.value = true
        SecurityAuditManager.serialQueue.async {
            let idEvents = Database.shared.aduitLogTable.read(limit: Const.dbReadLimit)
            let ids = idEvents.map({ $0.id })
            let events = idEvents.map({ $0.event })
            var request = SecurityEvent_EventsRequest()
            if events.isEmpty {
                #if DEBUG || ALPHA
                Self.logger.info("events empty skip")
                #endif
                self.isUploading.value = false
                return
            } else {
                #if DEBUG || ALPHA
                Self.logger.info("start request apiUrl: \(apiUrl)")
                #endif
            }
            request.events = events
            do {
                let requestBody = try request.serializedData()
                self.client.request(url: apiUrl, body: requestBody, complete: { result in
                    switch result {
                    case .success(let resp):
                        if let result = try? JSONSerialization.jsonObject(with: resp, options: []) as? [String: Any],
                           let code = result["code"] as? Int {
                            if code == Const.bizStatusOK {
                                #if DEBUG || ALPHA
                                Self.logger.info("upload success")
                                #endif
                                SecurityAuditManager.serialQueue.async {
                                    Database.shared.aduitLogTable.delete(ids)
                                }
                                complete(.success(()))
                            } else {
                                complete(.failure(SecurityAuditError.badBizCode(code: code)))
                                Self.logger.error(
                                    "biz code error",
                                    additionalData: [
                                        "code": "\(code)",
                                        "content": String(describing: String(data: resp, encoding: .utf8))
                                    ]
                                )
                            }
                        } else {
                            Self.logger.error(
                                "parse resp fail",
                                additionalData: [
                                    "content": String(describing: String(data: resp, encoding: .utf8))
                                ]
                            )
                            complete(.failure(SecurityAuditError.badServerData))
                        }
                    case .failure(let error):
                        Self.logger.error("request failed ", error: error)
                        complete(.failure(error))
                    }
                    self.isUploading.value = false
                })
            } catch {
                complete(.failure(SecurityAuditError.serializeDataFail))
                Self.logger.error("serialize to data fail", error: error)
                self.isUploading.value = false
            }
        }
    }
    // swiftlint:enable function_body_length
}
