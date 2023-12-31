//
//  WikiTitleChangeService.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/10/15.
//

import Foundation
import SKCommon

class WikiTitleChangeService {
    weak var handler: WikiJSEventHandler?
    init(_ handler: WikiJSEventHandler) {
        self.handler = handler
    }
}

extension WikiTitleChangeService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.utilTitleSetOfflineName]
    }
    func handle(params: [String: Any], serviceName: String) {
        handler?.handle(event: .titleChanged, params: params)
    }
}

class WikiSetInfoService {
    weak var handler: WikiJSEventHandler?
    init(_ handler: WikiJSEventHandler) {
        self.handler = handler
    }
}

extension WikiSetInfoService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.utilWikiFetchToken]
    }
    func handle(params: [String: Any], serviceName: String) {
        handler?.handle(event: .setWikiInfo, params: params)
    }
}

class WikiSetTreeEnableService: DocsJSServiceHandler {
    weak var handler: WikiJSEventHandler?
    init(_ handler: WikiJSEventHandler) {
        self.handler = handler
    }
    var handleServices: [DocsJSService] {
        return [.utilWikiTreeEnable]
    }
    func handle(params: [String: Any], serviceName: String) {
        handler?.handle(event: .setWikiTreeEnable, params: params)
    }
}

class WikiPermssionChangeService: DocsJSServiceHandler {
    weak var handler: WikiJSEventHandler?
    init(_ handler: WikiJSEventHandler) {
        self.handler = handler
    }
    
    var handleServices: [DocsJSService] {
        return [.userDocPermission, .utilSetData]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        if serviceName == "biz.util.setData" {
            return
        }
        handler?.handle(event: .permissionChanged, params: params)
    }
}
