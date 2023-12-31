//
//  URLInterceptor.swift
//  Lark
//
//  Created by liuwanlin on 2019/1/9.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import EENavigator
import LarkAccountInterface
import RxSwift
import Swinject
import LKCommonsLogging
import LarkSetting
import Foundation

private let WhiteURLScheme: [String] = ["http", "https"]

class UnloginProcessHandler: MiddlewareHandler {
    private static let logger = Logger.plog(UnloginProcessHandler.self, category: "Account.UnloginProcessHandler")

    let disposeBag: DisposeBag = DisposeBag()

    var lastVisitURL: URL?

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func handleLaunchHome() {
        if let url = self.lastVisitURL {
            if let mainSceneWindow = PassportNavigator.keyWindow {
                URLInterceptorManager.shared.handle(url, from: mainSceneWindow)
            } else {
                assertionFailure()
            }
            self.lastVisitURL = nil
        }
    }

    func handle(req: EENavigator.Request, res: Response) {
        let migrationStatus = PassportStore.shared.migrationStatus
        if migrationStatus == .inProgress {
            // 数据迁移中，正在展示迁移页面，延迟处理 URL（理论上 URLInterceptorManager 已经做了拦截这里不需要再拦截，可以验证后删除）
            Self.logger.error("Migration in progress, failed to open url", additionalData: ["url": req.url.absoluteString])
            lastVisitURL = req.url
            res.end(error: nil)
        } else if !unloginWhitelist.contains("//\(req.url.host ?? "")\(req.url.path)") //不是白名单
            && !AccountServiceAdapter.shared.isLogin //未登录
            && !WhiteURLScheme.contains(req.url.scheme ?? "") { //scheme 不在白名单内
            Self.logger.error("未登录无法进行路由跳转", additionalData: ["url": req.url.absoluteString])
            lastVisitURL = req.url //拦截, 登录后执行
            res.end(error: nil)
        } else { //其他不拦截
            Self.logger.info("url whitelist \(req.url.host)\(req.url.path)", method: .local)
        }
    }
}
