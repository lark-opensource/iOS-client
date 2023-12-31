//
//  ParticipantService.swift
//  ByteView
//
//  Created by Prontera on 2021/11/2.
//

import Foundation
import ByteViewCommon

public extension HttpClient {
    var participantService: ParticipantService {
        ParticipantService(self)
    }
}

public protocol ParticipantStrategy {
    func updateParticipant(_ participant: ParticipantUserInfo) -> ParticipantUserInfo
}

public struct ParticipantStrategyKey: Hashable {
    public let userId: String
    public let meetingId: String

    public init(userId: String, meetingId: String?) {
        self.userId = userId
        self.meetingId = meetingId ?? ""
    }
}

public final class ParticipantService {
    private static let logger = Logger.getLogger("Participant")

    private static var defaultStrategyFactory: ((ParticipantStrategyKey) -> ParticipantStrategy?)?
    @RwAtomic private static var strategies: [ParticipantStrategyKey: ParticipantStrategy] = [:]

    public static func setDefaultStrategy(factory: @escaping (ParticipantStrategyKey) -> ParticipantStrategy?) {
        self.defaultStrategyFactory = factory
    }

    public static func setStrategy(strategy: ParticipantStrategy?, for key: ParticipantStrategyKey) {
        if let strategy = strategy {
            self.strategies[key] = strategy
        } else {
            self.strategies.removeValue(forKey: key)
        }
    }

    private var userId: String { httpClient.userId }
    private let httpClient: HttpClient

    fileprivate init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    /// 获取单个参会人信息，有会议ID一定要传会议ID，否则获取不到游客信息
    /// - Parameters:
    ///   - pid: 参会人ID
    ///   - meetingId: 会议ID
    ///   - usingCache: 是否使用缓存，默认使用
    ///   - completion: 回调，查不到返回Unknown的Participant
    public func participantInfo(pid: ParticipantId, meetingId: String?,
                                usingCache: Bool = true,
                                completion: @escaping (ParticipantUserInfo) -> Void) {
        participantById(pid, meetingId: meetingId, usingCache: usingCache) { ap in
            completion(self.updateParticipant(ap, meetingId: meetingId))
        }
    }

    /// 获取部分参会人信息，优先从内存缓存中读取数据，有会议ID一定要传会议ID，否则获取不到游客信息
    /// - Parameters:
    ///   - pids: 部分参会人ID
    ///   - meetingId: 会议ID
    ///   - usingCache: 是否使用缓存，默认使用
    ///   - completion: 回调，查不到返回Unknown的Participant
    public func participantInfo(pids: [ParticipantId], meetingId: String?,
                                usingCache: Bool = true,
                                completion: @escaping ([ParticipantUserInfo]) -> Void) {
        participantsByIds(pids, meetingId: meetingId, usingCache: usingCache) { aps in
            completion(self.updateParticipants(aps, meetingId: meetingId))
        }
    }

    /// 获取单个参会人信息，优先从内存缓存中读取数据，有会议ID一定要传会议ID，否则获取不到游客信息
    /// - Parameters:
    ///   - pid: 参会人ID
    ///   - meetingId: 会议ID
    ///   - usingCache: 是否使用缓存，默认使用
    ///   - completion: 回调
    public func participantInfo(pid: ParticipantIdConvertible, meetingId: String?,
                                usingCache: Bool = true,
                                completion: @escaping (ParticipantUserInfo) -> Void) {
        participantInfo(pid: pid.participantId, meetingId: meetingId, usingCache: usingCache, completion: completion)
    }

    /// 获取部分参会人信息，优先从内存缓存中读取数据，有会议ID一定要传会议ID，否则获取不到游客信息
    /// - Parameters:
    ///   - pids: 部分参会人ID
    ///   - meetingId: 会议ID
    ///   - usingCache: 是否使用缓存，默认使用
    ///   - completion: 回调
    public func participantInfo(pids: [ParticipantIdConvertible], meetingId: String?,
                                usingCache: Bool = true,
                                completion: @escaping ([ParticipantUserInfo]) -> Void) {
        participantInfo(pids: pids.map { $0.participantId }, meetingId: meetingId, usingCache: usingCache, completion: completion)
    }

    public func participantAvatarPath(_ avatarInfo: AvatarInfo,
                                      dpSize: Int32 = 48,
                                      dpr: Float? = 3.0,
                                      format: String? = "jpg",
                                      completion: @escaping (URL?) -> Void) {
        guard case .remote(let key, let entityId) = avatarInfo else {
            completion(nil)
            return
        }
        if key.isEmpty {
            completion(nil)
            return
        }
        let request = GetAvatarPathRequest(key: key, entityID: entityId, dpSize: dpSize, format: format, dpr: dpr)
        httpClient.getResponse(request) { result in
            switch result {
            case .success(let resp):
                let path = resp.path
                let exist = FileManager.default.fileExists(atPath: path)
                completion(exist ? URL(string: path) : nil)
            default:
                completion(nil)
            }
        }
    }

    /// 清除所有参会人缓存
    public static func clearCache() {
        ParticipantCache.shared.clearAll()
    }

    /// 清除指定larkUser缓存
    public static func clearUserCache(_ id: String) {
        ParticipantCache.shared.removeUser(id)
    }

    private func strategy(meetingId: String?) -> ParticipantStrategy? {
        let key = ParticipantStrategyKey(userId: userId, meetingId: meetingId)
        if let strategy = Self.strategies[key] {
            return strategy
        }
        if let strategy = Self.defaultStrategyFactory?(key) {
            return strategy
        }
        return nil
    }

    private func updateParticipant(_ participant: ParticipantUserInfo, meetingId: String?) -> ParticipantUserInfo {
        if let strategy = strategy(meetingId: meetingId) {
            return strategy.updateParticipant(participant)
        } else {
            return participant
        }
    }

    private func updateParticipants(_ participants: [ParticipantUserInfo], meetingId: String?) -> [ParticipantUserInfo] {
        if let strategy = strategy(meetingId: meetingId) {
            return participants.map { strategy.updateParticipant($0) }
        } else {
            return participants
        }
    }
}

private extension ParticipantService {
    /// - note: 返回的数量和顺序均和入参一样，查不到时返回的是unknown的AnyParticipant
    /// - note: 回调在主线程
    func participantsByIds(_ pids: [ParticipantId], meetingId: String? = nil, usingCache: Bool = true, completion: (([ParticipantUserInfo]) -> Void)?) {
        guard let completion = completion else { return }
        self.fetchUserInfo(pids, meetingId: meetingId, usingCache: usingCache, completion: completion)
    }

    /// - note: 回调在主线程
    func participantById(_ pid: ParticipantId, meetingId: String? = nil, usingCache: Bool = true, completion: ((ParticipantUserInfo) -> Void)?) {
        participantsByIds([pid], meetingId: meetingId, usingCache: usingCache) { aps in
            /// 理论上不会走到else。
            if let ap = aps.first {
                completion?(ap)
            } else {
                Self.logger.error("participantByIdUsingCache return nil!")
                assertionFailure("participantByIdUsingCache return nil!")
            }
        }
    }
}

private extension ParticipantService {
    private func fetchUserInfo(_ pids: [ParticipantId], meetingId: String?, usingCache: Bool = true, completion: @escaping ([ParticipantUserInfo]) -> Void) {
        var userInfoTypeToPids: [UserInfoType: [ParticipantId]] = [:]
        pids.forEach { pid in
            let userInfoType = pid.userInfoType
            var userInfoTypePids = userInfoTypeToPids[userInfoType] ?? []
            userInfoTypePids.append(pid)
            userInfoTypeToPids[userInfoType] = userInfoTypePids
        }
        let dispatchGroup = DispatchGroup()
        var keyToInfo: [UserInfoKey: ParticipantUserInfo] = [:]
        var fetchedInfo: [ParticipantUserInfo] = []
        let fetchedInfoLock = RwLock()
        var needFetch: Bool = false
        for (userInfoType, userInfoTypePids) in userInfoTypeToPids {
            var pidsToFetch = userInfoTypePids
            if usingCache {
                pidsToFetch = pidsToFetch.filter {
                    if let cachedInfo = ParticipantCache.shared.load(pid: $0, meetingId: meetingId) {
                        keyToInfo[cachedInfo.userInfoKey] = cachedInfo
                        return false
                    }
                    return true
                }
            }
            if pidsToFetch.isEmpty { continue }
            if !needFetch { needFetch = true }
            dispatchGroup.enter()
            self.fetchUserInfo(userInfoType: userInfoType, pids: pidsToFetch, meetingId: meetingId) { result in
                defer { dispatchGroup.leave() }
                switch result {
                case .success(let userInfoList):
                    userInfoList.forEach { ParticipantCache.shared.save(meetingId: meetingId, userInfo: $0) }
                    fetchedInfoLock.withWrite { fetchedInfo.append(contentsOf: userInfoList) }
                case .failure(let error):
                    Self.logger.error("fail to fetch user info, pids = \(pidsToFetch), err = \(error)")
                }
            }
        }
        let callbackInfo: ([ParticipantId], [UserInfoKey: ParticipantUserInfo], ([ParticipantUserInfo]) -> Void) -> Void = { pids, keyToInfo, completion in
            let result = pids.map { pid in
                var info = keyToInfo[pid.userInfoKey] ?? pid.createUnknownUserInfo()
                info.pid = pid
                if info.isUnknown {
                    Self.logger.warn("fail to fetch user info, pid = \(pid)")
                }
                return info
            }
            completion(result)
        }
        if !needFetch {
            Util.runInMainThread {
                callbackInfo(pids, keyToInfo, completion)
            }
        } else {
            dispatchGroup.notify(queue: .main) {
                fetchedInfoLock.withRead {
                    fetchedInfo.forEach { keyToInfo[$0.userInfoKey] = $0 }
                }
                callbackInfo(pids, keyToInfo, completion)
            }
        }
    }

    // WARNING: 该函数的调用方在completion里做了释放信号量的操作，请确保completion一定被调用！！！
    private func fetchUserInfo(userInfoType: UserInfoType, pids: [ParticipantId], meetingId: String?,
                               completion: @escaping (Result<[ParticipantUserInfo], Error>) -> Void) {
        switch userInfoType {
        case .lark:
            let chatterIds = pids.compactMap({ $0.larkUserId }).uniqued()
            self.httpClient.getResponse(GetChattersRequest(chatterIds: chatterIds)) { result in
                completion(result.map { resp in resp.chatters.map { ParticipantUserInfo.user($0) } })
            }
        case .room:
            let roomIds = pids.map({ $0.id }).uniqued()
            httpClient.getResponse(GetRoomsRequest(roomIds: roomIds)) { result in
                completion(result.map { resp in resp.rooms.map { ParticipantUserInfo.room($0) } })
            }
        case .guest:
            guard let meetingId = meetingId else { return completion(.success([])) }
            let guests = pids.map { pid in ByteviewUser(id: pid.id, type: pid.type, deviceId: "0") }
            httpClient.getResponse(GetGuestsRequest(meetingId: meetingId, users: guests)) { result in
                completion(result.map { resp in resp.guests.map { ParticipantUserInfo.guest($0) } })
            }
        }
    }
}

private enum UserInfoType: Int {
    case lark
    case room
    case guest
}

private struct UserInfoKey: Hashable {
    let type: UserInfoType
    let id: String
}

private extension ParticipantId {
    var userInfoType: UserInfoType {
        switch self.type {
        case .neoUser, .larkUser, .docUser: return .lark
        case .pstnUser: return self.bindInfo?.type == .lark ? .lark : .guest
        case .room: return .room
        default: return .guest
        }
    }

    var userInfoKey: UserInfoKey {
        switch self.userInfoType {
        case .lark: return .init(type: .lark, id: self.larkUserId ?? "")
        case .room: return .init(type: .room, id: self.id)
        case .guest: return .init(type: .guest, id: "G_\(self.type.rawValue)_\(self.id)")
        }
    }

    func createUnknownUserInfo() -> ParticipantUserInfo {
        switch self.userInfoType {
        case .lark: return .user(.init(unknown: self.larkUserId ?? ""))
        case .room: return .room(.init(unknown: self.id))
        case .guest: return .guest(.init(unknown: self.id))
        }
    }
}

private extension ParticipantUserInfo {
    var userInfoKey: UserInfoKey {
        if let user = self.user { return .init(type: .lark, id: user.id) }
        if let room = self.room { return .init(type: .room, id: room.id) }
        if let guest = self.guest { return .init(type: .guest, id: "G_\(guest.type.rawValue)_\(guest.id)")}
        return .init(type: .guest, id: "G_UNKNOWN")
    }
}

private extension ParticipantCache {
    func load(pid: ParticipantId, meetingId: String?) -> ParticipantUserInfo? {
        switch pid.userInfoType {
        case .lark: return self.loadUser(pid.larkUserId ?? "").flatMap { .user($0) }
        case .room: return self.loadRoom(pid.id).flatMap { .room($0) }
        case .guest: return meetingId.flatMap({ self.loadGuest(pid.id, type: pid.type, meetingId: $0) }).flatMap({ .guest($0) })
        }
    }

    func save(meetingId: String?, userInfo: ParticipantUserInfo) {
        if let user = userInfo.user {
            return self.saveUser(user)
        }
        if let room = userInfo.room {
            return self.saveRoom(room)
        }
        if let guest = userInfo.guest, let mid = meetingId {
            return self.saveGuest(guest, meetingId: mid)
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        var values = [Element]()
        forEach {
            if set.insert($0).inserted {
                values.append($0)
            }
        }
        return values
    }
}
