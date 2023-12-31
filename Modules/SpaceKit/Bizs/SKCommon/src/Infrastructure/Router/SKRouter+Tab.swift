//
//  SKRouter+Tab.swift
//  SpaceKit
//
//  Created by Gill on 2019/12/26.
//

import SKFoundation

extension SKRouter {

    func isInDocsTab(_ resource: SKRouterResource) -> Bool {
        guard let pathAfterUrl = URLValidator.pathAfterBaseUrl(resource.url),
            let dest = DocsUrlUtil.jumpDirectionfor(pathAfterUrl),
            dest.isInDocsTab else {
            return false
        }
        return true
    }

    private func _getPath(_ resource: SKRouterResource) -> String? {
        guard let pathAfterUrl = URLValidator.pathAfterBaseUrl(resource.url),
            DocsUrlUtil.jumpDirectionfor(pathAfterUrl) != nil else {
                return nil
        }
        return pathAfterUrl
    }

    public func jumpDocsTabIfProssible(_ resource: SKRouterResource, from: UIViewController) -> Bool {
        if isInDocsTab(resource),
            let path = _getPath(resource) {
            HostAppBridge.shared.call(SwitchTabService(path: path, from: from))
            return true
        }
        return false
    }

}
