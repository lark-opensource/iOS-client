//
//  ShareToRoomEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/24.
//

import Foundation

final class ShareToRoomEntrance: MeetingEntrance<ShareToRoomEntryParams, Void> {

    override func precheckSuccess(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}
