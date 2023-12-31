//
//  PageInTask.swift
//  Lark
//
//  Created by huanglx on 2022/12/13.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import BootManager
import LarkFeatureGating
import LarkSetting
import LarkSDKInterface
import LarkContainer
import OfflineResourceManager
import LKCommonsLogging

/*
 pageIn预加载Task
*/
final class PageInTask: UserFlowBootTask, Identifiable {

    override var runOnlyOnce: Bool { return true }

    static var identify: TaskIdentify = "PageInTask"

    /// 日志
    private let logger = Logger.log(PageInTask.self, category: "PageInTask")

    override func execute(_ context: BootContext) {
        //是否开启
        let setting = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "pageIn_preloading_config"))
        let pageinEnable = setting?["pageinEnable"] as? Bool ?? false
        // lint:disable:next lark_storage_check - 'page_in_preloading_enable' 读取时机非常早（+load），不涉及业务/用户，不做存储检查
        UserDefaults.standard.set(pageinEnable, forKey: "page_in_preloading_enable")
        //加载策略
        let strategy: UInt = setting?["strategy"] as? UInt ?? 1

        if pageinEnable {
            //初始化gecko
            PageInResourceManager.initGecko()
            //获取资源地址
            PageInResourceManager.loadPath(fileName: PageInResourceManager.PAGE_FAULTS) { geckoPath in
                self.logger.info("pageIn_preloading_pageinEnable:\(pageinEnable)_strategy:\(strategy)_geckoPath:\(geckoPath)")
                if let geckoPath = geckoPath {
                    //更新本地资源
                    LarkPageIn.update(bySettings: pageinEnable, andFilePath: geckoPath, andStrategy: strategy)
                }
            }
        }
    }
}

//pagein 资源下载
final class PageInResourceManager: NSObject {
    static let PAGE_FAULTS = "jato_pagefaults"
    static let CHANNEL_PAGE_IN = "pagein_preloading"
    static let ACCESS_KEY_ONLINE = "f2e97c8d28fd14414ce871534b57db7e"

    //初始化gecko
    static func initGecko() {
        let accessKey = Self.ACCESS_KEY_ONLINE
        let orConfig = OfflineResourceBizConfig(bizID: Self.CHANNEL_PAGE_IN,
                                              bizKey: accessKey,
                                                       subBizKey: Self.CHANNEL_PAGE_IN)
        OfflineResourceManager.registerBiz(configs: [orConfig])
    }

    //获取最新文件路径
    static func loadPath(fileName: String, callback: @escaping (String?) -> Void) {
        OfflineResourceManager.fetchResource(byId: Self.CHANNEL_PAGE_IN, complete: { (isSucess, _) in
            if isSucess,
               let path = self.loadPath(fileName: fileName) {
                callback(path)
            } else {
                callback(nil)
            }
        })
    }

    static func loadPath(fileName: String) -> String? {
        guard let path = OfflineResourceManager.rootDir(forId: Self.CHANNEL_PAGE_IN) else { return nil }
        let filePath = path + "/" + fileName
        if FileManager.default.fileExists(atPath: filePath) {
            return filePath
        }
        return nil
    }
}
