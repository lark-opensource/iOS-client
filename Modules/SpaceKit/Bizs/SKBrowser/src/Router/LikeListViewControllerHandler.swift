//
//  LikeListViewControllerHandler.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/7/14.
//  

import Foundation
import LarkUIKit
import EENavigator
import SKCommon

public final class LikeListViewControllerHandler: TypedRouterHandler<LikeListViewControllerBody> {

    override public func handle(_ body: LikeListViewControllerBody, req _: EENavigator.Request, res: Response) {
        let likeListController = LikeListViewController(fileToken: body.docInfo.objToken, likeType: body.likeType)
        likeListController.listDelegate = body.listDelegate
        likeListController.watermarkConfig.needAddWatermark = body.docInfo.shouldShowWatermark
        res.end(resource: likeListController)
    }
}
