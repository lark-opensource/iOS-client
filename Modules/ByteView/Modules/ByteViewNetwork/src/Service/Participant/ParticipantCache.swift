//
//  ParticipantCache.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/9/7.
//

import Foundation
import ByteViewCommon

final class ParticipantCache {
    static let shared = ParticipantCache()
    // nolint-next-line: magic number
    private let store = MemoryCache(countLimit: 10000, ageLimit: 2 * 60 * 60)

    private func userKey(with id: String) -> String {
        "\(id)_User"
    }

    func saveUser(_ user: User) {
        store.setValue(user, forKey: userKey(with: user.id))
    }

    func loadUser(_ id: String) -> User? {
        store.value(forKey: userKey(with: id))
    }

    func removeUser(_ id: String) {
        store.removeValue(forKey: userKey(with: id))
    }

    private func roomKey(with id: String) -> String {
        "\(id)_Room"
    }

    func saveRoom(_ room: Room) {
        store.setValue(room, forKey: roomKey(with: room.id))
    }

    func loadRoom(_ id: String) -> Room? {
        store.value(forKey: roomKey(with: id))
    }

    private func guestKey(with id: String, type: ParticipantType, meetingId: String) -> String {
        "\(id)_Guest_\(type.rawValue)_\(meetingId)"
    }

    func saveGuest(_ guest: Guest, meetingId: String) {
        let key = guestKey(with: guest.id, type: guest.type, meetingId: meetingId)
        store.setValue(guest, forKey: key)
    }

    func loadGuest(_ id: String, type: ParticipantType, meetingId: String) -> Guest? {
        let key = guestKey(with: id, type: type, meetingId: meetingId)
        return store.value(forKey: key)
    }

    func clearAll() {
        store.removeAll()
    }
}
