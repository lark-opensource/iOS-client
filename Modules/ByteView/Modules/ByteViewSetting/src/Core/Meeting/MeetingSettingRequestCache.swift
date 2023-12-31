//
//  MeetingSettingRequestCache.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/9.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

final class MeetingSettingRequestCache {
    let httpClient: HttpClient
    @RwAtomic private var groupCache: [String: Chat] = [:]
    @RwAtomic private var tenantNames: [String: String] = [:]
    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func fetchGroups(_ ids: [String], completion: @escaping ([Chat]) -> Void) {
        var leftIds: [String] = []
        var groups: [String: Chat] = [:]
        ids.forEach { id in
            if let group = self.groupCache[id] {
                groups[id] = group
            } else {
                leftIds.append(id)
            }
        }
        if leftIds.isEmpty {
            completion(ids.compactMap({ groups[$0] }))
            return
        }

        httpClient.getResponse(GetChatsRequest(chatIds: leftIds)) { [weak self] result in
            if case let .success(resp) = result {
                for g in resp.chats where g.type == .group {
                    self?.groupCache[g.id] = g
                    groups[g.id] = g
                }
            }
            completion(ids.compactMap({ groups[$0] }))
        }
    }

    func fetchTenantNames(_ ids: Set<String>, completion: @escaping ([String: String]) -> Void) {
        var leftIds: Set<String> = []
        var names: [String: String] = [:]
        ids.forEach { id in
            if let name = self.tenantNames[id] {
                names[id] = name
            } else {
                leftIds.insert(id)
            }
        }
        if leftIds.isEmpty {
            completion(names)
            return
        }

        let group = DispatchGroup()
        leftIds.forEach { id in
            group.enter()
            httpClient.getResponse(GetUserProfileRequest(userId: id)) { [weak self] result in
                if case .success(let resp) = result {
                    self?.tenantNames[id] = resp.company.tenantName
                    names[id] = resp.company.tenantName
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(names)
        }
    }
}
