//
//  PageKeeperManagerOCBridge.swift
//  TTMicroApp
//
//  Created by qianhongqiang on 2023/10/18.
//

import Foundation
import LarkContainer
import LarkQuickLaunchInterface
import LKCommonsLogging
import OPSDK

@objc open class PageKeeperManagerOCBridge: NSObject {
    private static let logger = Logger.oplog(PageKeeperManagerOCBridge.self, category: "PageKeeperManager")
    @objc public static func removePage(uniqueId: OPAppUniqueID) {
        logger.info("PageKeeper remove page begin \(uniqueId.appID)")
        guard let pagekeeper = Container.shared.resolve(PageKeeperService.self) else { return }
        
        if let page = getCachePage(uniqueId: uniqueId) {
            logger.info("PageKeeper will remove valid page \(uniqueId.appID)")
            pagekeeper.removePage(page, force: true, notice: false) { finished in
                logger.info("PageKeeper remove page result \(finished)")
            }
        }
    }
    
    @objc public static func isPageCached(uniqueId: OPAppUniqueID) -> Bool {
        logger.info("PageKeeper isPageCached \(uniqueId.appID)")
        return getCachePage(uniqueId: uniqueId) != nil
    }
    
    static func getCachePage(uniqueId: OPAppUniqueID) -> PagePreservable?  {
        logger.info("PageKeeper get cache \(uniqueId.appID)")
        guard let pagekeeper = Container.shared.resolve(PageKeeperService.self) else { return nil }
        
        let getLauncherFrom: (_ uniuqeID: OPAppUniqueID) -> String = {uniuqeID in
            if let currentMountData = OPApplicationService.current.getContainer(uniuqeID: uniqueId)?.containerContext.currentMountData {
                if let launcherFrom = currentMountData.launcherFrom, !launcherFrom.isEmpty {
                    return launcherFrom
                }
            }
            return LarkQuickLaunchInterface.PageKeeperScene.normal.rawValue
        }
        
        let launcherFrom = getLauncherFrom(uniqueId)
        if let page = pagekeeper.getCachePage(id: uniqueId.appID, scene: launcherFrom) {
            logger.info("PageKeeper get valid cache \(uniqueId.appID)")
            return page
        }
        
        return nil
    }
    
    @objc public static func larkKeepAliveEnable() -> Bool {
        guard let pagekeeper = Container.shared.resolve(PageKeeperService.self) else { return false }
        return pagekeeper.hasSetting
    }
}
