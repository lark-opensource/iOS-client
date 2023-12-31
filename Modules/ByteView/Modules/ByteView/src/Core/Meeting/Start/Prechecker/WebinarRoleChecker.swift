//
//  WebinarRoleChecker.swift
//  ByteView
//
//  Created by lutingting on 2023/9/4.
//

import Foundation
import ByteViewNetwork

extension PrecheckBuilder {
    @discardableResult
    func checkWebinarRole(params: PreviewEntryParams) -> Self {
        checker(WebinarRoleChecker(params: params))
        return self
    }
}

final class WebinarRoleChecker: MeetingPrecheckable {
    let params: PreviewEntryParams
    var nextChecker: MeetingPrecheckable?

    init(params: PreviewEntryParams) {
        self.params = params
    }

    func check(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        guard params.isWebinar, params.isAllowGetWebinarRole else {
            checkNextIfNeeded(context, completion: completion)
            return
        }

        var req = GetWebinarRoleRequest()
        switch params.idType {
        case .meetingId:
            req.meetingID = Int64(params.id)
        case .uniqueId:
            req.uniqueID = Int64(params.id)
        case .meetingNumber:
            req.meetingNo = params.id
        default:
            assertionFailure()
        }
        context.httpClient.getResponse(req) { [weak self, weak context] result in
            guard let self = self, let context = context else {
                completion(.failure(VCError.unknown))
                return
            }
            switch result {
            case .success(let resp):
                if resp.role == .webinarAttendee {
                    context.info.isWebinarAttendee = true
                }
                self.checkNextIfNeeded(context, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension PreviewEntryParams {
    var isAllowGetWebinarRole: Bool {
        switch idType {
        case .meetingId, .meetingNumber, .uniqueId:
            return true
        default:
            return false
        }
    }
}
