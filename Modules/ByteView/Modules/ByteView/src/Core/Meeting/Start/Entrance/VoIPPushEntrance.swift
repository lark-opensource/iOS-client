//
//  VoIPPushEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/17.
//

import Foundation

final class VoIPPushEntrance: MeetingEntrance<VoIPPushInfo, Void> {

    override func precheckSuccess(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}
