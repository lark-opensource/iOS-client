//
//  NoOtherPreviewChecker.swift
//  ByteView
//
//  Created by lutingting on 2023/9/8.
//

import Foundation
import ByteViewMeeting

extension PrecheckBuilder {
    @discardableResult
    func checkNoOtherPreview() -> Self {
        checker(NoOtherPreviewChecker())
        return self
    }
}

final class NoOtherPreviewChecker: MeetingPrecheckable {
    var nextChecker: MeetingPrecheckable?

    func check(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        guard let session = MeetingManager.shared.currentSession, session.sessionType == .vc, session.sessionId != context.sessionId, session.state == .start || session.state == .preparing else {
            checkNextIfNeeded(context, completion: completion)
            return
        }
        session.leave { [weak self] _ in
            guard let self = self else {
                completion(.failure(VCError.unknown))
                return
            }
            self.checkNextIfNeeded(context, completion: completion)
        }
    }
}
