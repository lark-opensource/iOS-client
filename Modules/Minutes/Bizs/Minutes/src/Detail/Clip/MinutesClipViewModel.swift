//
//  MinutesClipViewModel.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/6.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

public final class MinutesClipViewModel {

    public var minutes: Minutes
    init(minutes: Minutes) {
        self.minutes = minutes
    }

    func requestDeleteClip(successHandler: (() -> Void)?, failureHandler: ((Error) -> Void)?) {
        minutes.doMinutesClipDeleteRequest(clipObjectToken: minutes.objectToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    successHandler?()
                case .failure(let error):
                    failureHandler?(error)
                }
            }
        }
    }
}

