//
//  I18nNetworkAPI.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/9/7.
//

import Foundation
import ByteViewCommon
import LarkLocalizations

public extension HttpClient {
    var i18n: I18nNetworkAPI {
        I18nNetworkAPI(self)
    }
}

public final class I18nNetworkAPI {
    private let httpClient: HttpClient
    fileprivate init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    public func get(_ keys: [String], completion: ((Result<[String: String], Error>) -> Void)?) {
        guard !keys.isEmpty else {
            completion?(.success([:]))
            return
        }

        httpClient.getResponse(GetViewI18nTemplateRequest(keys: keys), options: [.notHandleError]) { r in
            completion?(r.map({ $0.templates }))
        }
    }

    public func get(_ key: String, completion: ((Result<String, Error>) -> Void)?) {
        get([key]) { result in
            completion?(result.flatMap { templates in
                if let value = templates.first?.value {
                    return .success(value)
                } else {
                    return .failure(NetworkError.noElements)
                }
            })
        }
    }

    private static let specialNameKey = "specialName"
    public func get(by info: I18nKeyInfo, meetingId: String? = nil, completion: ((Result<(String, NSRange?), Error>) -> Void)?) {
        get(info.newKey.isEmpty ? info.key : info.newKey) { (result) in
            switch result {
            case .success(let template):
                let regex = try? NSRegularExpression(pattern: "(?<=\\{\\{)[^\\}\\}]*(?=\\}\\})")
                let range = NSRange(template.startIndex..., in: template)
                let matches = regex?.matches(in: template, range: range).compactMap {
                    Range($0.range, in: template).map { String(template[$0]) }
                }

                var msg = template
                var shouldFetchPaticipantName = false
                for key in matches ?? [] {
                    if key == Self.specialNameKey {
                        // 需要获取用户昵称进行替换
                        shouldFetchPaticipantName = true
                        continue
                    }
                    var value: String
                    if let v = info.params[key] {
                        value = v
                    } else if key == "appName" {
                        value = LanguageManager.bundleDisplayName
                    } else {
                        value = BundleI18n.LocalizedString(key: key, originalKey: key)
                        Logger.network.error("I18nKeyInfo.params missing value, key = \(key), useLocalValue = \(value)")
                    }
                    msg = msg.replacingOccurrences(of: "{{\(key)}}", with: "\(value)")
                }
                if shouldFetchPaticipantName {
                    self.participantInfo(info: info, meetingId: meetingId) { ap in
                        msg = msg.replacingOccurrences(of: "{{\(Self.specialNameKey)}}", with: "\(ap?.name ?? "")")
                        let result = self.rangeWithMessage(msg)
                        completion?(.success(result))
                    }
                } else {
                    let result = self.rangeWithMessage(msg)
                    completion?(.success(result))
                }
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    /// never throw error
    public func get(by info: I18nKeyInfo?, defaultContent: String, meetingId: String? = nil, completion: ((String) -> Void)?) {
        if let info = info {
            get(by: info, meetingId: meetingId) { result in
                switch result {
                case .success((let s, _)):
                    completion?(s)
                case .failure:
                    completion?(defaultContent)
                }
            }
        } else {
            completion?(defaultContent)
        }
    }

    private func rangeWithMessage(_ message: String) -> (String, NSRange?) {
        var msg = message
        let array = msg.components(separatedBy: "@@")
        var myrange: NSRange?
        if array.count >= 3 {
            msg = msg.replacingOccurrences(of: "@@\(array[1])@@", with: array[1])
            myrange = NSRange(location: array[0].count, length: array[1].count)
        }
        return (msg, myrange)
    }

    private func participantInfo(info: I18nKeyInfo, meetingId: String?, completion: @escaping (ParticipantUserInfo?) -> Void) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let meetingId = meetingId,
              let userStr = info.params[Self.specialNameKey],
              let userData = userStr.data(using: .utf8),
              let userDict = try? JSONSerialization.jsonObject(with: userData) as? [String: Any],
              let userId = userDict["user_id"] as? String,
              let deviceId = userDict["device_id"] as? String,
              let typeRawValue = userDict["user_type"] as? Int
        else {
            Logger.network.error("I18nKeyInfo.params get byteViewUser error")
            completion(nil)
            return
        }
        let pid = ParticipantId(id: userId, type: ParticipantType(rawValue: typeRawValue), deviceId: deviceId)
        httpClient.participantService.participantInfo(pid: pid, meetingId: meetingId, completion: completion)
    }
}
