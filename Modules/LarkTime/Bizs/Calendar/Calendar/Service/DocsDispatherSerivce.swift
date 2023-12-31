//
//  DocsDispatherSerivce.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/7.
//

import Foundation
import LarkContainer
import CalendarRichTextEditor
import CalendarFoundation
import AppContainer
import LarkAccountInterface
import LarkSetting

protocol DocsDispatherSerivce {
    func prepare()
    func sell() -> DocsViewHolder
    func clear()
}

final class DocsDispatherSerivceImpl: DocsDispatherSerivce, UserResolverWrapper {
    let minCacheCnt = 1
    private var cachedDocsViewHolders: [CalendarDocsView] = []

    let userService: PassportUserService

    let userResolver: UserResolver
    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        userService = try userResolver.resolve(assert: PassportUserService.self)
    }

    func prepare() {
        DispatchQueue.main.async {
            for _ in self.cachedDocsViewHolders.count ..< self.minCacheCnt {
                let docsViewHolder = CalendarDocsView(docsRichTextViewAPI: self.getDocsView())
                operationLog(message: "DocsDispatchService prepare docView: \(ObjectIdentifier(docsViewHolder))")
                self.cachedDocsViewHolders.append(docsViewHolder)
            }
        }
    }

    func sell() -> DocsViewHolder {
        defer {
            // https://bytedance.feishu.cn/docs/QFB8dsihBlJc6W7jyo1I6e 预加载第二个web会影响当前web渲染，延迟1s
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.prepare() // lazy 预加载，消费一个，补充一个
                operationLog(message: "DocsDispatchService prepare")
            }
        }

        /// 经过系统调用process terminate的缓存webview被废弃，不再继续使用
        if let _ = cachedDocsViewHolders.first {
            let docsView = cachedDocsViewHolders.removeFirst()
            if docsView.bridgeInvalid == false {
                operationLog(message: "DocsDispatchService return First DocsView: \(ObjectIdentifier(docsView))")
                return docsView
            } else {
                operationLog(message: "docView: \(ObjectIdentifier(docsView)) bridge invalid!")
            }
        }

        /// 兜底新建
        let docsView = CalendarDocsView(docsRichTextViewAPI: getDocsView())
        operationLog(message: "DocsDispatchService return New DocsView: \(ObjectIdentifier(docsView))")
        return docsView
    }

    func clear() {
        operationLog(message: "DocsDispatchService clear docViews")
        self.cachedDocsViewHolders = []
    }

    private func getDocsView() -> DocsRichTextView {
        let settings = DomainSettingManager.shared.currentSetting
        let domainPool = settings[DomainSettings.docsPeer] ?? []
        let spaceApi = settings[DomainSettings.docsApi]?.first ?? ""
        let postMainDomian = settings[DomainSettings.docsMainDomain]?.first ?? ""
        let prefixMainDomian = userService.userTenant.tenantDomain ?? ""
        let mainDomian = "\(prefixMainDomian).\(postMainDomian)"
        let richTextView = DocsRichTextView()
        richTextView.setDomains(domainPool: domainPool, spaceApiDomain: spaceApi, mainDomain: mainDomian)
        return richTextView
    }
}
