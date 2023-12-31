//
//  RejoinEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/16.
//

import Foundation

final class RejoinEntrance: MeetingEntrance<RejoinParams, Void> {
    override func precheckSuccess(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}
