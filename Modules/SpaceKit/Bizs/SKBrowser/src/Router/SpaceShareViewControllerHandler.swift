//
//  ShareViewControllerV2Handler.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/7/14.
// 

import Foundation
import SKCommon
import LarkUIKit
import EENavigator
import UniverseDesignColor

public final class SKShareViewControllerHandler: TypedRouterHandler<SKShareViewControllerBody> {

    override public func handle(_ body: SKShareViewControllerBody, req _: EENavigator.Request, res: Response) {
        let shareEntity = SKShareEntity.transformFrom(info: body.fileInfo)
        let shareVC = SKShareViewController(
            shareEntity,
            router: body.router,
            source: body.source,
            bizParameter: body.bizParameter,
            isInVideoConference: body.fileInfo.isInVideoConference ?? false
        )
        shareVC.watermarkConfig.needAddWatermark = body.fileInfo.shouldShowWatermark
        let navi = LkNavigationController(rootViewController: shareVC)
        if body.needPopover {
            shareVC.modalPresentationStyle = .popover
            navi.modalPresentationStyle = .popover
            navi.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            navi.popoverPresentationController?.sourceView = body.sourceView
            navi.popoverPresentationController?.sourceRect = body.popoverSourceFrame ?? .zero
            navi.popoverPresentationController?.permittedArrowDirections = body.padPopDirection
        } else {
            navi.modalPresentationStyle = .overFullScreen
        }
        res.end(resource: navi)
    }
}
