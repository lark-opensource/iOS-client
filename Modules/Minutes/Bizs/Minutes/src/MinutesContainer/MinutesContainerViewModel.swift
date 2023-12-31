//
//  MinutesContainerViewModel.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

public final class MinutesContainerViewModel: MinutesViewModelComponent {

    public var minutes: Minutes

    public var shouldShowDetail: Bool = true

    private let spaceAPI = MinutesSapceAPI()

    init(resolver: MinutesViewModelResolver) {
        self.minutes = resolver.minutes
    }

    init (minutes: Minutes) {
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
