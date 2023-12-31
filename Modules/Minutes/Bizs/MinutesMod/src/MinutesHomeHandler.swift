//
//  MinutesHomeHandler.swift
//  Minutes
//
//  Created by admin on 2021/2/24.
//

import Foundation
import EENavigator
import Swinject
import MinutesInterface
import MinutesNavigator
import LarkNavigation
import LarkUIKit
import LarkTab
import Minutes
import LKCommonsLogging
import LarkNavigator

let logger = Logger.log(MinutesHomeHandler.self, category: "Minutes")

public final class MinutesHomeHandler: UserRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }
    
    private var isMinutesInTab: Bool {
        guard let service = try? userResolver.resolve(assert: NavigationService.self) else { return false }
        
        return service.checkInTabs(for: Tab.minutes)
    }

    public func handle(req: Request, res: Response) throws {
        let service = try userResolver.resolve(assert: MinutesService.self)
        if isMinutesInTab {
            logger.info("Minutes go to home page, already in tab, switch to tab")
            let minutesHome = Tab.minutes.url.append(fragment: req.url.path)
            guard let from = req.context.from() else { return }
            userResolver.navigator.switchTab(Tab.minutes.url, from: from, animated: false, completion: nil)
            
            if req.url.path.mins.isHomePath() {
                NotificationCenter.default.post(name: Notification.minutesHomeForTab, object: nil)
            }
            if req.url.path.mins.isSharePath() {
                NotificationCenter.default.post(name: Notification.minutesHomeShareForTab, object: nil)
            }
            if req.url.path.mins.isMyPath() {
                if let ref = req.parameters["ref"] as? String, ref == "home" {
                    NotificationCenter.default.post(name: Notification.minutesHomeForTab, object: nil)
                } else {
                    NotificationCenter.default.post(name: Notification.minutesHomeMeForTab, object: nil)
                }
            }
            if req.url.path.mins.isTrashPath() {
                NotificationCenter.default.post(name: Notification.minutesHomeTrashForTab, object: nil)
            }
            service.tabURL = req.url

            res.end(resource: EmptyResource())
        } else {
            logger.info("Minutes go to home page, not in tab, push in")
            // 通过URL进入
            let minutesHomeVC: MinutesHomePageViewController
            if req.url.path.mins.isSharePath() {
                minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .share, fromSource: .others)
            } else if req.url.path.mins.isMyPath() {
                if let ref = req.parameters["ref"] as? String, ref == "home" {
                    minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .home, fromSource: .others)
                } else {
                    minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .my, fromSource: .others)
                }
            } else if req.url.path.mins.isTrashPath() {
                minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .trash, fromSource: .others)
            } else {
                minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .home, fromSource: .others)
            }
            res.end(resource: minutesHomeVC)
        }
    }
}

public final class MinutesHomeTabHandler: UserRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    public func handle(req: Request, res: Response) throws {
        let service = try userResolver.resolve(assert: MinutesService.self)
        
        // 通过主端底部Tab进入
        let minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .tabbar, spaceType: .home, fromSource: .sideBar)
        res.end(resource: minutesHomeVC)

        logger.info("Minutes go to tab page: \(service.tabURL)")
    }
}

public final class MinutesHomeMeHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    public func handle(_ body: MinutesHomeMeBody, req: Request, res: Response) throws {
        let service = try userResolver.resolve(assert: MinutesService.self)
        logger.info("Minutes go to home me page")
        
        let minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .my, fromSource: .meetingTab)
        res.end(resource: minutesHomeVC)
    }
}

public final class MinutesHomeSharedHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    public func handle(_ body: MinutesHomeSharedBody, req: Request, res: Response) throws {
        logger.info("Minutes go to home share page")
        _ = try userResolver.resolve(assert: MinutesService.self)
        // 通过Meeting面板进入
        let minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .share, fromSource: .meetingTab)
        res.end(resource: minutesHomeVC)
    }
}

public final class MinutesHomePageHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    public func handle(_ body: MinutesHomePageBody, req: Request, res: Response) throws {
        logger.info("Minutes go to home page")
        _ = try userResolver.resolve(assert: MinutesService.self)
        
        let minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .home, fromSource: .meetingTab)
        res.end(resource: minutesHomeVC)
    }
}

public final class MinutesHomeTrashHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    public func handle(_ body: MinutesHomeTrashBody, req: Request, res: Response) throws {
        logger.info("Minutes go to home trash page")
        _ = try userResolver.resolve(assert: MinutesService.self)
        let minutesHomeVC = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .trash, fromSource: .meetingTab)
        res.end(resource: minutesHomeVC)
    }
}
