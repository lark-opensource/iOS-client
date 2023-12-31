//
//  StartCallEntrance.swift
//  ByteView
//
//  Created by lutingting on 2023/8/7.
//

import Foundation
import ByteViewMeeting

final class StartCallEntrance: CallEntrance<StartCallParams> {

    override func precheckFailure(error: Error) {
        guard params.source != .openPlatform1v1 else { return }
        if let handler = params.onError, let e = error as? VCError {
            switch e {
            case .collaborationBlocked:
                handler(.collaborationBlocked)
            case .collaborationBeBlocked:
                handler(.collaborationBeBlocked)
            case .collaborationNoRights:
                handler(.collaborationNoRights)
            default:
                handler(.otherError)
            }
        }
        super.precheckFailure(error: error)
    }
}
