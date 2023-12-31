//
//  TourLauncherDelegate.swift
//  LarkTour
//
//  Created by Meng on 2019/12/20.
//

import Foundation
import RxSwift
import Swinject
import LarkTourInterface
import LarkContainer
import LarkAccountInterface

public final class TourLauncherDelegate: PassportDelegate {

    public func userDidOffline(state: PassportState) {
        guard let userID = state.user?.userID, let userResolver = try? Container.shared.getUserResolver(userID: userID) else { return }

        let adEventHandler = try? userResolver.resolve(assert: AdvertisingEventHandler.self)
        adEventHandler?.onLogout()
    }
}
