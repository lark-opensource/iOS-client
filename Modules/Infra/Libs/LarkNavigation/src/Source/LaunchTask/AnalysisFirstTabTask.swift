//
//  AnalysisFirstTabTask.swift
//  LarkNavigation
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import LarkContainer
import Swinject
import LarkStorage

final class AnalysisFirstTabTask: UserFlowBootTask, Identifiable {
    static var identify = "AnalysisFirstTabTask"

    @ScopedProvider private var navigationService: NavigationService?

    override var runOnlyOnceInUserScope: Bool { return false }

    override func execute(_ context: BootContext) {
        guard let userId = context.currentUserID else { return }
        let store = KVStores.Navigation.build(forUser: userId)
        if let firstTab = store[KVKeys.Navigation.firstTab] {
            context.firstTab = firstTab
        } else {
            context.firstTab = navigationService?.firstTab?.urlString
        }
    }
}
