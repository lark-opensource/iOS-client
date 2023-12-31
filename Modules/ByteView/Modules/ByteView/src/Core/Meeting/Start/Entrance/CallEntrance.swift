//
//  CallEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/7.
//

import Foundation

struct CallEntranceOutputParams {
    let isE2EeMeeting: Bool
}

class CallEntrance<Param: CallEntryParams>: MeetingEntrance<Param, CallEntranceOutputParams> {

    override func willBeginPrecheck() {
        CallingReciableTracker.startEnterCalling(source: params.source.rawValue, isVoiceCall: params.isVoiceCall)
    }

    override func precheckSuccess(completion: @escaping (Result<CallEntranceOutputParams, Error>) -> Void) {
        let output = CallEntranceOutputParams(isE2EeMeeting: context.info.isE2EeMeeting)
        completion(.success(output))
    }

    override func precheckFailure( error: Error) {
        CallingReciableTracker.cancelStartCalling()
    }
}
