//
//  MinutesDetailViewModel.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

public final class MinutesDetailViewModel {
    public var minutes: Minutes
    public var editSession: MinutesEditSession?
    private let spaceAPI = MinutesSapceAPI()
    
    init(minutes: Minutes) {
        self.minutes = minutes
    }
    
    func requestDeleteMinutes(catchError: Bool, successHandler: (() -> Void)?, failureHandler: ((Error) -> Void)?) {
        spaceAPI.doMinutesDeleteRequest(catchError: catchError, objectTokens: [minutes.objectToken], isDestroyed: false) { [weak self] result in
            guard let wSelf = self else {
                return
            }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    successHandler?()
                    NotificationCenter.default.post(name: NSNotification.Name.SpaceList.minutesDidDelete, object: nil, userInfo: ["tokens": [wSelf.minutes.objectToken]])
                case .failure(let error):
                    failureHandler?(error)
                }
            }
        }
    }
}
