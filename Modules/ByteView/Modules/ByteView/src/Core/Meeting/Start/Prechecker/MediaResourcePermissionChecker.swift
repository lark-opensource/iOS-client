//
//  MediaResourcePermissionChecker.swift
//  ByteView
//
//  Created by lutingting on 2023/8/21.
//

import Foundation
import ByteViewMeeting

extension PrecheckBuilder {
    @discardableResult
    func checkMediaResourcePermission(isNeedAlert: Bool, isNeedCamera: Bool) -> Self {
        checker(MediaResourcePermissionChecker(isNeedAlert: isNeedAlert, isNeedCamera: isNeedCamera))
        return self
    }
}

final class MediaResourcePermissionChecker: MeetingPrecheckable {
    let isNeedAlert: Bool
    let isNeedCamera: Bool
    var nextChecker: MeetingPrecheckable?

    init(isNeedAlert: Bool = false, isNeedCamera: Bool) {
        self.isNeedAlert = isNeedAlert
        self.isNeedCamera = isNeedCamera
    }

    func check(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        Privacy.requestMicrophoneAccessAlert { result in
            if !self.isNeedAlert || result.isSuccess {
                if self.isNeedCamera {
                    self.checkCamera(context, completion: completion)
                } else {
                    self.checkNextIfNeeded(context, completion: completion)
                }
            } else {
                completion(.failure(VCError.micDenied))
            }
        }
    }

    private func checkCamera(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        Privacy.requestCameraAccessAlert { _ in
            self.checkNextIfNeeded(context, completion: completion)
        }
    }
}
