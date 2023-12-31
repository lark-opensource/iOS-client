//
//  ParticipantRelationTagService.swift
//  ByteView
//
//  Created by admin on 2022/11/25.
//

import Foundation
import ByteViewCommon

public extension HttpClient {
    var participantRelationTagService: ParticipantRelationTagService {
        ParticipantRelationTagService(self)
    }
}

public final class ParticipantRelationTagService {
    // logger
    private static let logger = Logger.getLogger("RelationTag")

    private let httpClient: HttpClient
    fileprivate init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    /// 根据用户获取关联组织标签
    /// - Parameters:
    ///   - users: 需要查找关联标签的用户数组
    ///   - useCache: 是否需要使用缓存，true: 优先使用缓存，无缓存再从服务端拉取；false: 直接服务端拉取
    ///   - completion: 完成回调
    public func relationTagsByUsers(_ users: [VCRelationTag.User], useCache: Bool = true, completion: (([VCRelationTag]) -> Void)?) {
        _relationTagsByUsers(users, useCache: useCache) { result in
            // 强制异步，防止外部Rx有问题
            DispatchQueue.main.async {
                switch result {
                case .success(let r):
                    completion?(r)
                case .failure:
                    completion?([])
                }
            }
        }
    }

    /// 清除所有参会人的关联标签缓存
    public static func clearAllCache() {
        logger.info("clean relationTag...")
        ParticipantRelationTagCache.shared.clearAll()
    }
}

final class ParticipantRelationTagCache {
    static let shared = ParticipantRelationTagCache()
    // nolint-next-line: magic number
    private let store = MemoryCache(countLimit: 10000, ageLimit: 10 * 60)

    private func userKey(with id: String) -> String {
        "\(id)_tag"
    }

    func storeRelationTag(_ tag: VCRelationTag, id: String) {
        store.setValue(tag, forKey: userKey(with: id))
    }

    func relationTag(_ id: String) -> VCRelationTag? {
        store.value(forKey: userKey(with: id))
    }

    func removeRelationTag(_ id: String) {
        store.removeValue(forKey: userKey(with: id))
    }

    func clearAll() {
        store.removeAll()
    }
}

private extension ParticipantRelationTagService {
    private func _relationTagsByUsers(_ users: [VCRelationTag.User], useCache: Bool = true, completion: ((Result<[VCRelationTag], Error>) -> Void)?) {
        if users.isEmpty {
            completion?(.success([]))
            return
        }

        var tagsCached: [VCRelationTag] = []
        var usersNotCached: [VCRelationTag.User] = []
        if useCache {
            users.forEach { (user: VCRelationTag.User) in
                let id = user.userIdentifier
                if let tag = ParticipantRelationTagCache.shared.relationTag(id) {
                    tagsCached.append(tag)
                } else {
                    usersNotCached.append(user)
                }
            }
        } else {
            usersNotCached = users
        }
        if usersNotCached.isEmpty {
            Self.logger.info("getVCRelationTag use cached, users: \(users)")
            completion?(.success(tagsCached))
            return
        }

        let request = GetRelationTagRequest(users: usersNotCached)
        httpClient.getResponse(request) { result in
            switch result {
            case .success(let response):
                let relationTags = response.relationTags
                if relationTags.count != usersNotCached.count {
                    let ids = usersNotCached.map { $0.userID }
                    Self.logger.error("getVCRelationTag Error ids: \(ids)")
                }
                relationTags.forEach { tag in
                    Self.logger.info("getVCRelationTag done, \(tag.user.userIdentifier), \(tag)")
                    ParticipantRelationTagCache.shared.storeRelationTag(tag, id: tag.user.userIdentifier)
                }
                completion?(.success(tagsCached + relationTags))
            case .failure(let error):
                Self.logger.error("getVCRelationTag Error: \(error)")
                completion?(.failure(error))
            }
        }
    }
}
