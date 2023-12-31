//
//  MinutesInfoParticipantViewModel.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/17.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

public final class MinutesInfoParticipantViewModel {

    public var minutes: Minutes

    init(minutes: Minutes) {
        self.minutes = minutes
    }

    func participantsDelete(catchError: Bool, with participant: Participant,
                            successHandler: (() -> Void)?,
                            failureHandler: (() -> Void)?) {
        if let actionId = participant.actionId {
            minutes.info.participantDelete(catchError: catchError, userId: participant.userID, userType: participant.userType.rawValue, actionId: actionId, completionHandler: {result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        successHandler?()
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        failureHandler?()
                    }
                }
            })
        }
    }
}
