//
//  BrowserViewController+LifeCycleEvent.swift
//  SKBrowser
//
//  Created by huangzhikai on 2023/9/14.
//

import Foundation
import SKCommon
import SKFoundation
import LarkTab
import LarkContainer
import LarkQuickLaunchInterface

extension BrowserViewController: BrowserViewLifeCycleEvent {
    public func browserTerminate() {
        DocsLogger.warning("receive browserTerminate, begin removeMainTabBarCache")
        //webview被kill，也清除主导航tabbar缓存
        self.removeMainTabBarCache()
    }
    
}

extension BrowserViewController {
    //从主导航移除tabbar缓存
    public func removeMainTabBarCache() {
        DispatchQueue.safetyAsyncMain { [weak self] in
            guard let self = self else { return }
            
            //是否开启新的缓存，是则从新缓存移除
            if let keepService = self.userResolver.resolve(PageKeeperService.self), keepService.hasSetting {
                keepService.removePage(self, force: false, notice: true) { _ in }
                return
            }
            
            //从旧缓存移除
            if (self.docsInfo?.isFromWiki ?? false || self.docsInfo?.isVersion ?? false), let vc = self.parent as? TabContainable {
                self.temporaryTabService.removeTabCache(id: vc.tabContainableIdentifier)
            } else {
                self.temporaryTabService.removeTabCache(id: self.tabContainableIdentifier)
            }
        }
    }
}
