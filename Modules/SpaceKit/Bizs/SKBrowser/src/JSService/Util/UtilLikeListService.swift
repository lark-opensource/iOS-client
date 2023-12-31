//
//  UtilLikeListService.swift
//  SpaceKit
//
//  Created by Webster on 2018/12/6.
//

import Foundation
import SKCommon



public final class UtilLikeListService: BaseJSService {
}

extension UtilLikeListService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilOpenLikeList]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.utilOpenLikeList.rawValue:
            guard let token = params["token"] as? String,
                let type = params["refer_type"] as? Int,
                let likeType = DocLikesType(rawValue: type) else {
                    return
            }
            let likeListController = LikeListViewController(fileToken: token, likeType: likeType)
            likeListController.listDelegate = self
            likeListController.watermarkConfig.needAddWatermark = model?.browserInfo.docsInfo?.shouldShowWatermark ?? true
            navigator?.pushViewController(likeListController)
        default: return
        }
    }
}

extension UtilLikeListService: LikeListDelegate {
    public func requestDisplayUserProfile(userId: String, fileName: String?, listController: LikeListViewController) {
        navigator?.showUserProfile(token: userId)
    }

    public func requestCreateBrowserView(url: String, config: FileConfig) -> UIViewController? {
        return nil
    }
}
