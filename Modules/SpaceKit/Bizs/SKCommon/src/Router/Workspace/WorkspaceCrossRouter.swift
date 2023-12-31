//
//  WorkspaceCrossRouter.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/4/29.
//

import Foundation
import SKFoundation
import RxSwift
import SpaceInterface
import SKInfra

public protocol PhoenixRouteConfigType {
    var pathPrefix: String { get }
    // isSupport, objType, objToken
    func parse(url: URL) -> (Bool, DocsType, String)
    func getPhoenixPath(type: DocsType, token: String, originURL: URL) -> String
}

public final class PhoenixRouteConfig: PhoenixRouteConfigType {

    public init() {}
    public var pathPrefix: String {
        H5UrlPathConfig.phoenixPathPrefix
    }

    public func parse(url: URL) -> (Bool, DocsType, String) {
        URLValidator.isSupportURLRawtype(url: url)
    }

    public func getPhoenixPath(type: DocsType, token: String, originURL: URL) -> String {
        DocsUrlUtil.getPath(type: type, token: token, originURL: originURL, isPhoenixPath: true)
    }
}


// wiki space 交叉路由
public final class WorkspaceCrossRouter {
    public static let skipRouterKey = "_skip_workspace_redirect"
    public typealias Record = WorkspaceCrossRouteRecord
    private let storage: WorkspaceCrossRouteStorage
    private let disposeBag = DisposeBag()

    init() {
        storage = DocsContainer.shared.resolve(WorkspaceCrossRouteStorage.self)!
    }

    // 如果需要重定向，返回目标 objToken 和 objType
    public func redirect(wikiToken: String) -> Record? {
        guard let record = storage.get(wikiToken: wikiToken) else { return nil }
        if record.inWiki { return nil }
        return record
    }

    // 如果需要重定向，返回目标 wikiToken
    public func redirect(objToken: String) -> Record? {
        guard let record = storage.get(objToken: objToken) else { return nil }
        guard record.inWiki else { return nil }
        return record
    }

    public static func redirect(wikiURL: URL, objToken: String, objType: DocsType) -> URL {
        let redirectURL: URL
        let spaceURL = DocsUrlUtil.url(type: objType, token: objToken)
        if let originComponents = URLComponents(url: wikiURL, resolvingAgainstBaseURL: false),
           var spaceComponents = URLComponents(url: spaceURL, resolvingAgainstBaseURL: false) {
            // 只继承 host、 query 和 fragment
            spaceComponents.percentEncodedHost = originComponents.percentEncodedHost
            spaceComponents.percentEncodedQuery = originComponents.percentEncodedQuery
            spaceComponents.percentEncodedFragment = originComponents.percentEncodedFragment
            redirectURL = spaceComponents.url ?? spaceURL
        } else {
            spaceAssertionFailure("failed to convert wikiURL or spaceURL to components")
            redirectURL = spaceURL
        }
        return redirectURL
    }

    public static func redirect(spaceURL: URL, wikiToken: String) -> URL {
        let wikiURL = DocsUrlUtil.url(type: .wiki, token: wikiToken)
        let redirectURL: URL
        if let originComponents = URLComponents(url: spaceURL, resolvingAgainstBaseURL: false),
           var wikiComponents = URLComponents(url: wikiURL, resolvingAgainstBaseURL: false) {
            // 只继承 host、query 和 fragment
            wikiComponents.percentEncodedHost = originComponents.percentEncodedHost
            wikiComponents.percentEncodedQuery = originComponents.percentEncodedQuery
            wikiComponents.percentEncodedFragment = originComponents.percentEncodedFragment
            redirectURL = wikiComponents.url ?? wikiURL
        } else {
            spaceAssertionFailure("failed to convert wikiURL or spaceURL to components")
            redirectURL = wikiURL
        }
        return redirectURL
    }

    public static func redirectPhoenixURL(spaceURL: URL, config: PhoenixRouteConfigType = PhoenixRouteConfig()) -> URL {
        guard let originComponents = URLComponents(url: spaceURL, resolvingAgainstBaseURL: false) else {
            spaceAssertionFailure("failed to convert spaceURL to components")
            return spaceURL
        }
        let (isSupport, objType, objToken) = config.parse(url: spaceURL)
        var phoenixComponents = originComponents
        guard isSupport, !objType.isUnknownType, !objToken.isEmpty else {
            // 从 url 里拿不到 token 和 type，就直接插入 workspace prefix
            let path = phoenixComponents.path
            if !path.starts(with: "/" + config.pathPrefix) {
                phoenixComponents.path = "/" + config.pathPrefix + path
            }
            let redirectURL = phoenixComponents.url ?? spaceURL
            return redirectURL
        }
        let path = config.getPhoenixPath(type: objType, token: objToken, originURL: spaceURL)
        phoenixComponents.path = path
        let redirectURL = phoenixComponents.url ?? spaceURL
        return redirectURL
    }

    // workspace 重定向缓存及校验逻辑 https://bytedance.feishu.cn/wiki/wikcn4NiwHLCmpf13z987IK9Txn
    public func redirect(resource: SKRouterResource, params: [AnyHashable: Any]?) -> (SKRouterResource, [AnyHashable: Any]?)? {
        if let skipRedirect = params?[Self.skipRouterKey] as? Bool, skipRedirect {
            return nil
        }

        if let entry = resource as? SpaceEntry, entry.originInWiki, let wikiToken = entry.bizNodeToken {
            // 打开指向 Wiki 的 space shortcut，直接跳转
            let wikiURL = Self.redirect(spaceURL: entry.url, wikiToken: wikiToken)
            var newParams = params ?? [:]
            newParams[Self.skipRouterKey] = true
            DocsLogger.info("redirecting space shortcut to wiki", component: LogComponents.workspace)
            return (wikiURL, newParams)
        }

        let (isSupport, type, token) = URLValidator.isSupportURLRawtype(url: resource.url)
        guard isSupport, !token.isEmpty else {
            // 无法解析出 token
            return nil
        }

        if type == .wiki {
            guard let record = redirect(wikiToken: token) else {
                return nil
            }
            let spaceURL = Self.redirect(wikiURL: resource.url, objToken: record.objToken, objType: record.objType)
            var newParams = params ?? [:]
            newParams[Self.skipRouterKey] = true
            DocsLogger.info("redirecting wiki to space",
                            extraInfo: [
                                "wikiToken": DocsTracker.encrypt(id: token),
                                "objToken": DocsTracker.encrypt(id: record.objToken)
                            ],
                            component: LogComponents.workspace)
            WorkspaceTracker.reportWorkspaceRedirectEvent(record: record, reason: .hitCache)
            verify(record: record)
            return (spaceURL, newParams)
        } else {
            guard let record = redirect(objToken: token) else {
                return nil
            }
            let wikiURL = Self.redirect(spaceURL: resource.url, wikiToken: record.wikiToken)
            var newParams = params ?? [:]
            newParams[Self.skipRouterKey] = true
            DocsLogger.info("redirecting space to wiki",
                            extraInfo: [
                                "wikiToken": DocsTracker.encrypt(id: token),
                                "objToken": DocsTracker.encrypt(id: record.objToken)
                            ],
                            component: LogComponents.workspace)
            WorkspaceTracker.reportWorkspaceRedirectEvent(record: record, reason: .hitCache)
            verify(record: record)
            return (wikiURL, newParams)
        }
    }

    private func verify(record: Record) {
        WorkspaceCrossNetworkAPI.getInWikiStatus(wikiToken: record.wikiToken)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] serverRecord in
                if record.objToken == serverRecord.objToken,
                record.objType == serverRecord.objType {
                    // objToken 相同，说明 record 中的映射关系正常，不做处理
                    // 这里不关心 inWiki 状态，因为 inWiki 会随用户操作变化，已有其他逻辑处理
                    return
                }
                DocsLogger.error("verify in space failed, target objToken mismatch",
                                 extraInfo: [
                                    "wikiToken": DocsTracker.encrypt(id: record.wikiToken),
                                    "recordInWiki": record.inWiki,
                                    "recordLogID": record.logID,
                                    "recordObjToken": DocsTracker.encrypt(id: record.objToken),
                                    "serverObjToken": DocsTracker.encrypt(id: serverRecord.objToken)
                                 ],
                                 component: LogComponents.workspace)
                self?.storage.delete(wikiToken: record.wikiToken)
                self?.storage.delete(objToken: record.objToken)
                // 用缓存数据上报 mismatch cache 事件
                WorkspaceTracker.reportWorkspaceRedirectEvent(record: record, reason: .mismatchCache)
            } onError: { error in
                DocsLogger.error("unable to verify in space record", error: error, component: LogComponents.workspace)
            }
            .disposed(by: disposeBag)
    }
}
