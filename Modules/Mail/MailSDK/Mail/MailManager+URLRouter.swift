//
//  MailManager+URLRouter.swift
//  MailSDK
//
//  Created by chenjiahao.gill on 2019/4/26.
//  

import Foundation

/// MakeURLRouter
// extension MailManager {
//    func makeURLRouter() {
//        urlRouter = SKURLRouter()
//        urlRouter.mailManager = self
//        /// Docs Tab
//        registerMailTab()
//        /// Drive
//        urlRouter.register(types: [.file]) { [weak self] url, _ -> UIViewController in
//            guard let `self` = self else { return UIViewController() }
//            return self.vcFactory.makeDrivePreview(url: url)
//        }
//    }
//
//    /// 某些链接可以直接打开 Mail Tab 的页面
//    private func registerMailTab() {
//        urlRouter.register { [weak self] (url, params) -> (UIViewController?) in
//            guard let `self` = self else { return nil }
//            guard let tmp = params as? [String: Any],
//                let fromSDK = tmp["from_sdk"] as? Bool,
//                fromSDK else { return nil }
//            // TODO: 需要重构为 Mail 的逻辑
//            if URLValidator.isMailHomePageURL(url) {
//                /// 打开 Mail 主页
//                return self.vcFactory.makeMailTabController(tabItemConfigs: self.vcFactory.defaultMailTabConfigs(), isNeedTab: true)
//            } else {
//                return nil
//            }
//        }
//    }
// }
