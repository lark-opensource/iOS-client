//
//  NotesNetworkAPI.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/5/11.
//

import Foundation
import ByteViewNetwork

extension HttpClient {
    var notes: NotesNetworkAPI {
        NotesNetworkAPI(self)
    }
}

struct NotesCollaborator: Equatable {
    let userId: String
    let avatarUrl: String
}

final class NotesNetworkAPI {
    private let httpClient: HttpClient
    fileprivate init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func createNotes(_ meetingId: String,
                     templateToken: String,
                     templateId: String,
                     locale: String,
                     timeZone: String,
                     completion: ((Result<NotesManageResponse, Error>) -> Void)? = nil) {
        Logger.notes.info("create notes with mID: \(meetingId), tToken.isEmpty: \(templateToken.isEmpty), tID.hash: \(templateId.hashValue), locale: \(locale), timeZone: \(timeZone)")
        manageNotesRequest(action: NotesManageRequest.Action.create,
                           meetingId: meetingId,
                           templateToken: templateToken,
                           templateId: templateId,
                           locale: locale,
                           timeZone: timeZone) {
            switch $0 {
            case .success(let response):
                Logger.notes.info("create notes succeeded, rsp: \(response)")
            case .failure(let error):
                Logger.notes.info("create notes failed, error: \(error)")
            }
            completion?($0)
        }
    }

    func pullNotesCollaboratorInfo(domain: String,
                                   objToken: String,
                                   cachedUserIds: [String],
                                   session: String,
                                   completion: (([NotesCollaborator], [String], NSInteger, NSInteger) -> Void)? = nil) {
        var url = "https://" + domain + "/space/api/rce/document_avatar_info?" + "obj_type=22&obj_token=\(objToken)&scene_id=1"
        cachedUserIds.forEach {
            url.append("&user_id_with_user_info=\($0)")
        }
        let headers: [String: String] = [
            "Content-Type": "application/json",
            "Cookie": "session=\(session)"
        ]
        let request = SendHttpRequest(url: url, method: .get, headers: headers, body: nil, timeout: nil)
        httpClient.getResponse(request) { result in
            switch result {
            case .success(let rsp):
                guard let jsonBody = try? JSONSerialization.jsonObject(with: rsp.body) as? [String: Any] else {
                    Logger.notes.info("notes avatar get json object failed, may show no collaborator avatar")
                    completion?([], [], 30, 0)
                    return
                }
                guard let data = jsonBody["data"] as? [String: Any],
                      let pullInterval = data["poll_interval"] as? NSInteger,
                      let count = data["user_count"] as? NSInteger,
                      let users = data["users"] as? [String: Any],
                      let remainedUsers = data["users_still_in_room"] as? [String] else {
                    Logger.notes.info("notes avatar get avatar failed, may show no collaborator avatar")
                    completion?([], [], 30, 0)
                    return
                }
                var notesCollaborators = [NotesCollaborator]()
                users.forEach {
                    let avatarUrl = ($0.value as? [String: Any])?["avatar_url"] as? String ?? ""
                    notesCollaborators.append(NotesCollaborator(userId: $0.key, avatarUrl: avatarUrl))
                }
                Logger.notes.info("notesCollaborators: \(notesCollaborators), remainedUsers: \(remainedUsers), count: \(count)")
                completion?(notesCollaborators, remainedUsers, pullInterval, count)
            case .failure(let error):
                Logger.notes.warn("notes collaborator request failed with error code: \(error.toErrorCode()), may show no collaborators avatar")
                completion?([], [], 30, 0)
            }
        }
    }

    /// 创建会议纪要文档
    private func manageNotesRequest(action: NotesManageRequest.Action,
                                    meetingId: String,
                                    templateToken: String,
                                    templateId: String,
                                    locale: String,
                                    timeZone: String,
                                    completion: ((Result<NotesManageResponse, Error>) -> Void)? = nil) {
        let createInfo = NotesManageRequest.CreateInfo(templateToken: templateToken,
                                                       templateId: templateId,
                                                       locale: locale,
                                                       timeZone: timeZone)
        let request = NotesManageRequest(action: action,
                                         meetingID: meetingId,
                                         createInfo: createInfo)
        httpClient.getResponse(request, completion: completion)
    }

}
