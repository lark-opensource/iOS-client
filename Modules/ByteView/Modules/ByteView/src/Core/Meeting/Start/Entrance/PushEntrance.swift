//
//  PushEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/16.
//

import Foundation

final class PushEntrance: MeetingEntrance<JoinMeetingMessage, Void> {
    override func precheckSuccess(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}
