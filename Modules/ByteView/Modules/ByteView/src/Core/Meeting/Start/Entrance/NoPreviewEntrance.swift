//
//  NoPreviewEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/8.
//

import Foundation
import ByteViewMeeting

final class NoPreviewEntrance: MeetingEntrance<NoPreviewParams, Void> {

    override func precheckSuccess(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))

    }
}
