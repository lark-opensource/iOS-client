//
//  EnterpriseCallEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/7.
//

import Foundation
import ByteViewMeeting

final class EnterpriseCallEntrance: CallEntrance<EnterpriseCallParams> {

    override func precheckSuccess(completion: @escaping (Result<CallEntranceOutputParams, Error>) -> Void) {
        Logger.phoneCall.info("EnterpriseCallEntrance precheckSuccess params = \(params)")
        let output = CallEntranceOutputParams(isE2EeMeeting: context.info.isE2EeMeeting)
        completion(.success(output))
    }
}
