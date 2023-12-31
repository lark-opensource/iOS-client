//
//  DocHandler+MainNavigation.swift
//  CCMMod
//
//  Created by huangzhikai on 2023/10/19.
//

import Foundation
import EENavigator
import LarkQuickLaunchInterface
import LarkTab
import SKCommon

extension DocsViewControllerHandler {
    
    //如果是从主导航打开文档，尝试从主导航缓存获取缓存vc
    func tryGetCacheVCFromMainNavigation(req: EENavigator.Request, docUrl: URL) -> UIViewController? {
        //todo：huangzhikai 这里需要增加setting判断是否生效
        
        guard let launcherFrom = req.context[NavigationKeys.launcherFrom] as? String,
              !launcherFrom.isEmpty,
              let pagekeeper = self.pagekeeperService else {
            return nil
        }
        
        //主导航缓存setting是否开启
        guard pagekeeper.hasSetting else {
            return nil
        }
        
        let docsInfo = DocsUrlUtil.getFileInfoNewFrom(docUrl)
        guard let token = docsInfo.token else {
            return nil
        }
        
        //如果是版本文档，则拼接版本
        var pageId = token
        if let version = URLValidator.getVersionNum(docUrl) {
            pageId += version
        }
        
        
        //打开文档的id
        let vc = pagekeeper.popCachePage(id: pageId, scene: launcherFrom)
        return vc
    }
}
