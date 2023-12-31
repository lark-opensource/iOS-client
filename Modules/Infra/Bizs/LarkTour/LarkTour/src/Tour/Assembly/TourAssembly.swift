//
//  TourAssembly.swift
//  LarkTour
//
//  Created by Meng on 2019/8/16.
//

import UIKit
import Foundation
import Swinject
import LarkTourInterface
import EENavigator
import LarkContainer
import LarkAccountInterface
import LarkGuide
import AppContainer
import LarkDebugExtensionPoint
import LarkAlertController
import LarkNavigation
import LarkRustClient
import BootManager
import LarkNavigation
import LarkAssembler
import LarkStorage

public final class TourAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(TourSetupTask.self)
        NewBootManager.register(UGDialogFetchTask.self)
    }

    public func registContainer(container: Container) {

        let user = container.inObjectScope(.userV2)
        let userGraph = container.inObjectScope(.userGraph)

        user.register(SwitchTabDialogManager.self) { r in
            return SwitchTabDialogManager(userResolver: r)
        }

        userGraph.register(AdvertisingService.self) { r in
            return try r.resolve(assert: AdvertisingManager.self)
        }

        userGraph.register(AdvertisingEventHandler.self) { r in
            return try r.resolve(assert: AdvertisingManager.self)
        }

        user.register(AdvertisingStorage.self) { _ in
            return AdvertisingStorage()
        }

        user.register(AdvertisingManager.self) { r in
            return AdvertisingManager(userResolver: r)
        }

        userGraph.register(AdvertisingRequestTool.self) { _ in
            return AdvertisingRequestTool()
        }

        user.register(TourChatGuideManager.self) { _ in
            return TourChatGuideManager()
        }

        userGraph.register(TourChatGuideService.self) { r -> TourChatGuideService in
            return try r.resolve(assert: TourChatGuideManager.self)
        }

        user.register(TeamConversionService.self) { _ -> TeamConversionService in
            return TeamConversionServiceImpl()
        }

        user.register(TourConfigAPI.self) { (r) -> TourConfigAPI in
            let rustClient = try r.resolve(assert: RustService.self)
            return RustTourConfigAPI(client: rustClient, scheduler: scheduler)
        }

        user.register(DynamicResourceService.self) { r in
            return DynamicResourceServiceImpl(
                configurationAPI: try r.resolve(assert: TourConfigAPI.self),
                pushCenter: try r.userPushCenter,
                productGuideAPI: try r.resolve(assert: ProductGuideAPI.self)
            )
        }
    }

    public func registDebugItem(container: Container) {
        ({ ClearUserGrowthUserDefaultsItem() }, SectionType.dataInfo)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory { TourLauncherDelegate() }, PassportDelegatePriority.middle)
    }
}

struct ClearUserGrowthUserDefaultsItem: DebugCellItem {
    var title: String { return "清除UserGrowth的UserDefaults数据" }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let alertController = LarkAlertController()
        alertController.addSecondaryButton(text: "取消")
        alertController.setTitle(text: "确定要清除UserGrowth的UserDefaults数据?")
        alertController.addDestructiveButton(text: "确定") {
            let store = KVStores.udkv(space: .global, domain: Domain.biz.core.child("UserGrowth"))
            store.clearAll()
        }
        DispatchQueue.main.async {
            Navigator.shared.present(alertController, from: debugVC) //Global
        }
    }
}
